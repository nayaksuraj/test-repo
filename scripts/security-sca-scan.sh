#!/bin/bash
# ==============================================================================
# Software Composition Analysis (SCA) - Dependency Security Scanning
# ==============================================================================
# This script scans dependencies for known vulnerabilities
# Part of Phase 1: Foundation (CRITICAL)
# Tools: OWASP Dependency-Check (Primary), Snyk (Optional)
# Implements: OWASP A06:2021 - Vulnerable and Outdated Components
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables
# ==============================================================================
DEPENDENCY_CHECK_VERSION="${DEPENDENCY_CHECK_VERSION:-9.0.0}"
CVSS_THRESHOLD="${CVSS_THRESHOLD:-7.0}"  # Fail on CVSS >= 7.0 (HIGH)
FAIL_ON_CVSS="${FAIL_ON_CVSS:-true}"  # Block pipeline on high severity
SUPPRESSION_FILE="${SUPPRESSION_FILE:-}"  # Optional: suppress false positives
NVD_API_KEY="${NVD_API_KEY:-}"  # Optional: NVD API key for faster updates

# Maven/Gradle detection
BUILD_TOOL="maven"
if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    BUILD_TOOL="gradle"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "==============================================================================="
echo "🔒 SOFTWARE COMPOSITION ANALYSIS (SCA) - DEPENDENCY SECURITY"
echo "==============================================================================="
echo "Tool: OWASP Dependency-Check v${DEPENDENCY_CHECK_VERSION}"
echo "Build Tool: ${BUILD_TOOL}"
echo "CVSS Threshold: ${CVSS_THRESHOLD}"
echo "Fail on High Severity: ${FAIL_ON_CVSS}"
echo ""

# ==============================================================================
# Install OWASP Dependency-Check (if not using Maven plugin)
# ==============================================================================
install_dependency_check() {
    if ! command -v dependency-check &> /dev/null; then
        echo "=== Installing OWASP Dependency-Check ==="
        echo "Version: $DEPENDENCY_CHECK_VERSION"

        # Download and install
        wget -q https://github.com/jeremylong/DependencyCheck/releases/download/v${DEPENDENCY_CHECK_VERSION}/dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip
        unzip -q dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip
        chmod +x dependency-check/bin/dependency-check.sh
        sudo mv dependency-check /usr/local/ 2>/dev/null || mv dependency-check /tmp/
        rm dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip

        # Add to PATH
        export PATH="/usr/local/dependency-check/bin:/tmp/dependency-check/bin:$PATH"

        dependency-check.sh --version
        echo ""
    fi
}

# Create security reports directory
mkdir -p security-reports

# ==============================================================================
# Run OWASP Dependency-Check
# ==============================================================================
echo "=== Scanning Dependencies for Known Vulnerabilities ==="
echo "This may take several minutes on first run (downloads NVD database)..."
echo ""

if [[ "$BUILD_TOOL" == "maven" ]]; then
    # ===========================================================================
    # Maven: Use dependency-check-maven plugin
    # ===========================================================================

    # Check if plugin is configured in pom.xml
    if ! grep -q "dependency-check-maven" pom.xml 2>/dev/null; then
        echo "⚠️  Warning: dependency-check-maven plugin not found in pom.xml"
        echo "   Falling back to standalone Dependency-Check CLI"
        install_dependency_check

        # Run CLI version
        dependency-check.sh \
            --project "$(basename $(pwd))" \
            --scan . \
            --format "HTML" \
            --format "JSON" \
            --format "JUNIT" \
            --out security-reports \
            --failOnCVSS ${CVSS_THRESHOLD} \
            ${SUPPRESSION_FILE:+--suppression $SUPPRESSION_FILE} \
            ${NVD_API_KEY:+--nvdApiKey $NVD_API_KEY}
    else
        # Run Maven plugin
        mvn dependency-check:check \
            -DfailBuildOnCVSS=${CVSS_THRESHOLD} \
            -DskipTests=true \
            ${SUPPRESSION_FILE:+-DsuppressionFile=$SUPPRESSION_FILE} \
            ${NVD_API_KEY:+-DnvdApiKey=$NVD_API_KEY} \
            || handle_scan_failure
    fi

elif [[ "$BUILD_TOOL" == "gradle" ]]; then
    # ===========================================================================
    # Gradle: Use dependency-check-gradle plugin
    # ===========================================================================

    if ! grep -q "org.owasp.dependencycheck" build.gradle* 2>/dev/null; then
        echo "⚠️  Warning: dependency-check plugin not found in build.gradle"
        echo "   Falling back to standalone Dependency-Check CLI"
        install_dependency_check

        # Run CLI version
        dependency-check.sh \
            --project "$(basename $(pwd))" \
            --scan . \
            --format "HTML" \
            --format "JSON" \
            --out security-reports \
            --failOnCVSS ${CVSS_THRESHOLD} \
            ${SUPPRESSION_FILE:+--suppression $SUPPRESSION_FILE} \
            ${NVD_API_KEY:+--nvdApiKey $NVD_API_KEY}
    else
        # Run Gradle plugin
        ./gradlew dependencyCheckAnalyze \
            -DfailBuildOnCVSS=${CVSS_THRESHOLD} \
            ${SUPPRESSION_FILE:+-DsuppressionFile=$SUPPRESSION_FILE} \
            ${NVD_API_KEY:+-DnvdApiKey=$NVD_API_KEY} \
            || handle_scan_failure
    fi
