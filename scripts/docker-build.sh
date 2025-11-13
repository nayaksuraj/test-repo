#!/bin/bash
# ==============================================================================
# Docker Build and Push Script
# ==============================================================================
# This script builds and pushes Docker images with proper tagging
# Reusable across multiple projects
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables (Override via environment or pipeline variables)
# ==============================================================================
# REQUIRED: These must be set via environment variables
if [[ -z "${DOCKER_REGISTRY}" ]]; then
    echo "ERROR: DOCKER_REGISTRY environment variable is required"
    echo "Example: export DOCKER_REGISTRY=docker.io"
    exit 1
fi

if [[ -z "${DOCKER_REPOSITORY}" ]]; then
    echo "ERROR: DOCKER_REPOSITORY environment variable is required"
    echo "Example: export DOCKER_REPOSITORY=myorg/myapp"
    exit 1
fi
DOCKERFILE_PATH="${DOCKERFILE_PATH:-./Dockerfile}"

# Get Git information
GIT_COMMIT_SHA=$(git rev-parse --short HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Determine environment from branch
if [[ "$GIT_BRANCH" == "develop" ]]; then
    ENVIRONMENT="dev"
elif [[ "$GIT_BRANCH" == "main" ]]; then
    ENVIRONMENT="stage"
elif [[ "$GIT_BRANCH" == "release" ]] || [[ "$GIT_BRANCH" =~ ^release/.* ]]; then
    ENVIRONMENT="prod"
elif [[ "$GIT_BRANCH" =~ ^feature/.* ]]; then
    ENVIRONMENT="feature"
elif [[ "$GIT_BRANCH" =~ ^hotfix/.* ]]; then
    ENVIRONMENT="hotfix"
else
    ENVIRONMENT="dev"
fi

# Build version tag
VERSION="${VERSION:-0.0.1-SNAPSHOT}"

# ==============================================================================
# Build Docker Image
# ==============================================================================
echo "=== Docker Build Started ==="
echo "Registry: $DOCKER_REGISTRY"
echo "Repository: $DOCKER_REPOSITORY"
echo "Environment: $ENVIRONMENT"
echo "Git Commit: $GIT_COMMIT_SHA"
echo "Git Branch: $GIT_BRANCH"
echo "Version: $VERSION"
echo ""

# Build tags
IMAGE_NAME="$DOCKER_REGISTRY/$DOCKER_REPOSITORY"
TAG_COMMIT="$ENVIRONMENT-$GIT_COMMIT_SHA"
TAG_LATEST="$ENVIRONMENT-latest"
TAG_VERSION="$ENVIRONMENT-$VERSION"

echo "Building Docker image..."
echo "Image: $IMAGE_NAME"
echo "Tags: $TAG_COMMIT, $TAG_LATEST, $TAG_VERSION"
echo ""

# Build the image with multiple tags
docker build \
    --file "$DOCKERFILE_PATH" \
    --tag "$IMAGE_NAME:$TAG_COMMIT" \
    --tag "$IMAGE_NAME:$TAG_LATEST" \
    --tag "$IMAGE_NAME:$TAG_VERSION" \
    --build-arg VERSION="$VERSION" \
    --build-arg GIT_COMMIT="$GIT_COMMIT_SHA" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    .

echo ""
echo "=== Docker Build Complete ==="

# ==============================================================================
# Push Docker Image (only if DOCKER_PUSH=true)
# ==============================================================================
if [[ "${DOCKER_PUSH}" == "true" ]]; then
    echo ""
    echo "=== Pushing Docker Images ==="

    # Login to Docker registry if credentials are provided
    if [[ -n "$DOCKER_USERNAME" ]] && [[ -n "$DOCKER_PASSWORD" ]]; then
        echo "Logging in to Docker registry..."
        echo "$DOCKER_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$DOCKER_USERNAME" --password-stdin
    fi

    # Push all tags
    echo "Pushing $IMAGE_NAME:$TAG_COMMIT..."
    docker push "$IMAGE_NAME:$TAG_COMMIT"

    echo "Pushing $IMAGE_NAME:$TAG_LATEST..."
    docker push "$IMAGE_NAME:$TAG_LATEST"

    echo "Pushing $IMAGE_NAME:$TAG_VERSION..."
    docker push "$IMAGE_NAME:$TAG_VERSION"

    echo ""
    echo "=== Docker Push Complete ==="
    echo "Image successfully pushed to: $DOCKER_REGISTRY/$DOCKER_REPOSITORY"
    echo "Available tags: $TAG_COMMIT, $TAG_LATEST, $TAG_VERSION"
else
    echo ""
    echo "=== Skipping Docker Push ==="
    echo "Set DOCKER_PUSH=true to push images"
fi

# ==============================================================================
# Export image information for use in subsequent steps
# ==============================================================================
echo ""
echo "=== Exporting Image Information ==="
export DOCKER_IMAGE_FULL="$IMAGE_NAME:$TAG_COMMIT"
export DOCKER_IMAGE_TAG="$TAG_COMMIT"

# Save to file for Bitbucket Pipelines artifacts
mkdir -p build-info
cat > build-info/docker-image.txt <<EOF
DOCKER_IMAGE=$IMAGE_NAME:$TAG_COMMIT
DOCKER_IMAGE_LATEST=$IMAGE_NAME:$TAG_LATEST
DOCKER_IMAGE_VERSION=$IMAGE_NAME:$TAG_VERSION
DOCKER_TAG=$TAG_COMMIT
ENVIRONMENT=$ENVIRONMENT
VERSION=$VERSION
GIT_COMMIT=$GIT_COMMIT_SHA
GIT_BRANCH=$GIT_BRANCH
EOF

echo "Docker image information saved to build-info/docker-image.txt"
cat build-info/docker-image.txt

echo ""
echo "=== Docker Build and Push Script Complete ==="
