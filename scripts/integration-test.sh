#!/bin/bash
# ==============================================================================
# Integration Tests Script
# ==============================================================================
# This script runs integration tests using Maven Failsafe or Gradle
# Supports TestContainers for database and service integration tests
# Reusable across multiple projects
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables
# ==============================================================================
BUILD_TOOL="maven"
if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    BUILD_TOOL="gradle"
fi

# Docker is required for TestContainers
DOCKER_REQUIRED="${DOCKER_REQUIRED:-true}"

echo "=== Integration Tests Started ==="
echo "Build Tool: $BUILD_TOOL"
echo ""

# ==============================================================================
# Prerequisites Check
# ==============================================================================
echo "=== Checking Prerequisites ==="

# Check if Docker is running (required for TestContainers)
if [[ "$DOCKER_REQUIRED" == "true" ]]; then
    if ! docker info &> /dev/null; then
        echo "ERROR: Docker is not running"
        echo "Integration tests require Docker for TestContainers"
        echo "Please start Docker daemon or set DOCKER_REQUIRED=false"
        exit 1
    fi
    echo "✓ Docker is running"
fi

# Check Docker Compose (optional, for complex test environments)
if command -v docker-compose &> /dev/null; then
    echo "✓ Docker Compose is available"
fi

echo ""

# ==============================================================================
# Setup Test Environment
# ==============================================================================
echo "=== Setting Up Test Environment ==="

# Set environment variables for tests
export TESTCONTAINERS_RYUK_DISABLED="${TESTCONTAINERS_RYUK_DISABLED:-false}"
export TESTCONTAINERS_CHECKS_DISABLE="${TESTCONTAINERS_CHECKS_DISABLE:-false}"

# Pull common images to speed up tests (optional)
if [[ "${PRE_PULL_IMAGES}" == "true" ]]; then
    echo "Pre-pulling TestContainers images..."
    docker pull testcontainers/ryuk:0.5.1 2>/dev/null || true
    # Add more images as needed for your tests
fi

echo "✓ Test environment ready"
echo ""

# ==============================================================================
# Run Integration Tests
# ==============================================================================
echo "=== Running Integration Tests ==="

if [[ "$BUILD_TOOL" == "maven" ]]; then
    # Maven: Run integration tests with Failsafe plugin
    echo "Running Maven integration tests (Failsafe)..."

    # Integration tests are typically named *IT.java or *IntegrationTest.java
    mvn verify \
        -DskipUnitTests=false \
        -DskipIntegrationTests=false \
        -Dfailsafe.rerunFailingTestsCount=2

    echo ""
    echo "=== Integration Test Results ==="

    # Check for test reports
    if [[ -f "target/failsafe-reports/failsafe-summary.xml" ]]; then
        echo "Integration test report: target/failsafe-reports/failsafe-summary.xml"

        # Parse test results (if xmllint is available)
        if command -v xmllint &> /dev/null; then
            TESTS=$(xmllint --xpath "string(//failsafe-summary/@result)" target/failsafe-reports/failsafe-summary.xml)
            echo "Tests result: $TESTS"
        fi
    fi

    # List all integration test reports
    if [[ -d "target/failsafe-reports" ]]; then
        echo ""
        echo "Integration test reports:"
        ls -lh target/failsafe-reports/*.xml 2>/dev/null || echo "No XML reports found"
    fi

elif [[ "$BUILD_TOOL" == "gradle" ]]; then
    # Gradle: Run integration tests
    echo "Running Gradle integration tests..."

    # Assuming integration tests are in integrationTest source set
    if ./gradlew tasks --all | grep -q "integrationTest"; then
        ./gradlew integrationTest --info
    else
        # Fallback to test task
        ./gradlew test --info
    fi

    echo ""
    echo "=== Integration Test Results ==="
    if [[ -d "build/reports/tests/integrationTest" ]]; then
        echo "Integration test report: build/reports/tests/integrationTest/index.html"
    elif [[ -d "build/reports/tests/test" ]]; then
        echo "Test report: build/reports/tests/test/index.html"
    fi
fi

echo ""

# ==============================================================================
# Cleanup Test Containers
# ==============================================================================
echo "=== Cleaning Up Test Resources ==="

# Stop and remove any dangling TestContainers
if [[ "$DOCKER_REQUIRED" == "true" ]]; then
    echo "Cleaning up TestContainers..."

    # Remove containers created by TestContainers
    docker ps -a --filter "label=org.testcontainers=true" -q | xargs -r docker rm -f 2>/dev/null || true

    # Remove networks created by TestContainers
    docker network ls --filter "label=org.testcontainers=true" -q | xargs -r docker network rm 2>/dev/null || true

    # Prune volumes (optional - be careful in CI/CD)
    if [[ "${CLEANUP_VOLUMES}" == "true" ]]; then
        docker volume prune -f --filter "label=org.testcontainers=true" 2>/dev/null || true
    fi

    echo "✓ Test resources cleaned up"
fi

echo ""

# ==============================================================================
# Generate Test Coverage Report (Combined with Integration Tests)
# ==============================================================================
if [[ "${GENERATE_COVERAGE}" == "true" ]]; then
    echo "=== Generating Combined Test Coverage ==="

    if [[ "$BUILD_TOOL" == "maven" ]]; then
        # Generate combined coverage report (unit + integration tests)
        mvn jacoco:report-aggregate || mvn jacoco:report

        if [[ -f "target/site/jacoco-aggregate/index.html" ]]; then
            echo "Combined coverage report: target/site/jacoco-aggregate/index.html"
        elif [[ -f "target/site/jacoco/index.html" ]]; then
            echo "Coverage report: target/site/jacoco/index.html"
        fi
    fi

    echo ""
fi

# ==============================================================================
# Summary
# ==============================================================================
echo "=== Integration Tests Complete ==="
echo ""
echo "Next steps:"
echo "  - Review test reports in target/failsafe-reports/ or build/reports/tests/"
echo "  - Check test coverage reports"
echo "  - Ensure all critical integration tests are passing"
echo ""
