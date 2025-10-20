#!/bin/bash
# ==============================================================================
# Helm Chart Package and Push Script
# ==============================================================================
# This script packages and pushes Helm charts
# Reusable across multiple projects
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables (Override via environment or pipeline variables)
# ==============================================================================
HELM_CHART_PATH="${HELM_CHART_PATH:-./helm-chart}"
HELM_REGISTRY="${HELM_REGISTRY:-oci://your-registry.example.com/helm-charts}"
HELM_REGISTRY_USERNAME="${HELM_REGISTRY_USERNAME:-}"
HELM_REGISTRY_PASSWORD="${HELM_REGISTRY_PASSWORD:-}"

# Get version from Chart.yaml or use default
CHART_VERSION=$(grep '^version:' "$HELM_CHART_PATH/Chart.yaml" | awk '{print $2}')
APP_VERSION=$(grep '^appVersion:' "$HELM_CHART_PATH/Chart.yaml" | awk '{print $2}' | tr -d '"')

# Get Git information
GIT_COMMIT_SHA=$(git rev-parse --short HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "=== Helm Chart Package Started ==="
echo "Chart Path: $HELM_CHART_PATH"
echo "Chart Version: $CHART_VERSION"
echo "App Version: $APP_VERSION"
echo "Git Commit: $GIT_COMMIT_SHA"
echo "Git Branch: $GIT_BRANCH"
echo ""

# ==============================================================================
# Install Helm (if not already installed)
# ==============================================================================
if ! command -v helm &> /dev/null; then
    echo "=== Installing Helm ==="
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    helm version
    echo ""
fi

# ==============================================================================
# Lint Helm Chart
# ==============================================================================
echo "=== Linting Helm Chart ==="
helm lint "$HELM_CHART_PATH"
echo ""

# ==============================================================================
# Template Validation (dry-run for all environments)
# ==============================================================================
echo "=== Validating Helm Templates ==="

# Validate with default values
echo "Validating with default values..."
helm template test "$HELM_CHART_PATH" --debug > /dev/null
echo "  ✓ Default values validation passed"

# Validate with dev values
if [[ -f "$HELM_CHART_PATH/values-dev.yaml" ]]; then
    echo "Validating with dev values..."
    helm template test "$HELM_CHART_PATH" -f "$HELM_CHART_PATH/values-dev.yaml" --debug > /dev/null
    echo "  ✓ Dev values validation passed"
fi

# Validate with stage values
if [[ -f "$HELM_CHART_PATH/values-stage.yaml" ]]; then
    echo "Validating with stage values..."
    helm template test "$HELM_CHART_PATH" -f "$HELM_CHART_PATH/values-stage.yaml" --debug > /dev/null
    echo "  ✓ Stage values validation passed"
fi

# Validate with prod values
if [[ -f "$HELM_CHART_PATH/values-prod.yaml" ]]; then
    echo "Validating with prod values..."
    helm template test "$HELM_CHART_PATH" -f "$HELM_CHART_PATH/values-prod.yaml" --debug > /dev/null
    echo "  ✓ Prod values validation passed"
fi

echo ""

# ==============================================================================
# Package Helm Chart
# ==============================================================================
echo "=== Packaging Helm Chart ==="

# Create package directory
mkdir -p helm-packages

# Update dependencies (if Chart.yaml has dependencies)
if grep -q "^dependencies:" "$HELM_CHART_PATH/Chart.yaml"; then
    echo "Updating chart dependencies..."
    helm dependency update "$HELM_CHART_PATH"
fi

# Package the chart
helm package "$HELM_CHART_PATH" --destination helm-packages

CHART_PACKAGE="helm-packages/$(basename $HELM_CHART_PATH)-${CHART_VERSION}.tgz"

echo "Chart packaged successfully: $CHART_PACKAGE"
echo ""

# ==============================================================================
# Generate Chart Index
# ==============================================================================
echo "=== Generating Helm Repository Index ==="
helm repo index helm-packages --url "$HELM_REGISTRY"
echo "Repository index generated: helm-packages/index.yaml"
echo ""

# ==============================================================================
# Push Helm Chart (only if HELM_PUSH=true)
# ==============================================================================
if [[ "${HELM_PUSH}" == "true" ]]; then
    echo "=== Pushing Helm Chart ==="

    # Login to Helm registry if credentials are provided
    if [[ -n "$HELM_REGISTRY_USERNAME" ]] && [[ -n "$HELM_REGISTRY_PASSWORD" ]]; then
        echo "Logging in to Helm registry..."

        # Check if registry is OCI
        if [[ "$HELM_REGISTRY" =~ ^oci:// ]]; then
            echo "$HELM_REGISTRY_PASSWORD" | helm registry login \
                $(echo "$HELM_REGISTRY" | sed 's|oci://||' | cut -d'/' -f1) \
                -u "$HELM_REGISTRY_USERNAME" \
                --password-stdin
        fi
    fi

    # Push to OCI registry
    if [[ "$HELM_REGISTRY" =~ ^oci:// ]]; then
        echo "Pushing chart to OCI registry..."
        helm push "$CHART_PACKAGE" "$HELM_REGISTRY"
    else
        # Push to ChartMuseum or similar
        echo "Pushing chart to Helm repository..."
        curl --data-binary "@$CHART_PACKAGE" "$HELM_REGISTRY/api/charts"
    fi

    echo ""
    echo "=== Helm Chart Push Complete ==="
    echo "Chart successfully pushed to: $HELM_REGISTRY"
else
    echo "=== Skipping Helm Push ==="
    echo "Set HELM_PUSH=true to push charts"
fi

# ==============================================================================
# Export chart information for use in subsequent steps
# ==============================================================================
echo ""
echo "=== Exporting Chart Information ==="

# Save to file for Bitbucket Pipelines artifacts
mkdir -p build-info
cat > build-info/helm-chart.txt <<EOF
HELM_CHART_PATH=$HELM_CHART_PATH
HELM_CHART_PACKAGE=$CHART_PACKAGE
HELM_CHART_VERSION=$CHART_VERSION
HELM_APP_VERSION=$APP_VERSION
GIT_COMMIT=$GIT_COMMIT_SHA
GIT_BRANCH=$GIT_BRANCH
EOF

echo "Helm chart information saved to build-info/helm-chart.txt"
cat build-info/helm-chart.txt

echo ""
echo "=== Helm Chart Package Script Complete ==="
