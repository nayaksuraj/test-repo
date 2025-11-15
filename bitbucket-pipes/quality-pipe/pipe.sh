#!/bin/bash
# ==============================================================================
# BITBUCKET PIPE: QUALITY-PIPE
# ==============================================================================
# Generic code quality analysis pipe for multiple languages
# Supports: SonarQube, Linting, Coverage, Static Analysis
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
QUALITY_COMMAND="${QUALITY_COMMAND:-}"
SONAR_ENABLED="${SONAR_ENABLED:-false}"
SONAR_TOKEN="${SONAR_TOKEN:-}"
SONAR_HOST_URL="${SONAR_HOST_URL:-https://sonarcloud.io}"
SONAR_PROJECT_KEY="${SONAR_PROJECT_KEY:-}"
SONAR_ORGANIZATION="${SONAR_ORGANIZATION:-}"
CHECKSTYLE_ENABLED="${CHECKSTYLE_ENABLED:-false}"
LINT_ENABLED="${LINT_ENABLED:-true}"
COVERAGE_ENABLED="${COVERAGE_ENABLED:-true}"
COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
FAIL_ON_LOW_COVERAGE="${FAIL_ON_LOW_COVERAGE:-false}"
SPOTBUGS_ENABLED="${SPOTBUGS_ENABLED:-false}"
PMD_ENABLED="${PMD_ENABLED:-false}"
WORKING_DIR="${WORKING_DIR:-.}"
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
echo -e "${GREEN}📊 QUALITY PIPE - CODE QUALITY ANALYSIS${NC}"
echo "==============================================================================="
echo "Working Directory: ${WORKING_DIR}"
echo "SonarQube Enabled: ${SONAR_ENABLED}"
echo "Coverage Enabled: ${COVERAGE_ENABLED}"
echo "Lint Enabled: ${LINT_ENABLED}"
echo "Debug Mode: ${DEBUG}"
echo ""

# Change to working directory
cd "$WORKING_DIR" || {
    error "Failed to change to working directory: $WORKING_DIR"
    exit 1
}

# ==============================================================================
# Auto-detect Build Tool
# ==============================================================================
detect_build_tool() {
    debug "Auto-detecting build tool..."

    if [ -f "pom.xml" ]; then
        echo "maven"
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "gradle"
    elif [ -f "package.json" ]; then
        echo "npm"
    elif [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        echo "python"
    elif [ -f "go.mod" ]; then
        echo "go"
    elif ls *.csproj 1> /dev/null 2>&1; then
        echo "dotnet"
    else
        echo "unknown"
    fi
}

BUILD_TOOL=$(detect_build_tool)
success "Detected build tool: $BUILD_TOOL"

# ==============================================================================
# Run Tests with Coverage
# ==============================================================================
run_tests_with_coverage() {
    if [ "$COVERAGE_ENABLED" = "false" ]; then
        info "Coverage collection disabled"
        return 0
    fi

    echo ""
    echo "=== Running Tests with Code Coverage ==="
    echo ""

    case "$BUILD_TOOL" in
        maven)
            info "Running Maven tests with JaCoCo coverage..."
            mvn clean test jacoco:report
            success "Maven tests with coverage completed"
            ;;
        gradle)
            info "Running Gradle tests with coverage..."
            [ -f "gradlew" ] && chmod +x gradlew
            ./gradlew test jacocoTestReport
            success "Gradle tests with coverage completed"
            ;;
        npm)
            info "Running NPM tests with coverage..."
            if grep -q '"test"' package.json; then
                npm test -- --coverage 2>/dev/null || npm test
            fi
            success "NPM tests completed"
            ;;
        python)
            info "Running Python tests with coverage..."
            if command -v pytest &> /dev/null; then
                pytest --cov --cov-report=html --cov-report=xml 2>/dev/null || true
            fi
            success "Python tests with coverage completed"
            ;;
        go)
            info "Running Go tests with coverage..."
            go test -coverprofile=coverage.out ./... 2>/dev/null || true
            [ -f coverage.out ] && go tool cover -html=coverage.out -o coverage.html
            success "Go tests with coverage completed"
            ;;
        dotnet)
            info "Running .NET tests with coverage..."
            dotnet test --collect:"XPlat Code Coverage" 2>/dev/null || true
            success ".NET tests with coverage completed"
            ;;
        *)
            warning "Coverage not available for $BUILD_TOOL"
            ;;
    esac
}