fi

# ==============================================================================
# Handle Scan Failure
# ==============================================================================
handle_scan_failure() {
    local EXIT_CODE=$?

    echo ""
    echo -e "${RED}===============================================================================${NC}"
    echo -e "${RED}✗ VULNERABLE DEPENDENCIES DETECTED${NC}"
    echo -e "${RED}===============================================================================${NC}"
    echo ""

    # Parse and display results
    parse_scan_results

    echo ""
    echo "=== Remediation Steps ==="
    echo "1. Review the detailed report: security-reports/dependency-check-report.html"
    echo "2. Update vulnerable dependencies to patched versions"
    echo "3. If no patch is available:"
    echo "   - Consider alternative libraries"
    echo "   - Implement compensating controls"
    echo "   - Add suppression with security team approval"
    echo "4. Run 'mvn versions:display-dependency-updates' to see available updates"
    echo ""

    if [ "$FAIL_ON_CVSS" = "true" ]; then
        echo -e "${RED}🔒 SCA SCAN FAILED - BLOCKING PIPELINE${NC}"
        exit 1
    else
        echo -e "${YELLOW}🔒 SCA SCAN COMPLETE - WARNING ONLY${NC}"
        exit 0
    fi
}

# ==============================================================================
# Parse Scan Results
# ==============================================================================
parse_scan_results() {
    local REPORT_JSON=""

    # Find the JSON report
    if [ -f "security-reports/dependency-check-report.json" ]; then
        REPORT_JSON="security-reports/dependency-check-report.json"
    elif [ -f "target/dependency-check-report.json" ]; then
        REPORT_JSON="target/dependency-check-report.json"
        cp "$REPORT_JSON" security-reports/
    elif [ -f "build/reports/dependency-check-report.json" ]; then
        REPORT_JSON="build/reports/dependency-check-report.json"
        cp "$REPORT_JSON" security-reports/
    fi

    if [ -n "$REPORT_JSON" ] && command -v jq &> /dev/null; then
        echo "=== Vulnerability Summary ==="

        # Count vulnerabilities by severity
        CRITICAL=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity=="CRITICAL")] | length' "$REPORT_JSON" 2>/dev/null || echo "0")
        HIGH=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity=="HIGH")] | length' "$REPORT_JSON" 2>/dev/null || echo "0")
        MEDIUM=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity=="MEDIUM")] | length' "$REPORT_JSON" 2>/dev/null || echo "0")
        LOW=$(jq '[.dependencies[].vulnerabilities[]? | select(.severity=="LOW")] | length' "$REPORT_JSON" 2>/dev/null || echo "0")

        echo -e "${RED}Critical: ${CRITICAL}${NC}"
        echo -e "${RED}High:     ${HIGH}${NC}"
        echo -e "${YELLOW}Medium:   ${MEDIUM}${NC}"
        echo -e "${CYAN}Low:      ${LOW}${NC}"
        echo ""

        # Show top vulnerabilities
        if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            echo "=== Top Vulnerabilities (CRITICAL + HIGH) ==="
            jq -r '.dependencies[] | select(.vulnerabilities != null) | .vulnerabilities[] | select(.severity=="CRITICAL" or .severity=="HIGH") | "[\(.severity)] \(.name) - CVSS: \(.cvssv3?.baseScore // .cvssv2?.score // "N/A") - \(.description[0:100])..."' "$REPORT_JSON" 2>/dev/null | head -10
            echo ""
        fi
    fi

    echo "=== Reports Generated ==="
    [ -f "security-reports/dependency-check-report.html" ] && echo "HTML Report: security-reports/dependency-check-report.html"
    [ -f "security-reports/dependency-check-report.json" ] && echo "JSON Report: security-reports/dependency-check-report.json"
    echo ""
}

# ==============================================================================
# Success Handler
# ==============================================================================
echo ""
echo -e "${GREEN}===============================================================================${NC}"
echo -e "${GREEN}✓ NO CRITICAL VULNERABILITIES DETECTED${NC}"
echo -e "${GREEN}===============================================================================${NC}"
echo ""

parse_scan_results

echo "=== Next Steps ==="
echo "1. Review the detailed report for lower severity issues"
echo "2. Keep dependencies updated regularly"
echo "3. Subscribe to security advisories for your dependencies"
echo "4. Consider using Dependabot or Renovate for automated updates"
echo ""
echo "🔒 SCA SCAN COMPLETE - PASSED"
