#!/bin/bash
# =============================================================================
# Docker Pipe - Build, Scan, and Push Docker Images
# =============================================================================
# Enterprise-grade Docker image build pipeline with security scanning
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
if [[ -z "${DOCKER_REGISTRY}" ]]; then
    error "DOCKER_REGISTRY is required"
    exit 1
fi

if [[ -z "${DOCKER_REPOSITORY}" ]]; then
    error "DOCKER_REPOSITORY is required"
    exit 1
fi

# =============================================================================
# Configuration
# =============================================================================
WORKING_DIR="${WORKING_DIR:-.}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-./Dockerfile}"
SCAN_IMAGE="${SCAN_IMAGE:-true}"
PUSH_IMAGE="${PUSH_IMAGE:-true}"
TRIVY_SEVERITY="${TRIVY_SEVERITY:-CRITICAL,HIGH,MEDIUM}"
TRIVY_EXIT_CODE="${TRIVY_EXIT_CODE:-0}"

# Change to working directory
cd "${WORKING_DIR}"

# =============================================================================
# Get Git Information
# =============================================================================
if [[ -d .git ]]; then
    GIT_COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
else
    GIT_COMMIT_SHA="${BITBUCKET_COMMIT:-unknown}"
    GIT_BRANCH="${BITBUCKET_BRANCH:-unknown}"
fi

# Determine image tag
if [[ -n "${IMAGE_TAG}" ]]; then
    TAG="${IMAGE_TAG}"
else
    TAG="${GIT_COMMIT_SHA}"
fi

# =============================================================================
# Build Configuration
# =============================================================================
IMAGE_NAME="${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"
LATEST_IMAGE="${IMAGE_NAME}:latest"

info "Docker Build Configuration"
echo "Registry: ${DOCKER_REGISTRY}"
echo "Repository: ${DOCKER_REPOSITORY}"
echo "Image: ${FULL_IMAGE}"
echo "Dockerfile: ${DOCKERFILE_PATH}"
echo "Git Commit: ${GIT_COMMIT_SHA}"
echo "Git Branch: ${GIT_BRANCH}"
echo ""

# Validate Dockerfile exists
if [[ ! -f "${DOCKERFILE_PATH}" ]]; then
    error "Dockerfile not found at: ${DOCKERFILE_PATH}"
    exit 1
fi

# =============================================================================
# Build Docker Image
# =============================================================================
info "Building Docker image..."

# Prepare build args
BUILD_CMD="docker build"
BUILD_CMD+=" --file ${DOCKERFILE_PATH}"
BUILD_CMD+=" --tag ${FULL_IMAGE}"
BUILD_CMD+=" --tag ${LATEST_IMAGE}"

# Add standard build args
BUILD_CMD+=" --build-arg VERSION=${TAG}"
BUILD_CMD+=" --build-arg GIT_COMMIT=${GIT_COMMIT_SHA}"
BUILD_CMD+=" --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

# Add custom build args if provided
if [[ -n "${BUILD_ARGS}" ]]; then
    IFS=',' read -ra ARGS <<< "${BUILD_ARGS}"
    for arg in "${ARGS[@]}"; do
        BUILD_CMD+=" --build-arg ${arg}"
    done
fi

# Add context
BUILD_CMD+=" ."

# Execute build
info "Build command: ${BUILD_CMD}"
eval ${BUILD_CMD}

success "Docker image built successfully: ${FULL_IMAGE}"
echo ""

# =============================================================================
# Scan Docker Image with Trivy
# =============================================================================
if [[ "${SCAN_IMAGE}" == "true" ]]; then
    info "Scanning Docker image for vulnerabilities..."

    # Create reports directory
    mkdir -p security-reports

    # Run Trivy scan
    info "Severity levels: ${TRIVY_SEVERITY}"

    # Table format for console output
    trivy image \
        --severity "${TRIVY_SEVERITY}" \
        --exit-code "${TRIVY_EXIT_CODE}" \
        --no-progress \
        --format table \
        --output security-reports/trivy-report.txt \
        "${FULL_IMAGE}" || SCAN_FAILED=$?

    # JSON format for automation
    trivy image \
        --severity "${TRIVY_SEVERITY}" \
        --no-progress \
        --format json \
        --output security-reports/trivy-report.json \
        "${FULL_IMAGE}"

    # Display scan results
    echo ""
    info "Vulnerability Scan Results:"
    cat security-reports/trivy-report.txt
    echo ""

    # Parse and display summary
    if command -v jq &> /dev/null; then
        CRITICAL=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' security-reports/trivy-report.json 2>/dev/null || echo "0")
        HIGH=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' security-reports/trivy-report.json 2>/dev/null || echo "0")
        MEDIUM=$(jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' security-reports/trivy-report.json 2>/dev/null || echo "0")

        info "Vulnerability Summary:"
        echo "  Critical: ${CRITICAL}"
        echo "  High: ${HIGH}"
        echo "  Medium: ${MEDIUM}"
        echo ""

        if [[ ${CRITICAL} -gt 0 ]] || [[ ${HIGH} -gt 0 ]]; then
            warning "Image contains ${CRITICAL} critical and ${HIGH} high severity vulnerabilities"
        fi
    fi

    if [[ ${SCAN_FAILED} -eq 1 ]]; then
        error "Vulnerability scan failed - vulnerabilities found exceed threshold"
        exit 1
    fi

    success "Vulnerability scan completed"
    echo ""
else
    warning "Image scanning disabled - set SCAN_IMAGE=true to enable"
    echo ""
fi

# =============================================================================
# Push Docker Image
# =============================================================================
if [[ "${PUSH_IMAGE}" == "true" ]]; then
    info "Pushing Docker image to registry..."

    # Login to Docker registry if credentials provided
    if [[ -n "${DOCKER_USERNAME}" ]] && [[ -n "${DOCKER_PASSWORD}" ]]; then
        info "Logging in to Docker registry: ${DOCKER_REGISTRY}"
        echo "${DOCKER_PASSWORD}" | docker login "${DOCKER_REGISTRY}" -u "${DOCKER_USERNAME}" --password-stdin
        success "Login successful"
    else
        warning "No credentials provided - assuming registry is already authenticated"
    fi

    # Push image with tag
    info "Pushing ${FULL_IMAGE}..."
    docker push "${FULL_IMAGE}"
    success "Pushed ${FULL_IMAGE}"

    # Push latest tag
    info "Pushing ${LATEST_IMAGE}..."
    docker push "${LATEST_IMAGE}"
    success "Pushed ${LATEST_IMAGE}"

    echo ""
    success "Docker image pushed successfully to ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}"
    echo "Available tags: ${TAG}, latest"
else
    warning "Image push disabled - set PUSH_IMAGE=true to enable"
    echo ""
fi

# =============================================================================
# Export Image Information
# =============================================================================
info "Exporting image information..."

# Create build-info directory
mkdir -p build-info

# Save image information
cat > build-info/docker-image.txt <<EOF
DOCKER_IMAGE=${FULL_IMAGE}
DOCKER_IMAGE_LATEST=${LATEST_IMAGE}
DOCKER_REGISTRY=${DOCKER_REGISTRY}
DOCKER_REPOSITORY=${DOCKER_REPOSITORY}
IMAGE_TAG=${TAG}
GIT_COMMIT=${GIT_COMMIT_SHA}
GIT_BRANCH=${GIT_BRANCH}
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
EOF

info "Image information saved to build-info/docker-image.txt"
cat build-info/docker-image.txt

echo ""
success "Docker pipe completed successfully!"
