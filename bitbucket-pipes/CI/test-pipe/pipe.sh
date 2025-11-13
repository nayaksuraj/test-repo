#!/bin/bash
# ==============================================================================
# BITBUCKET PIPE: TEST-PIPE
# ==============================================================================
# Generic test execution pipe that auto-detects test frameworks
# Supports: Maven, Gradle, NPM, Yarn, Pytest, Go, .NET, PHP, Ruby
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Colors for output
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==============================================================================
# Configuration
# ==============================================================================
TEST_COMMAND="${TEST_COMMAND:-}"
TEST_TOOL="${TEST_TOOL:-}"
TEST_ARGS="${TEST_ARGS:-}"
INTEGRATION_TESTS="${INTEGRATION_TESTS:-false}"
WORKING_DIR="${WORKING_DIR:-.}"
SKIP_TESTS="${SKIP_TESTS:-false}"
COVERAGE_ENABLED="${COVERAGE_ENABLED:-false}"
DOCKER_REQUIRED="${DOCKER_REQUIRED:-false}"
DEBUG="${DEBUG:-false}"

# ==============================================================================
# Helper Functions
# ==============================================================================
debug() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${CYAN}[DEBUG] $*${NC}"
    fi
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
}

error() {
    echo -e "${RED}✗ $*${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $*${NC}"
}

info() {
    echo -e "${CYAN}ℹ $*${NC}"
}

# ==============================================================================
# Pipe Header
# ==============================================================================
echo "==============================================================================="
echo -e "${GREEN}🧪 TEST PIPE - GENERIC TEST EXECUTION${NC}"
echo "==============================================================================="
echo "Working Directory: ${WORKING_DIR}"
echo "Integration Tests: ${INTEGRATION_TESTS}"
echo "Coverage Enabled: ${COVERAGE_ENABLED}"
echo "Debug Mode: ${DEBUG}"
echo ""

# Change to working directory
cd "$WORKING_DIR" || {
    error "Failed to change to working directory: $WORKING_DIR"
    exit 1
}

# ==============================================================================
# Skip Tests Check
# ==============================================================================
if [ "$SKIP_TESTS" = "true" ]; then
    warning "Tests skipped (SKIP_TESTS=true)"
    exit 0
fi

# ==============================================================================
# Auto-detect Test Framework
# ==============================================================================
detect_test_framework() {
    debug "Auto-detecting test framework..."

    # Maven
    if [ -f "pom.xml" ]; then
        echo "maven"
        return
    fi

    # Gradle
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "gradle"
        return
    fi

    # Node.js / NPM
    if [ -f "package.json" ]; then
        if [ -f "yarn.lock" ]; then
            echo "yarn"
        else
            echo "npm"
        fi
        return
    fi

    # Python
    if [ -f "setup.py" ] || [ -f "pyproject.toml" ] || [ -f "pytest.ini" ]; then
        echo "pytest"
        return
    fi

    # Go
    if [ -f "go.mod" ]; then
        echo "go"
        return
    fi

    # .NET
    if ls *.csproj 1> /dev/null 2>&1 || ls *.sln 1> /dev/null 2>&1; then
        echo "dotnet"
        return
    fi

    # PHP
    if [ -f "composer.json" ] && [ -f "phpunit.xml" ]; then
        echo "phpunit"
        return
    fi

    # Ruby
    if [ -f "Gemfile" ]; then
        echo "rspec"
        return
    fi

    # Rust
    if [ -f "Cargo.toml" ]; then
        echo "cargo"
        return
    fi

    echo "unknown"
}

# ==============================================================================
# Docker Prerequisites Check
# ==============================================================================
check_docker_prerequisites() {
    if [ "$DOCKER_REQUIRED" = "true" ]; then
        info "Checking Docker prerequisites..."
        if ! docker info &> /dev/null; then
            error "Docker is not running"
            error "Integration tests require Docker for TestContainers"
            exit 1
        fi
        success "Docker is running"
    fi
}

