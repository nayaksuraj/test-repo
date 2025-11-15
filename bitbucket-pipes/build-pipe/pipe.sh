#!/bin/bash
# =============================================================================
# Build Pipe - Generic Application Builder
# =============================================================================
set -e
set -o pipefail

# Enable debug if requested
if [[ "${DEBUG}" == "true" ]]; then
    set -x
fi

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

info "Starting Build Pipe v1.0.0"
info "Working directory: ${WORKING_DIR:-.}"

# Change to working directory
cd "${WORKING_DIR:-.}" || error "Failed to change to directory: ${WORKING_DIR}"

# =============================================================================
# Auto-detect build tool if not specified
# =============================================================================
detect_build_tool() {
    if [[ -f "pom.xml" ]]; then
        echo "maven"
    elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        echo "gradle"
    elif [[ -f "package.json" ]]; then
        echo "npm"
    elif [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
        echo "python"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
        echo "dotnet"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "Gemfile" ]]; then
        echo "ruby"
    else
        echo "unknown"
    fi
}

# Detect or use specified build tool
if [[ -n "${BUILD_TOOL}" ]]; then
    info "Using specified build tool: ${BUILD_TOOL}"
    DETECTED_TOOL="${BUILD_TOOL}"
else
    DETECTED_TOOL=$(detect_build_tool)
    info "Auto-detected build tool: ${DETECTED_TOOL}"
fi

# =============================================================================
# Execute build based on tool
# =============================================================================
if [[ -n "${BUILD_COMMAND}" ]]; then
    info "Using custom build command: ${BUILD_COMMAND}"
    eval "${BUILD_COMMAND} ${BUILD_ARGS}"
else
    case "${DETECTED_TOOL}" in
        maven)
            info "Building with Maven..."
            mvn clean compile ${BUILD_ARGS}
            ;;
        gradle)
            info "Building with Gradle..."
            ./gradlew clean build ${BUILD_ARGS}
            ;;
        npm)
            info "Building with npm..."
            npm install
            npm run build ${BUILD_ARGS}
            ;;
        python)
            info "Building with Python..."
            if [[ -f "setup.py" ]]; then
                python setup.py build ${BUILD_ARGS}
            else
                info "No setup.py found, skipping build"
            fi
            ;;
        go)
            info "Building with Go..."
            go build ${BUILD_ARGS} ./...
            ;;
        dotnet)
            info "Building with .NET..."
            dotnet build ${BUILD_ARGS}
            ;;
        rust)
            info "Building with Rust..."
            cargo build ${BUILD_ARGS}
            ;;
        ruby)
            info "Building with Ruby/Bundler..."
            bundle install
            ;;
        unknown)
            error "Could not detect build tool. Please specify BUILD_COMMAND or BUILD_TOOL"
            ;;
        *)
            error "Unsupported build tool: ${DETECTED_TOOL}"
            ;;
    esac
fi

info "✓ Build completed successfully"
