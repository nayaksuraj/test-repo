#!/bin/bash
# ==============================================================================
# BITBUCKET PIPE: SECURITY-PIPE
# ==============================================================================
# Comprehensive security scanning pipe for shift-left security
# Includes: Secrets, SCA, SAST, SBOM, IaC, Dockerfile, Container scanning
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
SECRETS_SCAN="${SECRETS_SCAN:-true}"
SCA_SCAN="${SCA_SCAN:-true}"
SAST_SCAN="${SAST_SCAN:-false}"
SBOM_GENERATE="${SBOM_GENERATE:-true}"
IAC_SCAN="${IAC_SCAN:-false}"
DOCKERFILE_SCAN="${DOCKERFILE_SCAN:-false}"
CONTAINER_SCAN="${CONTAINER_SCAN:-false}"
CONTAINER_IMAGE="${CONTAINER_IMAGE:-}"
FAIL_ON_HIGH="${FAIL_ON_HIGH:-false}"
FAIL_ON_CRITICAL="${FAIL_ON_CRITICAL:-true}"
CVSS_THRESHOLD="${CVSS_THRESHOLD:-7.0}"
HELM_CHART_PATH="${HELM_CHART_PATH:-./helm-chart}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-./Dockerfile}"
WORKING_DIR="${WORKING_DIR:-.}"
REPORTS_DIR="${REPORTS_DIR:-security-reports}"
DEBUG="${DEBUG:-false}"

# Global variables for tracking results
SCAN_FAILURES=0
CRITICAL_ISSUES=0
HIGH_ISSUES=0
MEDIUM_ISSUES=0
LOW_ISSUES=0

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
echo -e "${GREEN}🔒 SECURITY PIPE - COMPREHENSIVE SECURITY SCANNING${NC}"
echo "==============================================================================="
echo "Working Directory: ${WORKING_DIR}"
echo "Reports Directory: ${REPORTS_DIR}"
echo ""
echo "Enabled Scans:"
echo "  - Secrets Scanning: ${SECRETS_SCAN}"
echo "  - SCA (Dependencies): ${SCA_SCAN}"
echo "  - SAST: ${SAST_SCAN}"
echo "  - SBOM Generation: ${SBOM_GENERATE}"
echo "  - IaC Scanning: ${IAC_SCAN}"
echo "  - Dockerfile Scanning: ${DOCKERFILE_SCAN}"
echo "  - Container Scanning: ${CONTAINER_SCAN}"
echo ""

# Change to working directory
cd "$WORKING_DIR" || {
    error "Failed to change to working directory: $WORKING_DIR"
    exit 1
}

# Create reports directory
mkdir -p "$REPORTS_DIR"

# ==============================================================================
# Auto-detect Build Tool
# ==============================================================================
detect_build_tool() {
    if [ -f "pom.xml" ]; then
        echo "maven"
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "gradle"
    elif [ -f "package.json" ]; then
        echo "npm"
    elif [ -f "go.mod" ]; then
        echo "go"
    elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        echo "python"
    else
        echo "unknown"
    fi
}

BUILD_TOOL=$(detect_build_tool)
debug "Detected build tool: $BUILD_TOOL"

# ==============================================================================
# Install GitLeaks (if not available)
# ==============================================================================
install_gitleaks() {
    if ! command -v gitleaks &> /dev/null; then
        info "Installing GitLeaks..."
        GITLEAKS_VERSION="8.18.0"
        wget -q https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz
        tar -xzf gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz
        chmod +x gitleaks
        mv gitleaks /usr/local/bin/ 2>/dev/null || export PATH="$(pwd):$PATH"
        rm gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz
    fi
}

