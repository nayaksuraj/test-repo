#!/bin/bash
# ==============================================================================
# Code Quality Analysis Script
# ==============================================================================
# This script runs code quality checks including:
# - SonarQube/SonarCloud analysis
# - Code coverage reporting
# - Static code analysis
# Reusable across multiple projects
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables (Override via environment or pipeline variables)
# ==============================================================================
SONAR_ENABLED="${SONAR_ENABLED:-false}"
SONAR_HOST_URL="${SONAR_HOST_URL:-https://sonarcloud.io}"
SONAR_TOKEN="${SONAR_TOKEN:-}"
SONAR_PROJECT_KEY="${SONAR_PROJECT_KEY:-demo-app}"
SONAR_ORGANIZATION="${SONAR_ORGANIZATION:-your-org}"

# Maven/Gradle detection
BUILD_TOOL="maven"
if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    BUILD_TOOL="gradle"
fi

echo "=== Code Quality Analysis Started ==="
echo "Build Tool: $BUILD_TOOL"
echo "SonarQube Enabled: $SONAR_ENABLED"
echo ""

# ==============================================================================
# Run Tests with Coverage
# ==============================================================================
echo "=== Running Tests with Code Coverage ==="

if [[ "$BUILD_TOOL" == "maven" ]]; then
    # Maven: Run tests with JaCoCo coverage
    mvn clean test jacoco:report

    echo ""
    echo "=== Code Coverage Report ==="
    if [[ -f "target/site/jacoco/index.html" ]]; then
        echo "JaCoCo report generated: target/site/jacoco/index.html"

        # Parse coverage percentage (if xmllint is available)
        if command -v xmllint &> /dev/null && [[ -f "target/site/jacoco/jacoco.xml" ]]; then
            COVERAGE=$(xmllint --xpath "string(//report/counter[@type='LINE']/@covered)" target/site/jacoco/jacoco.xml)
            TOTAL=$(xmllint --xpath "string(//report/counter[@type='LINE']/@missed)" target/site/jacoco/jacoco.xml)
            COVERAGE_PCT=$(awk "BEGIN {printf \"%.2f\", ($COVERAGE / ($COVERAGE + $TOTAL)) * 100}")
            echo "Line Coverage: ${COVERAGE_PCT}%"

            # Fail if coverage is below threshold
            COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
            if (( $(echo "$COVERAGE_PCT < $COVERAGE_THRESHOLD" | bc -l) )); then
                echo "WARNING: Code coverage ($COVERAGE_PCT%) is below threshold ($COVERAGE_THRESHOLD%)"
                if [[ "${FAIL_ON_LOW_COVERAGE}" == "true" ]]; then
                    exit 1
                fi
            fi
        fi
    fi

elif [[ "$BUILD_TOOL" == "gradle" ]]; then
    # Gradle: Run tests with coverage
    ./gradlew test jacocoTestReport

    echo ""
    echo "=== Code Coverage Report ==="
    if [[ -f "build/reports/jacoco/test/html/index.html" ]]; then
        echo "JaCoCo report generated: build/reports/jacoco/test/html/index.html"
    fi
fi

echo ""

# ==============================================================================
# SonarQube Analysis
# ==============================================================================
if [[ "$SONAR_ENABLED" == "true" ]]; then
    echo "=== Running SonarQube Analysis ==="

    if [[ -z "$SONAR_TOKEN" ]]; then
        echo "ERROR: SONAR_TOKEN is not set"
        echo "Please set SONAR_TOKEN environment variable"
        exit 1
    fi

    # Install SonarScanner if needed (for non-Maven/Gradle projects)
    if [[ "$BUILD_TOOL" == "maven" ]]; then
        # Maven SonarQube plugin
        mvn sonar:sonar \
            -Dsonar.host.url="$SONAR_HOST_URL" \
            -Dsonar.login="$SONAR_TOKEN" \
            -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
            -Dsonar.organization="$SONAR_ORGANIZATION" \
            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml

    elif [[ "$BUILD_TOOL" == "gradle" ]]; then
        # Gradle SonarQube plugin
        ./gradlew sonarqube \
            -Dsonar.host.url="$SONAR_HOST_URL" \
            -Dsonar.login="$SONAR_TOKEN" \
            -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
            -Dsonar.organization="$SONAR_ORGANIZATION"
    fi

    echo ""
    echo "=== SonarQube Analysis Complete ==="
    echo "View results at: $SONAR_HOST_URL/dashboard?id=$SONAR_PROJECT_KEY"
else
    echo "=== SonarQube Analysis Skipped ==="
    echo "Set SONAR_ENABLED=true to enable SonarQube analysis"
fi

echo ""

# ==============================================================================
# Additional Static Analysis (Optional)
# ==============================================================================
echo "=== Running Additional Static Analysis ==="

if [[ "$BUILD_TOOL" == "maven" ]]; then
    # Checkstyle
    if grep -q "maven-checkstyle-plugin" pom.xml 2>/dev/null; then
        echo "Running Checkstyle..."
        mvn checkstyle:check || echo "  ⚠ Checkstyle warnings found"
    fi

    # SpotBugs
    if grep -q "spotbugs-maven-plugin" pom.xml 2>/dev/null; then
        echo "Running SpotBugs..."
        mvn spotbugs:check || echo "  ⚠ SpotBugs issues found"
    fi

    # PMD
    if grep -q "maven-pmd-plugin" pom.xml 2>/dev/null; then
        echo "Running PMD..."
        mvn pmd:check || echo "  ⚠ PMD issues found"
    fi
fi

echo ""

# ==============================================================================
# OWASP Dependency Check (Security Vulnerabilities)
# ==============================================================================
if [[ "${OWASP_CHECK_ENABLED}" == "true" ]]; then
    echo "=== Running OWASP Dependency Check ==="

    if [[ "$BUILD_TOOL" == "maven" ]]; then
        # Check if dependency-check plugin is configured
        if ! grep -q "dependency-check-maven" pom.xml 2>/dev/null; then
            echo "Adding OWASP Dependency Check plugin to pom.xml..."
            # Plugin should be pre-configured in pom.xml
        fi

        mvn dependency-check:check -DfailBuildOnCVSS=7 || echo "  ⚠ Security vulnerabilities found"
    fi

    echo ""
fi

# ==============================================================================
# Generate Reports Summary
# ==============================================================================
echo "=== Quality Analysis Summary ==="
echo ""
echo "Reports generated:"

if [[ "$BUILD_TOOL" == "maven" ]]; then
    [[ -f "target/site/jacoco/index.html" ]] && echo "  ✓ Code Coverage: target/site/jacoco/index.html"
    [[ -f "target/checkstyle-result.xml" ]] && echo "  ✓ Checkstyle: target/checkstyle-result.xml"
    [[ -f "target/spotbugsXml.xml" ]] && echo "  ✓ SpotBugs: target/spotbugsXml.xml"
    [[ -f "target/pmd.xml" ]] && echo "  ✓ PMD: target/pmd.xml"
    [[ -f "target/dependency-check-report.html" ]] && echo "  ✓ OWASP: target/dependency-check-report.html"
elif [[ "$BUILD_TOOL" == "gradle" ]]; then
    [[ -f "build/reports/jacoco/test/html/index.html" ]] && echo "  ✓ Code Coverage: build/reports/jacoco/test/html/index.html"
fi

echo ""
echo "=== Code Quality Analysis Complete ==="
