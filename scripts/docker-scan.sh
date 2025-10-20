#!/bin/bash
# ==============================================================================
# Docker Image Vulnerability Scanning with Trivy
# ==============================================================================
# This script scans Docker images for vulnerabilities using Trivy
# Reusable across multiple projects
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables (Override via environment or pipeline variables)
# ==============================================================================
TRIVY_VERSION="${TRIVY_VERSION:-0.48.0}"
TRIVY_SEVERITY="${TRIVY_SEVERITY:-CRITICAL,HIGH,MEDIUM}"
TRIVY_EXIT_CODE="${TRIVY_EXIT_CODE:-0}"  # Set to 1 to fail on vulnerabilities
TRIVY_IGNORE_UNFIXED="${TRIVY_IGNORE_UNFIXED:-false}"
SCAN_TYPE="${SCAN_TYPE:-image}"  # image, fs, or both

# Get image information from build step
if [[ -f "build-info/docker-image.txt" ]]; then
    source build-info/docker-image.txt
fi

DOCKER_IMAGE="${DOCKER_IMAGE:-$1}"

if [[ -z "$DOCKER_IMAGE" ]]; then
    echo "ERROR: Docker image not specified"
    echo "Usage: $0 <docker-image>"
    echo "Or set DOCKER_IMAGE environment variable"
    exit 1
fi

# ==============================================================================
# Install Trivy (if not already installed)
# ==============================================================================
if ! command -v trivy &> /dev/null; then
    echo "=== Installing Trivy ==="
    echo "Version: $TRIVY_VERSION"

    # Download and install Trivy
    wget -qO- https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz | tar -xzf - -C /tmp
    sudo mv /tmp/trivy /usr/local/bin/
    trivy --version
    echo ""
fi

# Create reports directory
mkdir -p security-reports

# ==============================================================================
# Scan Docker Image
# ==============================================================================
if [[ "$SCAN_TYPE" == "image" ]] || [[ "$SCAN_TYPE" == "both" ]]; then
    echo "=== Scanning Docker Image for Vulnerabilities ==="
    echo "Image: $DOCKER_IMAGE"
    echo "Severity Levels: $TRIVY_SEVERITY"
    echo "Ignore Unfixed: $TRIVY_IGNORE_UNFIXED"
    echo ""

    # Run Trivy scan
    trivy image \
        --severity "$TRIVY_SEVERITY" \
        --exit-code "$TRIVY_EXIT_CODE" \
        --no-progress \
        --format table \
        --output security-reports/trivy-image-report.txt \
        "$DOCKER_IMAGE"

    # Generate JSON report for automation
    trivy image \
        --severity "$TRIVY_SEVERITY" \
        --no-progress \
        --format json \
        --output security-reports/trivy-image-report.json \
        "$DOCKER_IMAGE"

    # Generate HTML report for human review
    trivy image \
        --severity "$TRIVY_SEVERITY" \
        --no-progress \
        --format template \
        --template "@contrib/html.tpl" \
        --output security-reports/trivy-image-report.html \
        "$DOCKER_IMAGE" || echo "HTML report generation failed (template may not be available)"

    echo ""
    echo "=== Image Scan Results ==="
    cat security-reports/trivy-image-report.txt
    echo ""
fi

# ==============================================================================
# Scan Filesystem (for source code vulnerabilities)
# ==============================================================================
if [[ "$SCAN_TYPE" == "fs" ]] || [[ "$SCAN_TYPE" == "both" ]]; then
    echo "=== Scanning Filesystem for Vulnerabilities ==="
    echo "Path: ."
    echo ""

    # Run Trivy filesystem scan
    trivy fs \
        --severity "$TRIVY_SEVERITY" \
        --exit-code "$TRIVY_EXIT_CODE" \
        --no-progress \
        --format table \
        --output security-reports/trivy-fs-report.txt \
        .

    # Generate JSON report
    trivy fs \
        --severity "$TRIVY_SEVERITY" \
        --no-progress \
        --format json \
        --output security-reports/trivy-fs-report.json \
        .

    echo ""
    echo "=== Filesystem Scan Results ==="
    cat security-reports/trivy-fs-report.txt
    echo ""
fi

# ==============================================================================
# Generate Summary
# ==============================================================================
echo "=== Vulnerability Scan Summary ==="

# Parse JSON report for summary (if jq is available)
if command -v jq &> /dev/null && [[ -f "security-reports/trivy-image-report.json" ]]; then
    echo ""
    echo "Critical Vulnerabilities:"
    jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' security-reports/trivy-image-report.json || echo "0"

    echo "High Vulnerabilities:"
    jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' security-reports/trivy-image-report.json || echo "0"

    echo "Medium Vulnerabilities:"
    jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' security-reports/trivy-image-report.json || echo "0"
fi

echo ""
echo "=== Scan Reports Generated ==="
echo "Text Report: security-reports/trivy-image-report.txt"
echo "JSON Report: security-reports/trivy-image-report.json"
echo "HTML Report: security-reports/trivy-image-report.html"
echo ""

# ==============================================================================
# Policy Enforcement
# ==============================================================================
if [[ "$TRIVY_EXIT_CODE" == "1" ]]; then
    echo "=== Policy Enforcement Enabled ==="
    echo "Build will fail if vulnerabilities are found"
    echo ""
fi

echo "=== Docker Image Vulnerability Scan Complete ==="