# ==============================================================================
# Secrets Scanning
# ==============================================================================
run_secrets_scan() {
    if [ "$SECRETS_SCAN" != "true" ]; then
        info "Secrets scanning disabled"
        return 0
    fi

    echo ""
    echo "==============================================================================="
    echo -e "${CYAN}🔑 SECRETS SCANNING${NC}"
    echo "==============================================================================="

    install_gitleaks

    # Run GitLeaks
    set +e
    gitleaks detect \
        --source="." \
        --report-path="${REPORTS_DIR}/gitleaks-report.json" \
        --report-format=json \
        --verbose \
        --no-git 2>&1 | tee "${REPORTS_DIR}/gitleaks.log"

    GITLEAKS_EXIT_CODE=$?
    set -e

    if [ $GITLEAKS_EXIT_CODE -eq 0 ]; then
        success "No secrets detected"
    else
        error "SECRETS DETECTED!"
        ((SCAN_FAILURES++))
        ((CRITICAL_ISSUES++))

        if command -v jq &> /dev/null && [ -f "${REPORTS_DIR}/gitleaks-report.json" ]; then
            SECRET_COUNT=$(jq '. | length' "${REPORTS_DIR}/gitleaks-report.json" 2>/dev/null || echo "Unknown")
            error "Total secrets found: ${SECRET_COUNT}"
        fi

        cat >> "${REPORTS_DIR}/security-summary.txt" << EOF

SECRETS SCANNING: FAILED
- Secrets found in codebase
- Report: ${REPORTS_DIR}/gitleaks-report.json
- Action: Remove secrets immediately and rotate credentials

EOF
    fi

    info "Secrets scan report: ${REPORTS_DIR}/gitleaks-report.json"
}

# ==============================================================================
# Software Composition Analysis (SCA) - Dependency Scanning
# ==============================================================================
run_sca_scan() {
    if [ "$SCA_SCAN" != "true" ]; then
        info "SCA scanning disabled"
        return 0
    fi

    echo ""
    echo "==============================================================================="
    echo -e "${CYAN}📦 SOFTWARE COMPOSITION ANALYSIS (SCA)${NC}"
    echo "==============================================================================="

    case "$BUILD_TOOL" in
        maven|gradle)
            run_sca_java
            ;;
        npm)
            run_sca_npm
            ;;
        python)
            run_sca_python
            ;;
        go)
            run_sca_go
            ;;
        *)
            warning "SCA not available for build tool: $BUILD_TOOL"
            ;;
    esac
}

run_sca_java() {
    info "Running OWASP Dependency-Check..."

    # Use Grype as alternative for faster scanning
    if command -v grype &> /dev/null; then
        set +e
        grype dir:. \
            -o json \
            --file="${REPORTS_DIR}/sca-grype.json" \
            --fail-on=high 2>&1 | tee "${REPORTS_DIR}/sca-grype.log"

        GRYPE_EXIT_CODE=$?
        set -e

        if [ $GRYPE_EXIT_CODE -ne 0 ]; then
            error "Vulnerable dependencies detected"
            ((SCAN_FAILURES++))
            parse_grype_results
        else
            success "No critical vulnerabilities in dependencies"
        fi
    fi
}

run_sca_npm() {
    info "Running NPM audit..."

    set +e
    npm audit --json > "${REPORTS_DIR}/npm-audit.json" 2>&1
    NPM_AUDIT_EXIT=$?
    set -e

    if [ $NPM_AUDIT_EXIT -ne 0 ]; then
        warning "Vulnerabilities found in NPM dependencies"
        if command -v jq &> /dev/null; then
            CRITICAL=$(jq '.metadata.vulnerabilities.critical // 0' "${REPORTS_DIR}/npm-audit.json")
            HIGH=$(jq '.metadata.vulnerabilities.high // 0' "${REPORTS_DIR}/npm-audit.json")
            info "Critical: $CRITICAL, High: $HIGH"

            if [ "$CRITICAL" -gt 0 ]; then
                ((CRITICAL_ISSUES+=CRITICAL))
                ((SCAN_FAILURES++))
            fi
            if [ "$HIGH" -gt 0 ]; then
                ((HIGH_ISSUES+=HIGH))
            fi
        fi
    else
        success "No vulnerabilities in NPM dependencies"
    fi
}

