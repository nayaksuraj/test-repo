#!/bin/bash
# ==============================================================================
# Deploy to Staging Environment
# ==============================================================================
# This script deploys the application to the staging environment using Helm
# Includes smoke tests and rollback capability
# Reusable across multiple projects
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables
# ==============================================================================
ENVIRONMENT="stage"
NAMESPACE="${NAMESPACE:-staging}"
RELEASE_NAME="${RELEASE_NAME:-app}"
HELM_CHART_PATH="${HELM_CHART_PATH:-./helm-chart}"
VALUES_FILE="${VALUES_FILE:-$HELM_CHART_PATH/values-stage.yaml}"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Load build information
if [[ -f "build-info/docker-image.txt" ]]; then
    source build-info/docker-image.txt
fi

echo "=== Deploying to Staging Environment ==="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Release Name: $RELEASE_NAME"
echo "Chart Path: $HELM_CHART_PATH"
echo "Values File: $VALUES_FILE"
echo "Docker Image: $DOCKER_IMAGE"
echo ""

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
# Backup Current Deployment (for rollback)
# ==============================================================================
echo "=== Backing Up Current Deployment ==="
CURRENT_REVISION=$(helm history "$RELEASE_NAME" -n "$NAMESPACE" --max 1 -o json 2>/dev/null | grep -o '"revision":[0-9]*' | cut -d':' -f2 || echo "0")
echo "Current revision: $CURRENT_REVISION"
echo ""

# ==============================================================================
# Deploy with Helm (Blue-Green Strategy)
# ==============================================================================
echo "=== Deploying Application with Helm ==="

HELM_ARGS=(
    "upgrade"
    "$RELEASE_NAME"
    "$HELM_CHART_PATH"
    "--install"
    "--namespace" "$NAMESPACE"
    "--create-namespace"
    "--values" "$VALUES_FILE"
    "--timeout" "15m"
    "--wait"
    "--atomic"
    "--cleanup-on-fail"
)

# Override image tag if available
if [[ -n "$DOCKER_IMAGE" ]]; then
    HELM_ARGS+=("--set" "image.repository=$(echo $DOCKER_IMAGE | cut -d':' -f1)")
    HELM_ARGS+=("--set" "image.tag=$(echo $DOCKER_IMAGE | cut -d':' -f2)")
fi

# Additional overrides for staging
HELM_ARGS+=("--set" "environment=staging")

# Execute Helm deployment
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

# Wait for rollout
# Use label selector to find deployment dynamically
DEPLOYMENT_NAME=$(kubectl get deployment -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [[ -n "$DEPLOYMENT_NAME" ]]; then
    kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=10m
else
    echo "ERROR: No deployment found with label app.kubernetes.io/instance=$RELEASE_NAME"
    exit 1
fi

echo ""
echo "=== Running Smoke Tests ==="

# Get service endpoint - use label selector to find service dynamically
SERVICE_NAME=$(kubectl get service -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [[ -z "$SERVICE_NAME" ]]; then
    echo "ERROR: No service found with label app.kubernetes.io/instance=$RELEASE_NAME"
    exit 1
fi
SERVICE_PORT=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')

# Port-forward for smoke tests (if not using ingress)
kubectl port-forward -n "$NAMESPACE" "service/$SERVICE_NAME" 8080:$SERVICE_PORT &
PORT_FORWARD_PID=$!
sleep 5

# Run smoke tests
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

# Stop port-forward
kill $PORT_FORWARD_PID 2>/dev/null || true

# ==============================================================================
# Rollback on Failure
# ==============================================================================
if [ "$SMOKE_TEST_PASSED" = false ]; then
    echo ""
    echo "=== Smoke Tests Failed - Rolling Back ==="

    if [[ "$CURRENT_REVISION" != "0" ]]; then
        helm rollback "$RELEASE_NAME" "$CURRENT_REVISION" -n "$NAMESPACE" --wait
        echo "✓ Rolled back to revision $CURRENT_REVISION"
    else
        echo "No previous revision to rollback to"
    fi

    exit 1
fi

echo ""
echo "✓ All smoke tests passed"

# ==============================================================================
# Deployment Summary
# ==============================================================================
echo ""
echo "=== Deployment Status ==="
kubectl get deployments -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
kubectl get service -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
kubectl get ingress -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" || echo "No ingress configured"

echo ""
echo "=== Deployment to Staging Environment Complete ==="
echo ""