# ==============================================================================
# Check Coverage Threshold
# ==============================================================================
check_coverage_threshold() {
    if [ "$COVERAGE_ENABLED" = "false" ]; then
        return 0
    fi

    echo ""
    echo "=== Checking Coverage Threshold ==="
    echo ""

    local coverage_pct="0"
    local threshold="$COVERAGE_THRESHOLD"

    case "$BUILD_TOOL" in
        maven)
            if [ -f "target/site/jacoco/jacoco.xml" ]; then
                if command -v xmlstarlet &> /dev/null; then
                    local covered=$(xmlstarlet sel -t -v "sum(//counter[@type='LINE']/@covered)" target/site/jacoco/jacoco.xml)
                    local missed=$(xmlstarlet sel -t -v "sum(//counter[@type='LINE']/@missed)" target/site/jacoco/jacoco.xml)
                    if [ -n "$covered" ] && [ -n "$missed" ]; then
                        coverage_pct=$(awk "BEGIN {printf \"%.2f\", ($covered / ($covered + $missed)) * 100}")
                    fi
                fi
                info "JaCoCo report: target/site/jacoco/index.html"
            fi
            ;;
        gradle)
            if [ -f "build/reports/jacoco/test/html/index.html" ]; then
                info "JaCoCo report: build/reports/jacoco/test/html/index.html"
            fi
            ;;
        python)
            if [ -f "htmlcov/index.html" ]; then
                info "Coverage report: htmlcov/index.html"
            fi
            ;;
        go)
            if [ -f "coverage.html" ]; then
                info "Coverage report: coverage.html"
            fi
            ;;
    esac

    if [ "$coverage_pct" != "0" ]; then
        info "Line Coverage: ${coverage_pct}%"

        if (( $(echo "$coverage_pct < $threshold" | bc -l) )); then
            warning "Code coverage ($coverage_pct%) is below threshold ($threshold%)"
            if [ "$FAIL_ON_LOW_COVERAGE" = "true" ]; then
                error "Failing due to low coverage"
                exit 1
            fi
        else
            success "Coverage meets threshold: ${coverage_pct}% >= ${threshold}%"
        fi
    fi
}

# ==============================================================================
# Run Linting
# ==============================================================================
run_linting() {
    if [ "$LINT_ENABLED" = "false" ]; then
        info "Linting disabled"
        return 0
    fi

    echo ""
    echo "=== Running Linting ==="
    echo ""

    case "$BUILD_TOOL" in
        npm)
            if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || grep -q "eslint" package.json 2>/dev/null; then
                info "Running ESLint..."
                npx eslint . --ext .js,.jsx,.ts,.tsx 2>/dev/null || warning "ESLint found issues"
            fi
            ;;
        python)
            if command -v pylint &> /dev/null; then
                info "Running Pylint..."
                find . -name "*.py" -not -path "*/venv/*" -not -path "*/.venv/*" | xargs pylint 2>/dev/null || warning "Pylint found issues"
            fi
            if command -v flake8 &> /dev/null; then
                info "Running Flake8..."
                flake8 . --exclude=venv,.venv,__pycache__ 2>/dev/null || warning "Flake8 found issues"
            fi
            ;;
        go)
            if command -v golint &> /dev/null; then
                info "Running golint..."
                golint ./... 2>/dev/null || warning "Golint found issues"
            fi
            ;;
        *)
            debug "No linting configured for $BUILD_TOOL"
            ;;
    esac
}

# ==============================================================================
# Run Static Analysis
# ==============================================================================
run_static_analysis() {
    echo ""
    echo "=== Running Static Analysis ==="
    echo ""

    case "$BUILD_TOOL" in
        maven)
            # Checkstyle
            if [ "$CHECKSTYLE_ENABLED" = "true" ]; then
                if grep -q "maven-checkstyle-plugin" pom.xml 2>/dev/null; then
                    info "Running Checkstyle..."
                    mvn checkstyle:check 2>/dev/null || warning "Checkstyle found issues"
                fi
            fi

            # SpotBugs
            if [ "$SPOTBUGS_ENABLED" = "true" ]; then
                if grep -q "spotbugs-maven-plugin" pom.xml 2>/dev/null; then
                    info "Running SpotBugs..."
                    mvn spotbugs:check 2>/dev/null || warning "SpotBugs found issues"
                fi
            fi

            # PMD
            if [ "$PMD_ENABLED" = "true" ]; then
                if grep -q "maven-pmd-plugin" pom.xml 2>/dev/null; then
                    info "Running PMD..."
                    mvn pmd:check 2>/dev/null || warning "PMD found issues"
                fi
            fi
            ;;
        gradle)
            # Checkstyle
            if [ "$CHECKSTYLE_ENABLED" = "true" ]; then
                if grep -q "checkstyle" build.gradle* 2>/dev/null; then
                    info "Running Checkstyle..."
                    ./gradlew checkstyleMain checkstyleTest 2>/dev/null || warning "Checkstyle found issues"
                fi
            fi

            # SpotBugs
            if [ "$SPOTBUGS_ENABLED" = "true" ]; then
                if grep -q "spotbugs" build.gradle* 2>/dev/null; then
                    info "Running SpotBugs..."
                    ./gradlew spotbugsMain spotbugsTest 2>/dev/null || warning "SpotBugs found issues"
                fi
            fi
            ;;
    esac
}