run_sca_python() {
    info "Running Python dependency check..."

    # Use Grype for Python dependencies
    if command -v grype &> /dev/null; then
        set +e
        grype dir:. \
            -o json \
            --file="${REPORTS_DIR}/sca-python.json"
        set -e
    fi

    # Also try safety if available
    if pip3 list | grep -q safety; then
        pip3 freeze | safety check --json > "${REPORTS_DIR}/safety-report.json" 2>/dev/null || true
    fi
}

run_sca_go() {
    info "Running Go vulnerability check..."

    if command -v grype &> /dev/null; then
        set +e
        grype dir:. \
            -o json \
            --file="${REPORTS_DIR}/sca-go.json"
        set -e
    fi
}

parse_grype_results() {
    if [ -f "${REPORTS_DIR}/sca-grype.json" ] && command -v jq &> /dev/null; then
        CRITICAL=$(jq '[.matches[] | select(.vulnerability.severity=="Critical")] | length' "${REPORTS_DIR}/sca-grype.json" 2>/dev/null || echo "0")
        HIGH=$(jq '[.matches[] | select(.vulnerability.severity=="High")] | length' "${REPORTS_DIR}/sca-grype.json" 2>/dev/null || echo "0")
        MEDIUM=$(jq '[.matches[] | select(.vulnerability.severity=="Medium")] | length' "${REPORTS_DIR}/sca-grype.json" 2>/dev/null || echo "0")

        ((CRITICAL_ISSUES+=CRITICAL))
        ((HIGH_ISSUES+=HIGH))
        ((MEDIUM_ISSUES+=MEDIUM))

        error "Critical: $CRITICAL, High: $HIGH, Medium: $MEDIUM"
    fi
}

# ==============================================================================
# SAST (Static Application Security Testing)
# ==============================================================================
run_sast_scan() {
    if [ "$SAST_SCAN" != "true" ]; then
        info "SAST scanning disabled"
        return 0
    fi

    echo ""
    echo "==============================================================================="
    echo -e "${CYAN}🔍 STATIC APPLICATION SECURITY TESTING (SAST)${NC}"
    echo "==============================================================================="

    case "$BUILD_TOOL" in
        python)
            run_sast_python
            ;;
        *)
            info "Using Trivy for SAST..."
            if command -v trivy &> /dev/null; then
                trivy fs --security-checks vuln,config,secret . \
                    -f json \
                    -o "${REPORTS_DIR}/trivy-sast.json" || true
            fi
            ;;
    esac
}

run_sast_python() {
    info "Running Bandit (Python SAST)..."

    if command -v bandit &> /dev/null; then
        set +e
        bandit -r . -f json -o "${REPORTS_DIR}/bandit-report.json" 2>&1 | tee "${REPORTS_DIR}/bandit.log"
        set -e
        success "Bandit scan completed"
    fi
}

# ==============================================================================
# SBOM Generation
# ==============================================================================
run_sbom_generation() {
    if [ "$SBOM_GENERATE" != "true" ]; then
        info "SBOM generation disabled"
        return 0
    fi

    echo ""
    echo "==============================================================================="
    echo -e "${CYAN}📋 SBOM GENERATION${NC}"
    echo "==============================================================================="

    mkdir -p "${REPORTS_DIR}/sbom"

    case "$BUILD_TOOL" in
        maven)
            generate_sbom_maven
            ;;
        gradle)
            generate_sbom_gradle
            ;;
        *)
            generate_sbom_syft
            ;;
    esac
}

generate_sbom_maven() {
    info "Generating SBOM for Maven project..."

    # Use CycloneDX Maven plugin
    if grep -q "cyclonedx-maven-plugin" pom.xml 2>/dev/null; then
        mvn cyclonedx:makeAggregateBom -DoutputFormat=all -DoutputName=bom
        [ -f "target/bom.json" ] && cp target/bom.json "${REPORTS_DIR}/sbom/sbom-cyclonedx.json"
        success "Maven SBOM generated"
    else
        warning "CycloneDX plugin not configured, using Syft"
        generate_sbom_syft
    fi
}

