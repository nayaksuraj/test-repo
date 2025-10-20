#!/bin/bash

# ==============================================================================
# PACKAGE SCRIPT
# ==============================================================================
# This script handles packaging your application for deployment.
# Customize this script based on your programming language and deployment needs.
# ==============================================================================

set -e  # Exit on error

echo "=== Starting Package Process ==="

# ==============================================================================
# JAVA / MAVEN
# ==============================================================================
# Uncomment this section if you're using Maven
if [ -f "pom.xml" ]; then
    echo "Detected Maven project (pom.xml found)"
    echo "Packaging with Maven (single build - no duplication)..."
    mvn clean package -DskipTests -B

    echo "Artifacts created:"
    ls -lh target/*.jar 2>/dev/null || echo "No JAR files found"
    ls -lh target/*.war 2>/dev/null || echo "No WAR files found"

    # Create build-info directory for artifact metadata
    mkdir -p build-info
    echo "BUILD_TIMESTAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" > build-info/build.txt
    echo "GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" >> build-info/build.txt
    echo "GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')" >> build-info/build.txt

    echo "Build info saved to build-info/build.txt"
    exit 0
fi

# ==============================================================================
# JAVA / GRADLE
# ==============================================================================
# Uncomment this section if you're using Gradle
# if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
#     echo "Detected Gradle project"
#     echo "Packaging with Gradle..."
#     ./gradlew assemble -x test
#
#     echo "Artifacts created:"
#     ls -lh build/libs/*.jar 2>/dev/null || echo "No JAR files found"
#     exit 0
# fi

# ==============================================================================
# NODE.JS / NPM
# ==============================================================================
# Uncomment this section if you're using Node.js with npm
# if [ -f "package.json" ]; then
#     echo "Detected Node.js project (package.json found)"
#     echo "Building production bundle..."
#     npm run build
#
#     # Optional: Create a tarball for deployment
#     # echo "Creating deployment tarball..."
#     # tar -czf app.tar.gz dist/ package.json package-lock.json
#
#     echo "Build artifacts:"
#     ls -lh dist/ 2>/dev/null || ls -lh build/ 2>/dev/null || echo "No build directory found"
#     exit 0
# fi

# ==============================================================================
# NODE.JS / YARN
# ==============================================================================
# Uncomment this section if you're using Yarn
# if [ -f "package.json" ] && [ -f "yarn.lock" ]; then
#     echo "Detected Yarn project"
#     echo "Building production bundle..."
#     yarn build
#
#     echo "Build artifacts:"
#     ls -lh dist/ 2>/dev/null || ls -lh build/ 2>/dev/null || echo "No build directory found"
#     exit 0
# fi

# ==============================================================================
# PYTHON
# ==============================================================================
# Uncomment this section if you're using Python
# if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
#     echo "Detected Python project"
#     echo "Building Python distribution..."
#     python setup.py sdist bdist_wheel
#
#     echo "Distribution packages:"
#     ls -lh dist/
#     exit 0
# fi

# ==============================================================================
# GO
# ==============================================================================
# Uncomment this section if you're using Go
# if [ -f "go.mod" ]; then
#     echo "Detected Go project"
#     echo "Building Go binary..."
#
#     # Get the binary name from go.mod
#     BINARY_NAME=$(grep "^module" go.mod | awk '{print $2}' | awk -F'/' '{print $NF}')
#
#     # Build for Linux (common deployment target)
#     GOOS=linux GOARCH=amd64 go build -o "${BINARY_NAME}-linux-amd64" ./...
#
#     echo "Binary created:"
#     ls -lh "${BINARY_NAME}-linux-amd64"
#     exit 0
# fi

# ==============================================================================
# .NET / C#
# ==============================================================================
# Uncomment this section if you're using .NET
# if ls *.csproj 1> /dev/null 2>&1; then
#     echo "Detected .NET project"
#     echo "Publishing .NET application..."
#     dotnet publish --configuration Release --output ./publish
#
#     echo "Published files:"
#     ls -lh ./publish/
#     exit 0
# fi

# ==============================================================================
# RUST
# ==============================================================================
# Uncomment this section if you're using Rust
# if [ -f "Cargo.toml" ]; then
#     echo "Detected Rust project"
#     echo "Building Rust release binary..."
#     cargo build --release
#
#     echo "Binary created:"
#     ls -lh target/release/
#     exit 0
# fi

# ==============================================================================
# PHP / COMPOSER
# ==============================================================================
# Uncomment this section if you're using PHP
# if [ -f "composer.json" ]; then
#     echo "Detected PHP project"
#     echo "Installing production dependencies..."
#     composer install --no-dev --optimize-autoloader
#
#     # Optional: Create deployment archive
#     # echo "Creating deployment archive..."
#     # tar -czf app.tar.gz --exclude='tests' --exclude='.git' .
#
#     exit 0
# fi

# ==============================================================================
# DOCKER BUILD
# ==============================================================================
# Uncomment this section if you want to build a Docker image
# if [ -f "Dockerfile" ]; then
#     echo "Detected Dockerfile"
#     echo "Building Docker image..."
#
#     IMAGE_NAME="${BITBUCKET_REPO_SLUG:-myapp}"
#     IMAGE_TAG="${BITBUCKET_COMMIT:-latest}"
#
#     docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
#     docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_NAME}:latest"
#
#     echo "Docker image created: ${IMAGE_NAME}:${IMAGE_TAG}"
#     exit 0
# fi

# ==============================================================================
# CUSTOM PACKAGE COMMAND
# ==============================================================================
# If none of the above match your project, add your custom package command here:
# echo "Running custom package command..."
# your-custom-package-command

echo "=== Package Complete ==="