# ==============================================================================
# Run SonarQube Analysis
# ==============================================================================
run_sonarqube_analysis() {
    if [ "$SONAR_ENABLED" = "false" ]; then
        info "SonarQube analysis disabled"
        return 0
    fi

    echo ""
    echo "=== Running SonarQube Analysis ==="
    echo ""

    if [ -z "$SONAR_TOKEN" ]; then
        error "SONAR_TOKEN is required when SONAR_ENABLED=true"
        exit 1
    fi

    if [ -z "$SONAR_PROJECT_KEY" ]; then
        warning "SONAR_PROJECT_KEY not set, using directory name"
        SONAR_PROJECT_KEY=$(basename "$(pwd)")
    fi

    case "$BUILD_TOOL" in
        maven)
            info "Running SonarQube Maven analysis..."
            mvn sonar:sonar \
                -Dsonar.host.url="$SONAR_HOST_URL" \
                -Dsonar.login="$SONAR_TOKEN" \
                -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
                ${SONAR_ORGANIZATION:+-Dsonar.organization="$SONAR_ORGANIZATION"} \
                -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
            ;;
        gradle)
            info "Running SonarQube Gradle analysis..."
            ./gradlew sonarqube \
                -Dsonar.host.url="$SONAR_HOST_URL" \
                -Dsonar.login="$SONAR_TOKEN" \
                -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
                ${SONAR_ORGANIZATION:+-Dsonar.organization="$SONAR_ORGANIZATION"}
            ;;
        *)
            info "Running SonarScanner CLI..."
            sonar-scanner \
                -Dsonar.host.url="$SONAR_HOST_URL" \
                -Dsonar.login="$SONAR_TOKEN" \
                -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
                ${SONAR_ORGANIZATION:+-Dsonar.organization="$SONAR_ORGANIZATION"} \
                -Dsonar.sources=. \
                -Dsonar.exclusions=**/node_modules/**,**/venv/**,**/.venv/**,**/target/**,**/build/**
            ;;
    esac

    success "SonarQube analysis completed"
    info "View results at: $SONAR_HOST_URL/dashboard?id=$SONAR_PROJECT_KEY"
}

# ==============================================================================
# Generate Quality Report Summary
# ==============================================================================
generate_quality_summary() {
    echo ""
    echo "=== Quality Analysis Summary ==="
    echo ""

    info "Reports generated:"

    case "$BUILD_TOOL" in
        maven)
            [ -f "target/site/jacoco/index.html" ] && echo "  ✓ Coverage: target/site/jacoco/index.html"
            [ -f "target/checkstyle-result.xml" ] && echo "  ✓ Checkstyle: target/checkstyle-result.xml"
            [ -f "target/spotbugsXml.xml" ] && echo "  ✓ SpotBugs: target/spotbugsXml.xml"
            [ -f "target/pmd.xml" ] && echo "  ✓ PMD: target/pmd.xml"
            ;;
        gradle)
            [ -f "build/reports/jacoco/test/html/index.html" ] && echo "  ✓ Coverage: build/reports/jacoco/test/html/index.html"
            [ -d "build/reports/checkstyle" ] && echo "  ✓ Checkstyle: build/reports/checkstyle/"
            [ -d "build/reports/spotbugs" ] && echo "  ✓ SpotBugs: build/reports/spotbugs/"
            ;;
        python)
            [ -f "htmlcov/index.html" ] && echo "  ✓ Coverage: htmlcov/index.html"
            [ -f ".pylint.d" ] && echo "  ✓ Pylint: .pylint.d/"
            ;;
        go)
            [ -f "coverage.html" ] && echo "  ✓ Coverage: coverage.html"
            ;;
    esac

    if [ "$SONAR_ENABLED" = "true" ]; then
        echo "  ✓ SonarQube: $SONAR_HOST_URL/dashboard?id=$SONAR_PROJECT_KEY"
    fi

    echo ""
}

# ==============================================================================
# Custom Quality Command
# ==============================================================================
run_custom_quality_command() {
    if [ -n "$QUALITY_COMMAND" ]; then
        echo ""
        echo "=== Running Custom Quality Command ==="
        echo ""
        info "Command: $QUALITY_COMMAND"
        eval "$QUALITY_COMMAND"
        success "Custom quality command completed"
    fi
}

# ==============================================================================
# Main Execution
# ==============================================================================
main() {
    # Run custom command if specified
    if [ -n "$QUALITY_COMMAND" ]; then
        run_custom_quality_command
    else
        # Run standard quality checks
        run_tests_with_coverage
        check_coverage_threshold
        run_linting
        run_static_analysis
        run_sonarqube_analysis
    fi

    # Generate summary
    generate_quality_summary

    echo ""
    echo "==============================================================================="
    echo -e "${GREEN}✓ QUALITY ANALYSIS COMPLETE${NC}"
    echo "==============================================================================="
}

# Run main function
main
