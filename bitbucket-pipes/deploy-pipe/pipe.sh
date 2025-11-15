#!/bin/bash
# =============================================================================
# Deploy Pipe - Deploy to Kubernetes using Helm
# =============================================================================
# Enterprise-grade Kubernetes deployment pipeline
# =============================================================================

set -e
set -o pipefail

# =============================================================================
# Color Output
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

section() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# =============================================================================
# Debug Mode
# =============================================================================
if [[ "${DEBUG}" == "true" ]]; then
    info "Debug mode enabled"
    set -x
fi

# =============================================================================
# Validate Required Variables
# =============================================================================
if [[ -z "${ENVIRONMENT}" ]]; then
    error "ENVIRONMENT is required (dev, stage, prod)"
    exit 1
fi

if [[ -z "${NAMESPACE}" ]]; then
    error "NAMESPACE is required"
    exit 1
fi

if [[ -z "${KUBECONFIG}" ]]; then
    error "KUBECONFIG is required (base64-encoded kubeconfig content)"
    exit 1
fi

if [[ -z "${RELEASE_NAME}" ]]; then
    error "RELEASE_NAME is required"
    exit 1
fi

if [[ -z "${HELM_CHART_PATH}" ]]; then
    error "HELM_CHART_PATH is required"
    exit 1
fi

# Validate environment
case "${ENVIRONMENT}" in
    dev|development)
        ENVIRONMENT="dev"
        ;;
    stage|staging)
        ENVIRONMENT="stage"
        ;;
    prod|production)
        ENVIRONMENT="prod"
        ;;
    *)
        error "Invalid ENVIRONMENT: ${ENVIRONMENT}. Must be dev, stage, or prod"
        exit 1
        ;;
esac

# =============================================================================
# Configuration
# =============================================================================
WAIT_FOR_ROLLOUT="${WAIT_FOR_ROLLOUT:-true}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-10m}"
DRY_RUN="${DRY_RUN:-false}"

# Determine values file
if [[ -z "${VALUES_FILE}" ]]; then
    VALUES_FILE="${HELM_CHART_PATH}/values-${ENVIRONMENT}.yaml"
fi

section "Deployment Configuration"
echo "Environment: ${ENVIRONMENT}"
echo "Namespace: ${NAMESPACE}"
echo "Release Name: ${RELEASE_NAME}"
echo "Chart Path: ${HELM_CHART_PATH}"
echo "Values File: ${VALUES_FILE}"
echo "Image Tag: ${IMAGE_TAG:-auto-detect}"
echo "Dry Run: ${DRY_RUN}"
echo "Wait for Rollout: ${WAIT_FOR_ROLLOUT}"
echo "Rollout Timeout: ${ROLLOUT_TIMEOUT}"

# =============================================================================
# Setup Kubeconfig
# =============================================================================
section "Setting up Kubernetes Configuration"

# Create .kube directory
mkdir -p ~/.kube

# Decode and save kubeconfig
echo "${KUBECONFIG}" | base64 -d > ~/.kube/config
chmod 600 ~/.kube/config

info "Kubeconfig configured successfully"

# =============================================================================
# Verify Kubernetes Connection
# =============================================================================
section "Verifying Kubernetes Connection"

if ! kubectl cluster-info &> /dev/null; then
    error "Cannot connect to Kubernetes cluster"
    error "Please verify your KUBECONFIG is correct"
    exit 1
fi

# Get cluster info
CLUSTER_NAME=$(kubectl config current-context)
info "Connected to cluster: ${CLUSTER_NAME}"

# Get cluster version
CLUSTER_VERSION=$(kubectl version --short 2>/dev/null | grep Server || kubectl version -o json 2>/dev/null | jq -r '.serverVersion.gitVersion' || echo "unknown")
info "Cluster version: ${CLUSTER_VERSION}"

success "Kubernetes connection verified"

# =============================================================================
# Create/Verify Namespace
# =============================================================================
section "Preparing Namespace"

info "Checking namespace: ${NAMESPACE}"

if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
    info "Namespace '${NAMESPACE}' already exists"
else
    if [[ "${DRY_RUN}" == "true" ]]; then
        info "DRY RUN: Would create namespace '${NAMESPACE}'"
    else
        info "Creating namespace '${NAMESPACE}'"
        kubectl create namespace "${NAMESPACE}"
        success "Namespace created"
    fi
fi

