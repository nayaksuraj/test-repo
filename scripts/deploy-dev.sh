#!/bin/bash
# ==============================================================================
# Deploy to Development Environment
# ==============================================================================
# This script deploys the application to the development environment using Helm
# Reusable across multiple projects
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables
# ==============================================================================
ENVIRONMENT="dev"
NAMESPACE="${NAMESPACE:-dev}"
RELEASE_NAME="${RELEASE_NAME:-app}"
HELM_CHART_PATH="${HELM_CHART_PATH:-./helm-chart}"
VALUES_FILE="${VALUES_FILE:-$HELM_CHART_PATH/values-dev.yaml}"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Load build information
if [[ -f "build-info/docker-image.txt" ]]; then
    source build-info/docker-image.txt
fi

echo "=== Deploying to Development Environment ==="
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

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "ERROR: helm is not installed"
    exit 1
fi

# Verify Kubernetes cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: Cannot connect to Kubernetes cluster"
    echo "Please check your KUBECONFIG and cluster access"
    exit 1
fi

echo "✓ kubectl is installed"
echo "✓ helm is installed"
echo "✓ Kubernetes cluster is accessible"
echo ""

# ==============================================================================
# Create Namespace (if it doesn't exist)
# ==============================================================================
echo "=== Ensuring Namespace Exists ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespace '$NAMESPACE' is ready"
echo ""

# ==============================================================================
# Deploy with Helm
# ==============================================================================
echo "=== Deploying Application with Helm ==="

# Prepare Helm upgrade command
HELM_ARGS=(
    "upgrade"
    "$RELEASE_NAME"
    "$HELM_CHART_PATH"
    "--install"
    "--namespace" "$NAMESPACE"
    "--create-namespace"
    "--values" "$VALUES_FILE"
    "--timeout" "10m"
    "--wait"
    "--atomic"
    "--cleanup-on-fail"
)

# Override image tag if available from build
if [[ -n "$DOCKER_IMAGE" ]]; then
    HELM_ARGS+=("--set" "image.repository=$(echo $DOCKER_IMAGE | cut -d':' -f1)")
    HELM_ARGS+=("--set" "image.tag=$(echo $DOCKER_IMAGE | cut -d':' -f2)")
fi

# Additional overrides for dev environment
HELM_ARGS+=("--set" "environment=dev")

# Execute Helm deployment
helm "${HELM_ARGS[@]}"

echo ""
echo "=== Deployment Status ==="

# Check deployment status
kubectl get deployments -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
echo ""

# Check pod status
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"
echo ""

# ==============================================================================
# Post-Deployment Verification
# ==============================================================================
echo "=== Post-Deployment Verification ==="

# Wait for rollout to complete
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/"$RELEASE_NAME-app" -n "$NAMESPACE" --timeout=5m || true

# Get service information
echo ""
echo "=== Service Information ==="
kubectl get service -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"

# Get ingress information (if available)
echo ""
echo "=== Ingress Information ==="
kubectl get ingress -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" || echo "No ingress configured"

echo ""
echo "=== Deployment to Development Environment Complete ==="
echo ""
echo "Useful commands:"
echo "  View logs: kubectl logs -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME --tail=100 -f"
echo "  Check pods: kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME"
echo "  Check events: kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
echo ""
