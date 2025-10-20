#!/bin/bash

# ==============================================================================
# BUILD SCRIPT
# ==============================================================================
# This script handles the build process for your project.
# Customize this script based on your programming language and build tool.
# ==============================================================================

set -e  # Exit on error

echo "=== Starting Build Process ==="
echo "Project: $BITBUCKET_REPO_SLUG"
echo "Branch: $BITBUCKET_BRANCH"
echo "Commit: $BITBUCKET_COMMIT"

# ==============================================================================
# JAVA / MAVEN
# ==============================================================================
# Uncomment this section if you're using Maven
if [ -f "pom.xml" ]; then
    echo "Detected Maven project (pom.xml found)"
    echo "Running Maven compile (verification only)..."
    echo "Note: Full packaging happens in package.sh to avoid duplication"
    mvn compile -DskipTests
    exit 0
fi

# ==============================================================================
# JAVA / GRADLE
# ==============================================================================
# Uncomment this section if you're using Gradle
# if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
#     echo "Detected Gradle project"
#     echo "Running Gradle build..."
#     ./gradlew clean build -x test
#     exit 0
# fi

# ==============================================================================
# NODE.JS / NPM
# ==============================================================================
# Uncomment this section if you're using Node.js with npm
# if [ -f "package.json" ]; then
#     echo "Detected Node.js project (package.json found)"
#     echo "Installing dependencies..."
#     npm install
#     echo "Running build..."
#     npm run build
#     exit 0
# fi

# ==============================================================================
# NODE.JS / YARN
# ==============================================================================
# Uncomment this section if you're using Yarn
# if [ -f "package.json" ] && [ -f "yarn.lock" ]; then
#     echo "Detected Yarn project"
#     echo "Installing dependencies..."
#     yarn install
#     echo "Running build..."
#     yarn build
#     exit 0
# fi

# ==============================================================================
# PYTHON
# ==============================================================================
# Uncomment this section if you're using Python
# if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
#     echo "Detected Python project"
#     echo "Installing dependencies..."
#     pip install -r requirements.txt
#     echo "Building Python package..."
#     python setup.py build
#     exit 0
# fi

# ==============================================================================
# GO
# ==============================================================================
# Uncomment this section if you're using Go
# if [ -f "go.mod" ]; then
#     echo "Detected Go project"
#     echo "Downloading dependencies..."
#     go mod download
#     echo "Building Go application..."
#     go build -v ./...
#     exit 0
# fi

# ==============================================================================
# .NET / C#
# ==============================================================================
# Uncomment this section if you're using .NET
# if ls *.csproj 1> /dev/null 2>&1; then
#     echo "Detected .NET project"
#     echo "Restoring packages..."
#     dotnet restore
#     echo "Building .NET application..."
#     dotnet build --configuration Release
#     exit 0
# fi

# ==============================================================================
# RUST
# ==============================================================================
# Uncomment this section if you're using Rust
# if [ -f "Cargo.toml" ]; then
#     echo "Detected Rust project"
#     echo "Building Rust application..."
#     cargo build --release
#     exit 0
# fi

# ==============================================================================
# PHP / COMPOSER
# ==============================================================================
# Uncomment this section if you're using PHP with Composer
# if [ -f "composer.json" ]; then
#     echo "Detected PHP project"
#     echo "Installing dependencies..."
#     composer install --no-dev --optimize-autoloader
#     exit 0
# fi

# ==============================================================================
# RUBY
# ==============================================================================
# Uncomment this section if you're using Ruby
# if [ -f "Gemfile" ]; then
#     echo "Detected Ruby project"
#     echo "Installing gems..."
#     bundle install
#     exit 0
# fi

# ==============================================================================
# CUSTOM BUILD COMMAND
# ==============================================================================
# If none of the above match your project, add your custom build command here:
# echo "Running custom build command..."
# your-custom-build-command

echo "=== Build Complete ==="
