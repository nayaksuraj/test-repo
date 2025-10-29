#!/bin/bash
# ==============================================================================
# Build and Push DevSecOps Toolbox Docker Image
# ==============================================================================

set -e

# Configuration
IMAGE_NAME="${IMAGE_NAME:-yourorg/devsecops-toolbox}"
VERSION="${VERSION:-1.0.0}"
REGISTRY="${REGISTRY:-docker.io}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
BUILD_TYPE="${BUILD_TYPE:-single}"  # single or multi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "==============================================================================="
echo "Building DevSecOps Toolbox Docker Image"
echo "==============================================================================="
echo "Image: ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
echo "Platforms: ${PLATFORMS}"
echo "Build Type: ${BUILD_TYPE}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Build for single platform
if [ "$BUILD_TYPE" = "single" ]; then
    echo -e "${BLUE}Building for single platform...${NC}"

    docker build \
        --tag ${REGISTRY}/${IMAGE_NAME}:${VERSION} \
        --tag ${REGISTRY}/${IMAGE_NAME}:latest \
        --build-arg GITLEAKS_VERSION=8.18.0 \
        --build-arg TRIVY_VERSION=0.48.0 \
        --build-arg HADOLINT_VERSION=2.12.0 \
        .

    echo -e "${GREEN}✓ Build complete${NC}"
    echo ""

    # Test the image
    echo -e "${BLUE}Testing the image...${NC}"
    docker run --rm ${REGISTRY}/${IMAGE_NAME}:${VERSION} gitleaks version
    docker run --rm ${REGISTRY}/${IMAGE_NAME}:${VERSION} trivy --version
    docker run --rm ${REGISTRY}/${IMAGE_NAME}:${VERSION} hadolint --version
    echo -e "${GREEN}✓ Tests passed${NC}"
    echo ""

    # Push to registry
    if [ "$1" = "push" ]; then
        echo -e "${BLUE}Pushing to registry...${NC}"

        docker push ${REGISTRY}/${IMAGE_NAME}:${VERSION}
        docker push ${REGISTRY}/${IMAGE_NAME}:latest

        echo -e "${GREEN}✓ Push complete${NC}"
    else
        echo -e "${BLUE}Skipping push (use './build-and-push.sh push' to push)${NC}"
    fi

# Build for multiple platforms
elif [ "$BUILD_TYPE" = "multi" ]; then
    echo -e "${BLUE}Building for multiple platforms...${NC}"

    # Check if buildx is available
    if ! docker buildx version &> /dev/null; then
        echo -e "${RED}Error: Docker buildx is not available${NC}"
        exit 1
    fi

    # Create or use existing builder
    if ! docker buildx inspect multiplatform &> /dev/null; then
        echo "Creating multiplatform builder..."
        docker buildx create --name multiplatform --use
    else
        docker buildx use multiplatform
    fi

    # Build and push for multiple platforms
    docker buildx build \
        --platform ${PLATFORMS} \
        --tag ${REGISTRY}/${IMAGE_NAME}:${VERSION} \
        --tag ${REGISTRY}/${IMAGE_NAME}:latest \
        --build-arg GITLEAKS_VERSION=8.18.0 \
        --build-arg TRIVY_VERSION=0.48.0 \
        --build-arg HADOLINT_VERSION=2.12.0 \
        --push \
        .

    echo -e "${GREEN}✓ Multi-platform build and push complete${NC}"
fi

echo ""
echo "==============================================================================="
echo "DevSecOps Toolbox Image Ready"
echo "==============================================================================="
echo ""
echo "Usage in Bitbucket Pipelines:"
echo ""
echo "  image: ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
echo ""
echo "  pipelines:"
echo "    default:"
echo "      - step:"
echo "          script:"
echo "            - security-secrets-scan.sh"
echo "            - security-sca-scan.sh"
echo ""
echo "Image size:"
docker images ${REGISTRY}/${IMAGE_NAME}:${VERSION} --format "{{.Size}}"
echo ""