generate_sbom_gradle() {
    info "Generating SBOM for Gradle project..."

    [ -f "gradlew" ] && chmod +x gradlew

    if grep -q "org.cyclonedx.bom" build.gradle* 2>/dev/null; then
        ./gradlew cyclonedxBom
        [ -f "build/reports/bom.json" ] && cp build/reports/bom.json "${REPORTS_DIR}/sbom/sbom-cyclonedx.json"
        success "Gradle SBOM generated"
    else
        warning "CycloneDX plugin not configured, using Syft"
        generate_sbom_syft
    fi
}

generate_sbom_syft() {
    if ! command -v syft &> /dev/null; then
        warning "Syft not available, skipping SBOM generation"
        return
    fi

    info "Generating SBOM with Syft..."

    syft dir:. -o cyclonedx-json > "${REPORTS_DIR}/sbom/sbom-cyclonedx.json"
    syft dir:. -o spdx-json > "${REPORTS_DIR}/sbom/sbom-spdx.json"

    success "SBOM generated with Syft"

    if command -v jq &> /dev/null; then
        COMPONENT_COUNT=$(jq '.components | length' "${REPORTS_DIR}/sbom/sbom-cyclonedx.json" 2>/dev/null || echo "Unknown")
        info "Total components: ${COMPONENT_COUNT}"
    fi
}

# ==============================================================================
# IaC Scanning
# ==============================================================================
run_iac_scan() {
    if [ "$IAC_SCAN" != "true" ]; then
        info "IaC scanning disabled"
        return 0
    fi

    echo ""
    echo "==============================================================================="
    echo -e "${CYAN}☸️  INFRASTRUCTURE AS CODE (IAC) SCANNING${NC}"
    echo "==============================================================================="

    if [ ! -d "$HELM_CHART_PATH" ]; then
        warning "Helm chart not found at: $HELM_CHART_PATH"
        return 0
    fi

    mkdir -p "${REPORTS_DIR}/iac"

    # Scan with Checkov
    if command -v checkov &> /dev/null; then
        info "Scanning Helm charts with Checkov..."

        set +e
        checkov -d "$HELM_CHART_PATH" \
            --framework helm \
            --output cli \
            --output json \
            --output-file-path "${REPORTS_DIR}/iac" \
            --quiet 2>&1 | tee "${REPORTS_DIR}/iac/checkov.log"

        CHECKOV_EXIT=$?
        set -e

        if [ $CHECKOV_EXIT -ne 0 ]; then
            warning "IaC security issues detected"
            parse_checkov_results
        else
            success "No critical IaC issues found"
        fi
    fi

    # Scan with Trivy
    if command -v trivy &> /dev/null; then
        info "Scanning IaC with Trivy..."
        trivy config "$HELM_CHART_PATH" \
            -f json \
            -o "${REPORTS_DIR}/iac/trivy-iac.json" || true
    fi
}

parse_checkov_results() {
    if [ -f "${REPORTS_DIR}/iac/results_json.json" ] && command -v jq &> /dev/null; then
        FAILED=$(jq '.summary.failed // 0' "${REPORTS_DIR}/iac/results_json.json" 2>/dev/null || echo "0")
        CRITICAL=$(jq '[.results.failed_checks[]? | select(.severity=="CRITICAL")] | length' "${REPORTS_DIR}/iac/results_json.json" 2>/dev/null || echo "0")
        HIGH=$(jq '[.results.failed_checks[]? | select(.severity=="HIGH")] | length' "${REPORTS_DIR}/iac/results_json.json" 2>/dev/null || echo "0")

        info "Failed checks: $FAILED (Critical: $CRITICAL, High: $HIGH)"

        if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            ((CRITICAL_ISSUES+=CRITICAL))
            ((HIGH_ISSUES+=HIGH))
            ((SCAN_FAILURES++))
        fi
    fi
}