# ==============================================================================
# Run Tests Based on Framework
# ==============================================================================
run_tests() {
    local framework=$1
    local test_type=$2  # unit or integration

    echo ""
    echo "=== Running ${test_type} Tests (${framework}) ==="
    echo ""

    case "$framework" in
        maven)
            run_maven_tests "$test_type"
            ;;
        gradle)
            run_gradle_tests "$test_type"
            ;;
        npm)
            run_npm_tests "$test_type"
            ;;
        yarn)
            run_yarn_tests "$test_type"
            ;;
        pytest)
            run_pytest_tests "$test_type"
            ;;
        go)
            run_go_tests "$test_type"
            ;;
        dotnet)
            run_dotnet_tests "$test_type"
            ;;
        phpunit)
            run_phpunit_tests "$test_type"
            ;;
        rspec)
            run_rspec_tests "$test_type"
            ;;
        cargo)
            run_cargo_tests "$test_type"
            ;;
        custom)
            run_custom_tests
            ;;
        *)
            error "Unknown test framework: $framework"
            exit 1
            ;;
    esac
}

# ==============================================================================
# Maven Tests
# ==============================================================================
run_maven_tests() {
    local test_type=$1

    if [ "$test_type" = "unit" ]; then
        info "Running Maven unit tests..."
        if [ "$COVERAGE_ENABLED" = "true" ]; then
            mvn clean test jacoco:report $TEST_ARGS
        else
            mvn test $TEST_ARGS
        fi
        success "Maven unit tests completed"
    elif [ "$test_type" = "integration" ]; then
        info "Running Maven integration tests..."
        check_docker_prerequisites
        mvn verify -DskipUnitTests=false -DskipIntegrationTests=false $TEST_ARGS
        success "Maven integration tests completed"
    fi
}

# ==============================================================================
# Gradle Tests
# ==============================================================================
run_gradle_tests() {
    local test_type=$1

    # Make gradlew executable if it exists
    [ -f "gradlew" ] && chmod +x gradlew

    if [ "$test_type" = "unit" ]; then
        info "Running Gradle unit tests..."
        if [ "$COVERAGE_ENABLED" = "true" ]; then
            ./gradlew test jacocoTestReport $TEST_ARGS
        else
            ./gradlew test $TEST_ARGS
        fi
        success "Gradle unit tests completed"
    elif [ "$test_type" = "integration" ]; then
        info "Running Gradle integration tests..."
        check_docker_prerequisites
        if ./gradlew tasks --all | grep -q "integrationTest"; then
            ./gradlew integrationTest $TEST_ARGS
        else
            warning "No integrationTest task found, running default test task"
            ./gradlew test $TEST_ARGS
        fi
        success "Gradle integration tests completed"
    fi
}

# ==============================================================================
# NPM Tests
# ==============================================================================
run_npm_tests() {
    local test_type=$1

    if [ "$test_type" = "unit" ]; then
        info "Running NPM tests..."
        npm test $TEST_ARGS
        success "NPM tests completed"
    elif [ "$test_type" = "integration" ]; then
        info "Running NPM integration tests..."
        if npm run | grep -q "test:integration"; then
            npm run test:integration $TEST_ARGS
        else
            warning "No test:integration script found in package.json"
        fi
    fi
}

# ==============================================================================
# Yarn Tests
# ==============================================================================
run_yarn_tests() {
    local test_type=$1

    if [ "$test_type" = "unit" ]; then
        info "Running Yarn tests..."
        yarn test $TEST_ARGS
        success "Yarn tests completed"
    elif [ "$test_type" = "integration" ]; then
        info "Running Yarn integration tests..."
        if yarn run | grep -q "test:integration"; then
            yarn test:integration $TEST_ARGS
        else
            warning "No test:integration script found"
        fi
    fi
}

# ==============================================================================
# Pytest Tests
# ==============================================================================
run_pytest_tests() {
    local test_type=$1

    if [ "$test_type" = "unit" ]; then
        info "Running Pytest..."
        if [ "$COVERAGE_ENABLED" = "true" ]; then
            pytest --cov --cov-report=html --cov-report=xml $TEST_ARGS
        else
            pytest $TEST_ARGS
        fi
        success "Pytest completed"
    elif [ "$test_type" = "integration" ]; then
        info "Running Pytest integration tests..."
        pytest tests/integration/ $TEST_ARGS 2>/dev/null || \
            warning "No integration tests found in tests/integration/"
    fi
}

