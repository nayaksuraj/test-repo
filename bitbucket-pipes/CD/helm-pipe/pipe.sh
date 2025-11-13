#!/bin/bash
# =============================================================================
# Helm Pipe - Lint, Package, and Push Helm Charts
# =============================================================================
# Enterprise-grade Helm chart management pipeline
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
if [[ -z "${HELM_CHART_PATH}" ]]; then
    error "HELM_CHART_PATH is required"
    exit 1
fi

# =============================================================================
# Configuration
# =============================================================================
WORKING_DIR="${WORKING_DIR:-.}"
LINT_CHART="${LINT_CHART:-true}"
PACKAGE_CHART="${PACKAGE_CHART:-true}"
PUSH_CHART="${PUSH_CHART:-true}"

# Change to working directory
cd "${WORKING_DIR}"

# Validate chart path exists
if [[ ! -d "${HELM_CHART_PATH}" ]]; then
    error "Helm chart directory not found: ${HELM_CHART_PATH}"
    exit 1
fi

if [[ ! -f "${HELM_CHART_PATH}/Chart.yaml" ]]; then
    error "Chart.yaml not found in: ${HELM_CHART_PATH}"
    exit 1
fi

# =============================================================================
# Get Chart Information
# =============================================================================
CHART_NAME=$(grep '^name:' "${HELM_CHART_PATH}/Chart.yaml" | awk '{print $2}' | tr -d '"')

# Get chart version from Chart.yaml or use provided version
if [[ -n "${CHART_VERSION}" ]]; then
    CURRENT_VERSION="${CHART_VERSION}"
    # Update Chart.yaml with provided version
    sed -i "s/^version:.*/version: ${CHART_VERSION}/" "${HELM_CHART_PATH}/Chart.yaml"
else
    CURRENT_VERSION=$(grep '^version:' "${HELM_CHART_PATH}/Chart.yaml" | awk '{print $2}' | tr -d '"')
fi

APP_VERSION=$(grep '^appVersion:' "${HELM_CHART_PATH}/Chart.yaml" | awk '{print $2}' | tr -d '"')

# Get Git information if available
if [[ -d .git ]]; then
    GIT_COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
else
    GIT_COMMIT_SHA="${BITBUCKET_COMMIT:-unknown}"
    GIT_BRANCH="${BITBUCKET_BRANCH:-unknown}"
fi

info "Helm Chart Configuration"
echo "Chart Path: ${HELM_CHART_PATH}"
echo "Chart Name: ${CHART_NAME}"
echo "Chart Version: ${CURRENT_VERSION}"
echo "App Version: ${APP_VERSION}"
echo "Git Commit: ${GIT_COMMIT_SHA}"
echo "Git Branch: ${GIT_BRANCH}"
echo ""

# =============================================================================
# Lint Helm Chart
# =============================================================================
if [[ "${LINT_CHART}" == "true" ]]; then
    info "Linting Helm chart..."

    if helm lint "${HELM_CHART_PATH}"; then
        success "Helm chart lint passed"
    else
        error "Helm chart lint failed"
        exit 1
    fi
    echo ""
else
    warning "Chart linting disabled - set LINT_CHART=true to enable"
    echo ""
fi

# =============================================================================
# Template Validation
# =============================================================================
info "Validating Helm templates..."

# Validate with default values
info "Validating with default values..."
if helm template test "${HELM_CHART_PATH}" --debug > /dev/null 2>&1; then
    success "Default values validation passed"
else
    error "Default values validation failed"
    helm template test "${HELM_CHART_PATH}" --debug || true
    exit 1
fi

# Validate with environment-specific values if they exist
for env in dev stage staging prod production; do
    VALUES_FILE="${HELM_CHART_PATH}/values-${env}.yaml"
    if [[ -f "${VALUES_FILE}" ]]; then
        info "Validating with ${env} values..."
        if helm template test "${HELM_CHART_PATH}" -f "${VALUES_FILE}" --debug > /dev/null 2>&1; then
            success "${env} values validation passed"
        else
            error "${env} values validation failed"
            helm template test "${HELM_CHART_PATH}" -f "${VALUES_FILE}" --debug || true
            exit 1
        fi
    fi
done

echo ""

# =============================================================================
# Update Dependencies
# =============================================================================
if grep -q "^dependencies:" "${HELM_CHART_PATH}/Chart.yaml" 2>/dev/null; then
    info "Updating chart dependencies..."
    helm dependency update "${HELM_CHART_PATH}"
    success "Dependencies updated"
    echo ""
fi