# Label namespace with environment
if [[ "${DRY_RUN}" != "true" ]]; then
    kubectl label namespace "${NAMESPACE}" environment="${ENVIRONMENT}" --overwrite &> /dev/null || true
fi

# =============================================================================
# Load Build Information (if available)
# =============================================================================
if [[ -f "build-info/docker-image.txt" ]]; then
    info "Loading Docker image information from build-info"
    source build-info/docker-image.txt

    if [[ -z "${IMAGE_TAG}" ]] && [[ -n "${DOCKER_IMAGE}" ]]; then
        # Extract tag from full image reference
        IMAGE_TAG=$(echo "${DOCKER_IMAGE}" | cut -d':' -f2)
        info "Using image tag from build: ${IMAGE_TAG}"
    fi
fi

# =============================================================================
# Validate Helm Chart
# =============================================================================
section "Validating Helm Chart"

# Check if chart path exists
if [[ ! -d "${HELM_CHART_PATH}" ]] && [[ ! "${HELM_CHART_PATH}" =~ ^(oci://|https://|http://) ]]; then
    error "Helm chart not found: ${HELM_CHART_PATH}"
    exit 1
fi

# Validate chart if local
if [[ -d "${HELM_CHART_PATH}" ]]; then
    info "Linting Helm chart..."
    if helm lint "${HELM_CHART_PATH}" --values "${VALUES_FILE}" 2>&1 | tee /tmp/helm-lint.log; then
        success "Helm chart validation passed"
    else
        warning "Helm chart validation had warnings"
        cat /tmp/helm-lint.log
    fi
fi

# Validate values file exists
if [[ ! -f "${VALUES_FILE}" ]]; then
    error "Values file not found: ${VALUES_FILE}"
    error "Available values files:"
    ls -la "${HELM_CHART_PATH}"/values*.yaml 2>/dev/null || echo "  No values files found"
    exit 1
fi

success "Chart and values file validated"

# =============================================================================
# Prepare Helm Arguments
# =============================================================================
section "Preparing Deployment"

HELM_ARGS=(
    "upgrade"
    "${RELEASE_NAME}"
    "${HELM_CHART_PATH}"
    "--install"
    "--namespace" "${NAMESPACE}"
    "--create-namespace"
    "--values" "${VALUES_FILE}"
    "--timeout" "${ROLLOUT_TIMEOUT}"
    "--cleanup-on-fail"
)

# Add wait flag if enabled
if [[ "${WAIT_FOR_ROLLOUT}" == "true" ]]; then
    HELM_ARGS+=("--wait")
    HELM_ARGS+=("--atomic")
fi

# Add dry-run flag if enabled
if [[ "${DRY_RUN}" == "true" ]]; then
    HELM_ARGS+=("--dry-run")
    HELM_ARGS+=("--debug")
fi

# Override image tag if provided
if [[ -n "${IMAGE_TAG}" ]]; then
    info "Overriding image tag: ${IMAGE_TAG}"
    HELM_ARGS+=("--set" "image.tag=${IMAGE_TAG}")
fi

# Set environment label
HELM_ARGS+=("--set" "environment=${ENVIRONMENT}")

# Add labels for tracking
HELM_ARGS+=("--set-string" "labels.deployedBy=bitbucket-pipe")
HELM_ARGS+=("--set-string" "labels.deployedAt=$(date -u +'%Y-%m-%dT%H:%M:%SZ')")

# Get Git information if available
if [[ -d .git ]]; then
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
else
    GIT_COMMIT="${BITBUCKET_COMMIT:-unknown}"
    GIT_BRANCH="${BITBUCKET_BRANCH:-unknown}"
fi

HELM_ARGS+=("--set-string" "labels.gitCommit=${GIT_COMMIT}")
HELM_ARGS+=("--set-string" "labels.gitBranch=${GIT_BRANCH}")

info "Helm deployment command prepared"

# =============================================================================
# Deploy with Helm
# =============================================================================
section "Deploying to Kubernetes"

if [[ "${DRY_RUN}" == "true" ]]; then
    warning "DRY RUN MODE - No actual changes will be made"
fi

info "Executing Helm deployment..."
echo ""

# Execute Helm deployment
helm "${HELM_ARGS[@]}"

echo ""
if [[ "${DRY_RUN}" == "true" ]]; then
    success "Dry-run deployment completed successfully"
else
    success "Deployment completed successfully"
fi

# =============================================================================
# Post-Deployment Verification
# =============================================================================
if [[ "${DRY_RUN}" != "true" ]]; then
    section "Post-Deployment Verification"

    # Get deployment status
    info "Checking deployment status..."
    kubectl get deployments -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" || true
    echo ""

    # Get pod status
    info "Checking pod status..."
    kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" || true
    echo ""

    # Wait for rollout if enabled
    if [[ "${WAIT_FOR_ROLLOUT}" == "true" ]]; then
        info "Waiting for rollout to complete..."

        # Get all deployments for this release
        DEPLOYMENTS=$(kubectl get deployments -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" -o name 2>/dev/null || echo "")

        if [[ -n "${DEPLOYMENTS}" ]]; then
            for deployment in ${DEPLOYMENTS}; do
                info "Waiting for ${deployment}..."
                if kubectl rollout status "${deployment}" -n "${NAMESPACE}" --timeout="${ROLLOUT_TIMEOUT}"; then
                    success "Rollout completed for ${deployment}"
                else
                    error "Rollout failed for ${deployment}"

                    # Show recent events for debugging
                    echo ""
                    warning "Recent events:"
                    kubectl get events -n "${NAMESPACE}" --sort-by='.lastTimestamp' | tail -20

                    exit 1
                fi
            done
        else
            info "No deployments found for release ${RELEASE_NAME}"
        fi
    fi

    # Get service information
    section "Service Information"
    kubectl get service -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" || echo "No services found"
    echo ""

    # Get ingress information
    section "Ingress Information"
    kubectl get ingress -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" 2>/dev/null || echo "No ingress configured"
    echo ""

    # Get Helm release status
    section "Helm Release Status"
    helm status "${RELEASE_NAME}" -n "${NAMESPACE}"
    echo ""

    # Show recent pod logs if deployment failed
    POD_STATUS=$(kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "")

    if [[ "${POD_STATUS}" == *"Failed"* ]] || [[ "${POD_STATUS}" == *"CrashLoopBackOff"* ]]; then
        warning "Some pods are not running properly. Showing recent logs..."
        echo ""

        FAILED_POD=$(kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" --field-selector=status.phase!=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

        if [[ -n "${FAILED_POD}" ]]; then
            warning "Logs from failed pod: ${FAILED_POD}"
            kubectl logs "${FAILED_POD}" -n "${NAMESPACE}" --tail=50 || true
        fi
    fi
fi

# =============================================================================
# Export Deployment Information
# =============================================================================
section "Exporting Deployment Information"

# Create build-info directory
mkdir -p build-info

# Save deployment information
cat > build-info/deployment.txt <<EOF
ENVIRONMENT=${ENVIRONMENT}
NAMESPACE=${NAMESPACE}
RELEASE_NAME=${RELEASE_NAME}
HELM_CHART_PATH=${HELM_CHART_PATH}
VALUES_FILE=${VALUES_FILE}
IMAGE_TAG=${IMAGE_TAG:-}
GIT_COMMIT=${GIT_COMMIT}
GIT_BRANCH=${GIT_BRANCH}
DEPLOYMENT_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
CLUSTER=${CLUSTER_NAME}
DRY_RUN=${DRY_RUN}
EOF

info "Deployment information saved to build-info/deployment.txt"
cat build-info/deployment.txt

# =============================================================================
# Helpful Commands
# =============================================================================
section "Useful Commands"

echo "View logs:"
echo "  kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/instance=${RELEASE_NAME} --tail=100 -f"
echo ""
echo "Check pods:"
echo "  kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance=${RELEASE_NAME}"
echo ""
echo "Check events:"
echo "  kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp'"
echo ""
echo "Describe deployment:"
echo "  kubectl describe deployment -n ${NAMESPACE} -l app.kubernetes.io/instance=${RELEASE_NAME}"
echo ""
echo "Rollback deployment:"
echo "  helm rollback ${RELEASE_NAME} -n ${NAMESPACE}"
echo ""
echo "View Helm history:"
echo "  helm history ${RELEASE_NAME} -n ${NAMESPACE}"
echo ""

section "Deployment Complete"
success "Application deployed successfully to ${ENVIRONMENT} environment!"

if [[ "${DRY_RUN}" == "true" ]]; then
    info "This was a dry-run. Set DRY_RUN=false to perform actual deployment."
fi