# ==============================================================================
# Go Tests
# ==============================================================================
run_go_tests() {
    local test_type=$1

    if [ "$test_type" = "unit" ]; then
        info "Running Go tests..."
        if [ "$COVERAGE_ENABLED" = "true" ]; then
            go test -v -coverprofile=coverage.out ./... $TEST_ARGS
            go tool cover -html=coverage.out -o coverage.html
        else
            go test -v ./... $TEST_ARGS
        fi
        success "Go tests completed"
    elif [ "$test_type" = "integration" ]; then
        info "Running Go integration tests..."
        go test -v -tags=integration ./... $TEST_ARGS
    fi
}

# ==============================================================================
# .NET Tests
# ==============================================================================
run_dotnet_tests() {
    local test_type=$1

    if [ "$test_type" = "unit" ]; then
        info "Running .NET tests..."
        if [ "$COVERAGE_ENABLED" = "true" ]; then
            dotnet test --collect:"XPlat Code Coverage" $TEST_ARGS
        else
            dotnet test $TEST_ARGS
        fi
        success ".NET tests completed"
    elif [ "$test_type" = "integration" ]; then
        info "Running .NET integration tests..."
        dotnet test --filter Category=Integration $TEST_ARGS
    fi
}

# ==============================================================================
# PHPUnit Tests
# ==============================================================================
run_phpunit_tests() {
    local test_type=$1

    if [ "$test_type" = "unit" ]; then
        info "Running PHPUnit tests..."
        ./vendor/bin/phpunit $TEST_ARGS
        success "PHPUnit tests completed"
    fi
}

# ==============================================================================
# RSpec Tests
# ==============================================================================
run_rspec_tests() {
    local test_type=$1

    if [ "$test_type" = "unit" ]; then
        info "Running RSpec tests..."
        bundle exec rspec $TEST_ARGS
        success "RSpec tests completed"
    fi
}

# ==============================================================================
# Cargo Tests
# ==============================================================================
run_cargo_tests() {
    local test_type=$1

    if [ "$test_type" = "unit" ]; then
        info "Running Cargo tests..."
        cargo test $TEST_ARGS
        success "Cargo tests completed"
    fi
}

# ==============================================================================
# Custom Tests
# ==============================================================================
run_custom_tests() {
    if [ -n "$TEST_COMMAND" ]; then
        info "Running custom test command: $TEST_COMMAND"
        eval "$TEST_COMMAND $TEST_ARGS"
        success "Custom tests completed"
    else
        error "TEST_COMMAND is required when using custom framework"
        exit 1
    fi
}

# ==============================================================================
# Display Test Results
# ==============================================================================
display_test_results() {
    echo ""
    echo "=== Test Results ==="
    echo ""

    # Try to find and display test report summaries
    if [ -f "target/surefire-reports" ]; then
        info "Maven test reports: target/surefire-reports/"
    fi

    if [ -f "build/reports/tests/test" ]; then
        info "Gradle test reports: build/reports/tests/test/"
    fi

    if [ -f "coverage.html" ] || [ -f "htmlcov/index.html" ]; then
        info "Coverage reports generated"
    fi

    if [ -d "target/site/jacoco" ]; then
        info "JaCoCo coverage report: target/site/jacoco/index.html"
    fi
}

# ==============================================================================
# Main Execution
# ==============================================================================
main() {
    # Detect or use specified framework
    if [ -n "$TEST_COMMAND" ]; then
        FRAMEWORK="custom"
    elif [ -n "$TEST_TOOL" ]; then
        FRAMEWORK="$TEST_TOOL"
    else
        FRAMEWORK=$(detect_test_framework)
    fi

    if [ "$FRAMEWORK" = "unknown" ]; then
        error "Unable to detect test framework"
        error "Please specify TEST_TOOL or TEST_COMMAND"
        exit 1
    fi

    success "Detected test framework: $FRAMEWORK"

    # Run unit tests
    run_tests "$FRAMEWORK" "unit"

    # Run integration tests if enabled
    if [ "$INTEGRATION_TESTS" = "true" ]; then
        run_tests "$FRAMEWORK" "integration"
    fi

    # Display results
    display_test_results

    echo ""
    echo "==============================================================================="
    echo -e "${GREEN}✓ TEST EXECUTION COMPLETE${NC}"
    echo "==============================================================================="
}

# Run main function
main
