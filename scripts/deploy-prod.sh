#!/bin/bash
# ==============================================================================
# Deploy to Production Environment
# ==============================================================================
# This script deploys the application to the production environment using Helm
# Uses Canary deployment strategy with gradual rollout
# Reusable across multiple projects
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables
# ==============================================================================
ENVIRONMENT="prod"
NAMESPACE="${NAMESPACE:-production}"
RELEASE_NAME="${RELEASE_NAME:-demo-app}"
HELM_CHART_PATH="${HELM_CHART_PATH:-./helm-chart}"
VALUES_FILE="${VALUES_FILE:-$HELM_CHART_PATH/values-prod.yaml}"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Canary deployment configuration
CANARY_ENABLED="${CANARY_ENABLED:-false}"
CANARY_WEIGHT="${CANARY_WEIGHT:-10}"  # Start with 10% traffic

# Load build information
if [[ -f "build-info/docker-image.txt" ]]; then
    source build-info/docker-image.txt
fi

echo "==================================================================="
echo "           PRODUCTION DEPLOYMENT - PROCEED WITH CAUTION           "
echo "==================================================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Release Name: $RELEASE_NAME"
echo "Chart Path: $HELM_CHART_PATH"
echo "Values File: $VALUES_FILE"
echo "Docker Image: $DOCKER_IMAGE"
echo "Canary Enabled: $CANARY_ENABLED"
echo ""

# Manual confirmation for production
if [[ "${AUTO_APPROVE}" != "true" ]]; then
    echo "WARNING: You are about to deploy to PRODUCTION"
    echo "Press Ctrl+C to cancel, or press Enter to continue..."
    read -r
fi

# ==============================================================================
# Prerequisites Check
# ==============================================================================
echo "=== Checking Prerequisites ==="

if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "ERROR: helm is not installed"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✓ Prerequisites check passed"
echo ""

# ==============================================================================
# Create Namespace (if it doesn't exist)
# ==============================================================================
echo "=== Ensuring Namespace Exists ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespace '$NAMESPACE' is ready"
echo ""

# ==============================================================================
# Backup Current Deployment
# ==============================================================================
echo "=== Backing Up Current Deployment ==="
CURRENT_REVISION=$(helm history "$RELEASE_NAME" -n "$NAMESPACE" --max 1 -o json 2>/dev/null | grep -o '"revision":[0-9]*' | cut -d':' -f2 || echo "0")
echo "Current revision: $CURRENT_REVISION"

# Create snapshot of current deployment
kubectl get deployment "$RELEASE_NAME-demo-app" -n "$NAMESPACE" -o yaml > /tmp/deployment-backup-$(date +%Y%m%d-%H%M%S).yaml 2>/dev/null || true
echo "✓ Deployment backup created"
echo ""

# ==============================================================================
# Deploy with Helm
# ==============================================================================
echo "=== Deploying Application to Production ==="

HELM_ARGS=(
    "upgrade"
    "$RELEASE_NAME"
    "$HELM_CHART_PATH"
    "--install"
    "--namespace" "$NAMESPACE"
    "--create-namespace"
    "--values" "$VALUES_FILE"
    "--timeout" "20m"
    "--wait"
    "--atomic"
    "--cleanup-on-fail"
)

# Override image tag
if [[ -n "$DOCKER_IMAGE" ]]; then
    HELM_ARGS+=("--set" "image.repository=$(echo $DOCKER_IMAGE | cut -d':' -f1)")
    HELM_ARGS+=("--set" "image.tag=$(echo $DOCKER_IMAGE | cut -d':' -f2)")
fi

# Production-specific overrides
HELM_ARGS+=("--set" "environment=production")

# Canary deployment configuration
if [[ "$CANARY_ENABLED" == "true" ]]; then
    HELM_ARGS+=("--set" "canary.enabled=true")
    HELM_ARGS+=("--set" "canary.weight=$CANARY_WEIGHT")
    echo "Deploying with Canary strategy (${CANARY_WEIGHT}% traffic)"
fi

# Execute deployment
if helm "${HELM_ARGS[@]}"; then
    echo "✓ Helm deployment successful"
else
    echo "✗ Helm deployment failed"
    exit 1
fi

echo ""

# ==============================================================================
# Post-Deployment Verification
# ==============================================================================
echo "=== Post-Deployment Verification ==="

# Wait for rollout (more time for production)
kubectl rollout status deployment/"$RELEASE_NAME-demo-app" -n "$NAMESPACE" --timeout=15m

echo ""
echo "=== Running Production Smoke Tests ==="

# Get service endpoint
SERVICE_NAME="$RELEASE_NAME-demo-app"
SERVICE_PORT=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')

# Port-forward for smoke tests
kubectl port-forward -n "$NAMESPACE" "service/$SERVICE_NAME" 8080:$SERVICE_PORT &
PORT_FORWARD_PID=$!
sleep 5

# Production smoke tests
SMOKE_TEST_PASSED=true

echo "Testing health endpoint..."
if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "  ✓ Health check passed"
else
    echo "  ✗ Health check failed"
    SMOKE_TEST_PASSED=false
fi

echo "Testing liveness endpoint..."
if curl -f http://localhost:8080/actuator/health/liveness > /dev/null 2>&1; then
    echo "  ✓ Liveness check passed"
else
    echo "  ✗ Liveness check failed"
    SMOKE_TEST_PASSED=false
fi

echo "Testing readiness endpoint..."
if curl -f http://localhost:8080/actuator/health/readiness > /dev/null 2>&1; then
    echo "  ✓ Readiness check passed"
else
    echo "  ✗ Readiness check failed"
    SMOKE_TEST_PASSED=false
fi

# Verify metrics endpoint
echo "Testing metrics endpoint..."
if curl -f http://localhost:8080/actuator/prometheus > /dev/null 2>&1; then
    echo "  ✓ Metrics endpoint accessible"
else
    echo "  ✗ Metrics endpoint failed"
    SMOKE_TEST_PASSED=false
fi

kill $PORT_FORWARD_PID 2>/dev/null || true

# ==============================================================================
# Rollback on Failure
# ==============================================================================
if [ "$SMOKE_TEST_PASSED" = false ]; then
    echo ""
    echo "=== CRITICAL: Smoke Tests Failed - Rolling Back ==="

    if [[ "$CURRENT_REVISION" != "0" ]]; then
        helm rollback "$RELEASE_NAME" "$CURRENT_REVISION" -n "$NAMESPACE" --wait --timeout=10m
        echo "✓ Rolled back to revision $CURRENT_REVISION"
    fi

    exit 1
fi

echo ""
echo "✓ All production smoke tests passed"

# ==============================================================================
# Deployment Summary
# ==============================================================================
echo ""
echo "==================================================================="
echo "            PRODUCTION DEPLOYMENT SUCCESSFUL                       "
echo "==================================================================="
echo ""
echo "Deployment Details:"
kubectl get deployments -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
echo ""
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
echo ""
kubectl get service -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
echo ""
kubectl get ingress -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" || echo "No ingress configured"

echo ""
echo "==================================================================="
echo "Monitor your application closely for the next 30 minutes"
echo ""
echo "Useful commands:"
echo "  View logs: kubectl logs -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME --tail=100 -f"
echo "  Check pods: kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME -w"
echo "  Rollback: helm rollback $RELEASE_NAME -n $NAMESPACE"
echo "==================================================================="
echo ""