# ==============================================================================
# Dockerfile Scanning
# ==============================================================================
run_dockerfile_scan() {
    if [ "$DOCKERFILE_SCAN" != "true" ]; then
        info "Dockerfile scanning disabled"
        return 0
    fi

    echo ""
    echo "==============================================================================="
    echo -e "${CYAN}🐳 DOCKERFILE SECURITY SCANNING${NC}"
    echo "==============================================================================="

    if [ ! -f "$DOCKERFILE_PATH" ]; then
        warning "Dockerfile not found at: $DOCKERFILE_PATH"
        return 0
    fi

    # Scan with Hadolint
    if command -v hadolint &> /dev/null; then
        info "Scanning Dockerfile with Hadolint..."

        set +e
        hadolint --format json "$DOCKERFILE_PATH" > "${REPORTS_DIR}/hadolint-report.json" 2>/dev/null
        HADOLINT_EXIT=$?
        hadolint --format tty "$DOCKERFILE_PATH" 2>&1 | tee "${REPORTS_DIR}/hadolint-report.txt"
        set -e

        if [ $HADOLINT_EXIT -ne 0 ]; then
            warning "Dockerfile issues detected"
            if command -v jq &> /dev/null && [ -s "${REPORTS_DIR}/hadolint-report.json" ]; then
                ERROR_COUNT=$(jq '[.[] | select(.level=="error")] | length' "${REPORTS_DIR}/hadolint-report.json" 2>/dev/null || echo "0")
                [ "$ERROR_COUNT" -gt 0 ] && ((HIGH_ISSUES+=ERROR_COUNT))
            fi
        else
            success "Dockerfile follows security best practices"
        fi
    fi

    # Scan with Trivy
    if command -v trivy &> /dev/null; then
        info "Scanning Dockerfile with Trivy..."
        trivy config "$DOCKERFILE_PATH" \
            -f json \
            -o "${REPORTS_DIR}/trivy-dockerfile.json" || true
    fi
}

# ==============================================================================
# Container Image Scanning
# ==============================================================================
run_container_scan() {
    if [ "$CONTAINER_SCAN" != "true" ]; then
        info "Container scanning disabled"
        return 0
    fi

    if [ -z "$CONTAINER_IMAGE" ]; then
        warning "CONTAINER_IMAGE not specified, skipping container scan"
        return 0
    fi

    echo ""
    echo "==============================================================================="
    echo -e "${CYAN}📦 CONTAINER IMAGE SCANNING${NC}"
    echo "==============================================================================="

    info "Scanning container image: $CONTAINER_IMAGE"

    # Scan with Trivy
    if command -v trivy &> /dev/null; then
        info "Running Trivy container scan..."

        set +e
        trivy image "$CONTAINER_IMAGE" \
            --severity HIGH,CRITICAL \
            -f json \
            -o "${REPORTS_DIR}/trivy-container.json" 2>&1 | tee "${REPORTS_DIR}/trivy-container.log"

        TRIVY_EXIT=$?
        set -e

        if [ $TRIVY_EXIT -ne 0 ]; then
            error "Vulnerabilities found in container image"
            ((SCAN_FAILURES++))
            parse_trivy_results
        else
            success "No critical vulnerabilities in container image"
        fi
    fi

    # Scan with Grype
    if command -v grype &> /dev/null; then
        info "Running Grype container scan..."
        grype "$CONTAINER_IMAGE" \
            -o json \
            --file="${REPORTS_DIR}/grype-container.json" || true
    fi
}

parse_trivy_results() {
    if [ -f "${REPORTS_DIR}/trivy-container.json" ] && command -v jq &> /dev/null; then
        CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "${REPORTS_DIR}/trivy-container.json" 2>/dev/null || echo "0")
        HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "${REPORTS_DIR}/trivy-container.json" 2>/dev/null || echo "0")

        ((CRITICAL_ISSUES+=CRITICAL))
        ((HIGH_ISSUES+=HIGH))

        error "Critical: $CRITICAL, High: $HIGH"
    fi
}