# =============================================================================
# Package Helm Chart
# =============================================================================
if [[ "${PACKAGE_CHART}" == "true" ]]; then
    info "Packaging Helm chart..."

    # Create package directory
    mkdir -p helm-packages

    # Package the chart
    helm package "${HELM_CHART_PATH}" --destination helm-packages

    CHART_PACKAGE="helm-packages/${CHART_NAME}-${CURRENT_VERSION}.tgz"

    if [[ -f "${CHART_PACKAGE}" ]]; then
        success "Chart packaged successfully: ${CHART_PACKAGE}"
    else
        error "Chart package not found: ${CHART_PACKAGE}"
        exit 1
    fi

    # Generate repository index
    info "Generating Helm repository index..."
    helm repo index helm-packages --url "${HELM_REGISTRY:-http://charts.example.com}"
    success "Repository index generated"

    echo ""
else
    warning "Chart packaging disabled - set PACKAGE_CHART=true to enable"
    echo ""
fi

# =============================================================================
# Push Helm Chart
# =============================================================================
if [[ "${PUSH_CHART}" == "true" ]]; then
    if [[ -z "${HELM_REGISTRY}" ]]; then
        warning "HELM_REGISTRY not set - skipping push"
    else
        info "Pushing Helm chart to registry..."

        # Login to Helm registry if credentials provided
        if [[ -n "${HELM_REGISTRY_USERNAME}" ]] && [[ -n "${HELM_REGISTRY_PASSWORD}" ]]; then
            info "Logging in to Helm registry..."

            # Determine registry type and host
            if [[ "${HELM_REGISTRY}" =~ ^oci:// ]]; then
                # OCI registry
                REGISTRY_HOST=$(echo "${HELM_REGISTRY}" | sed 's|oci://||' | cut -d'/' -f1)
                info "OCI registry detected: ${REGISTRY_HOST}"

                echo "${HELM_REGISTRY_PASSWORD}" | helm registry login "${REGISTRY_HOST}" \
                    -u "${HELM_REGISTRY_USERNAME}" \
                    --password-stdin

                success "Login successful"
            else
                # Traditional Helm repository (ChartMuseum, etc.)
                info "Traditional Helm repository detected"
            fi
        else
            warning "No credentials provided - assuming registry is already authenticated"
        fi

        # Push chart
        if [[ "${HELM_REGISTRY}" =~ ^oci:// ]]; then
            # Push to OCI registry
            info "Pushing chart to OCI registry: ${HELM_REGISTRY}"
            helm push "${CHART_PACKAGE}" "${HELM_REGISTRY}"
            success "Chart pushed to OCI registry"
        else
            # Push to traditional Helm repository (ChartMuseum)
            info "Pushing chart to Helm repository: ${HELM_REGISTRY}"

            # Check if ChartMuseum API is available
            if curl -f -X POST --data-binary "@${CHART_PACKAGE}" "${HELM_REGISTRY}/api/charts" 2>/dev/null; then
                success "Chart pushed to Helm repository"
            else
                # Try alternative upload method
                warning "ChartMuseum API not available, trying alternative method..."
                if [[ -n "${HELM_REGISTRY_USERNAME}" ]] && [[ -n "${HELM_REGISTRY_PASSWORD}" ]]; then
                    curl -u "${HELM_REGISTRY_USERNAME}:${HELM_REGISTRY_PASSWORD}" \
                        -X POST --data-binary "@${CHART_PACKAGE}" \
                        "${HELM_REGISTRY}/api/charts"
                    success "Chart pushed to Helm repository"
                else
                    error "Unable to push chart - authentication required"
                    exit 1
                fi
            fi
        fi

        echo ""
        success "Helm chart pushed successfully"
        echo "Registry: ${HELM_REGISTRY}"
        echo "Chart: ${CHART_NAME}"
        echo "Version: ${CURRENT_VERSION}"
    fi
else
    warning "Chart push disabled - set PUSH_CHART=true to enable"
    echo ""
fi

# =============================================================================
# Export Chart Information
# =============================================================================
info "Exporting chart information..."

# Create build-info directory
mkdir -p build-info

# Save chart information
cat > build-info/helm-chart.txt <<EOF
HELM_CHART_PATH=${HELM_CHART_PATH}
HELM_CHART_NAME=${CHART_NAME}
HELM_CHART_VERSION=${CURRENT_VERSION}
HELM_APP_VERSION=${APP_VERSION}
HELM_CHART_PACKAGE=${CHART_PACKAGE}
HELM_REGISTRY=${HELM_REGISTRY:-}
GIT_COMMIT=${GIT_COMMIT_SHA}
GIT_BRANCH=${GIT_BRANCH}
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
EOF

info "Chart information saved to build-info/helm-chart.txt"
cat build-info/helm-chart.txt

echo ""
success "Helm pipe completed successfully!"