# ==============================================================================
# Generate Security Summary Report
# ==============================================================================
generate_security_summary() {
    echo ""
    echo "==============================================================================="
    echo -e "${CYAN}📊 SECURITY SCAN SUMMARY${NC}"
    echo "==============================================================================="

    cat > "${REPORTS_DIR}/security-summary.txt" << EOF
SECURITY SCAN SUMMARY
=====================
Generated: $(date)

SCAN RESULTS:
-------------
Total Scans: $(echo "$SECRETS_SCAN $SCA_SCAN $SAST_SCAN $IAC_SCAN $DOCKERFILE_SCAN $CONTAINER_SCAN" | tr ' ' '\n' | grep -c "true")
Failed Scans: ${SCAN_FAILURES}

SEVERITY BREAKDOWN:
------------------
Critical Issues: ${CRITICAL_ISSUES}
High Issues: ${HIGH_ISSUES}
Medium Issues: ${MEDIUM_ISSUES}
Low Issues: ${LOW_ISSUES}

ENABLED SCANS:
-------------
✓ Secrets Scanning: ${SECRETS_SCAN}
✓ SCA (Dependencies): ${SCA_SCAN}
✓ SAST: ${SAST_SCAN}
✓ SBOM Generation: ${SBOM_GENERATE}
✓ IaC Scanning: ${IAC_SCAN}
✓ Dockerfile Scanning: ${DOCKERFILE_SCAN}
✓ Container Scanning: ${CONTAINER_SCAN}

REPORTS GENERATED:
-----------------
EOF

    # List all generated reports
    find "${REPORTS_DIR}" -type f -name "*.json" -o -name "*.txt" -o -name "*.log" | while read -r file; do
        echo "  - $file" >> "${REPORTS_DIR}/security-summary.txt"
    done

    cat >> "${REPORTS_DIR}/security-summary.txt" << EOF

RECOMMENDATIONS:
---------------
EOF

    if [ "$CRITICAL_ISSUES" -gt 0 ]; then
        cat >> "${REPORTS_DIR}/security-summary.txt" << EOF
⚠️  CRITICAL: ${CRITICAL_ISSUES} critical issues found - IMMEDIATE ACTION REQUIRED
EOF
    fi

    if [ "$HIGH_ISSUES" -gt 0 ]; then
        cat >> "${REPORTS_DIR}/security-summary.txt" << EOF
⚠️  HIGH: ${HIGH_ISSUES} high severity issues found - Address as soon as possible
EOF
    fi

    cat >> "${REPORTS_DIR}/security-summary.txt" << EOF

For detailed findings, review individual scan reports in: ${REPORTS_DIR}/
EOF

    # Display summary
    cat "${REPORTS_DIR}/security-summary.txt"
}

# ==============================================================================
# Determine Exit Code
# ==============================================================================
determine_exit_code() {
    echo ""
    echo "==============================================================================="

    if [ "$CRITICAL_ISSUES" -gt 0 ] && [ "$FAIL_ON_CRITICAL" = "true" ]; then
        error "SECURITY SCAN FAILED - Critical issues found"
        echo "==============================================================================="
        exit 1
    elif [ "$HIGH_ISSUES" -gt 0 ] && [ "$FAIL_ON_HIGH" = "true" ]; then
        error "SECURITY SCAN FAILED - High severity issues found"
        echo "==============================================================================="
        exit 1
    elif [ "$SCAN_FAILURES" -gt 0 ]; then
        warning "SECURITY SCAN COMPLETED WITH WARNINGS"
        echo "==============================================================================="
        warning "Set FAIL_ON_HIGH=true or FAIL_ON_CRITICAL=true to enforce security gates"
        exit 0
    else
        success "SECURITY SCAN PASSED - No critical issues found"
        echo "==============================================================================="
        exit 0
    fi
}

# ==============================================================================
# Main Execution
# ==============================================================================
main() {
    # Run all enabled scans
    run_secrets_scan
    run_sca_scan
    run_sast_scan
    run_sbom_generation
    run_iac_scan
    run_dockerfile_scan
    run_container_scan

    # Generate summary
    generate_security_summary

    # Determine exit code
    determine_exit_code
}

# Run main function
main
