#!/bin/bash
# ==============================================================================
# Dockerfile Security Scanning Script
# ==============================================================================
# This script scans Dockerfiles for security best practices and vulnerabilities
# Part of Phase 2: Enhancement (HIGH PRIORITY)
# Tools: Hadolint, Checkov
# Implements: CIS Docker Benchmarks
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables
# ==============================================================================
DOCKERFILE_PATH="${DOCKERFILE_PATH:-./Dockerfile}"
FAIL_ON_ERROR="${FAIL_ON_ERROR:-false}"  # Start with warnings, enforce later
HADOLINT_VERSION="${HADOLINT_VERSION:-2.12.0}"
SEVERITY_THRESHOLD="${SEVERITY_THRESHOLD:-warning}"  # error, warning, info, style

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "==============================================================================="
echo "🐳 DOCKERFILE SECURITY SCANNING"
echo "==============================================================================="
echo "File: ${DOCKERFILE_PATH}"
echo "Severity Threshold: ${SEVERITY_THRESHOLD}"
echo "Fail on Error: ${FAIL_ON_ERROR}"
echo ""

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo -e "${RED}✗ Dockerfile not found at: $DOCKERFILE_PATH${NC}"
    exit 1
fi

# Create security reports directory
mkdir -p security-reports

# ==============================================================================
# Install Hadolint (if not already installed)
# ==============================================================================
if ! command -v hadolint &> /dev/null; then
    echo "=== Installing Hadolint ==="
    echo "Version: $HADOLINT_VERSION"

    # Download Hadolint binary
    wget -q -O /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64
    chmod +x /tmp/hadolint
    sudo mv /tmp/hadolint /usr/local/bin/ 2>/dev/null || mv /tmp/hadolint /tmp/hadolint-bin
    export PATH="/tmp:$PATH"

    hadolint --version 2>/dev/null || /tmp/hadolint-bin --version
    echo ""
fi

# ==============================================================================
# Run Hadolint Scan
# ==============================================================================
echo "=== Scanning Dockerfile with Hadolint ==="
echo "Checking against Docker best practices and CIS Benchmarks..."
echo ""

# Run Hadolint with multiple output formats
set +e  # Temporarily disable exit on error

# JSON format for parsing
hadolint --format json "$DOCKERFILE_PATH" > security-reports/hadolint-report.json 2>/dev/null
HADOLINT_EXIT_CODE=$?

# Human-readable format
hadolint --format tty "$DOCKERFILE_PATH" > security-reports/hadolint-report.txt 2>&1
set -e

# ==============================================================================
# Parse Results
# ==============================================================================
echo ""
echo "=== Scan Results ==="

if [ $HADOLINT_EXIT_CODE -eq 0 ] && [ ! -s security-reports/hadolint-report.json ]; then
    echo -e "${GREEN}✓ No issues found!${NC}"
    echo ""
    echo "Your Dockerfile follows security best practices."
    ISSUE_COUNT=0
else
    if [ -s security-reports/hadolint-report.json" ] && command -v jq &> /dev/null; then
        # Parse JSON report
        ERROR_COUNT=$(jq '[.[] | select(.level=="error")] | length' security-reports/hadolint-report.json 2>/dev/null || echo "0")
        WARNING_COUNT=$(jq '[.[] | select(.level=="warning")] | length' security-reports/hadolint-report.json 2>/dev/null || echo "0")
        INFO_COUNT=$(jq '[.[] | select(.level=="info")] | length' security-reports/hadolint-report.json 2>/dev/null || echo "0")
        STYLE_COUNT=$(jq '[.[] | select(.level=="style")] | length' security-reports/hadolint-report.json 2>/dev/null || echo "0")

        echo "=== Issue Summary ==="
        echo -e "${RED}Errors:   ${ERROR_COUNT}${NC}"
        echo -e "${YELLOW}Warnings: ${WARNING_COUNT}${NC}"
        echo -e "${CYAN}Info:     ${INFO_COUNT}${NC}"
        echo -e "Style:    ${STYLE_COUNT}"
        echo ""

        ISSUE_COUNT=$((ERROR_COUNT + WARNING_COUNT))

        # Display detailed issues
        if [ "$ERROR_COUNT" -gt 0 ]; then
            echo -e "${RED}=== Errors ===${NC}"
            jq -r '.[] | select(.level=="error") | "[\(.code)] Line \(.line): \(.message)"' security-reports/hadolint-report.json 2>/dev/null
            echo ""
        fi

        if [ "$WARNING_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}=== Warnings ===${NC}"
            jq -r '.[] | select(.level=="warning") | "[\(.code)] Line \(.line): \(.message)"' security-reports/hadolint-report.json 2>/dev/null | head -10
            [ "$WARNING_COUNT" -gt 10 ] && echo "... and $((WARNING_COUNT - 10)) more warnings"
            echo ""
        fi
    else
        # Fallback to text report
        echo "=== Issues Found ==="
        cat security-reports/hadolint-report.txt
        ISSUE_COUNT=$(wc -l < security-reports/hadolint-report.txt)
        echo ""
    fi
fi

# ==============================================================================
# Security Best Practices Check
# ==============================================================================
echo "=== Security Best Practices Validation ==="
echo ""

BEST_PRACTICES_PASS=0
BEST_PRACTICES_FAIL=0

# Check 1: Non-root user
if grep -q "^USER [^r]" "$DOCKERFILE_PATH"; then
    echo -e "${GREEN}✓ Non-root user configured${NC}"
    ((BEST_PRACTICES_PASS++))
else
    echo -e "${RED}✗ No non-root user configured (Security Risk)${NC}"
    echo "   Recommendation: Add 'USER <non-root-user>' before ENTRYPOINT"
    ((BEST_PRACTICES_FAIL++))
fi

# Check 2: Healthcheck
if grep -q "^HEALTHCHECK" "$DOCKERFILE_PATH"; then
    echo -e "${GREEN}✓ Healthcheck configured${NC}"
    ((BEST_PRACTICES_PASS++))
else
    echo -e "${YELLOW}⚠ No healthcheck configured${NC}"
    echo "   Recommendation: Add HEALTHCHECK instruction for container orchestration"
    ((BEST_PRACTICES_FAIL++))
fi

# Check 3: Using specific base image tags (not :latest)
if grep "^FROM.*:latest" "$DOCKERFILE_PATH" > /dev/null; then
    echo -e "${YELLOW}⚠ Using :latest tag for base image${NC}"
    echo "   Recommendation: Use specific version tags for reproducibility"
    ((BEST_PRACTICES_FAIL++))
else
    echo -e "${GREEN}✓ Specific base image tag used${NC}"
    ((BEST_PRACTICES_PASS++))
fi

# Check 4: Minimal base image (Alpine, Distroless)
if grep -E "^FROM.*(alpine|distroless)" "$DOCKERFILE_PATH" > /dev/null; then
    echo -e "${GREEN}✓ Minimal base image used${NC}"
    ((BEST_PRACTICES_PASS++))
else
    echo -e "${CYAN}ℹ Consider using minimal base images (Alpine, Distroless)${NC}"
fi

# Check 5: COPY vs ADD
if grep "^ADD" "$DOCKERFILE_PATH" > /dev/null; then
    echo -e "${YELLOW}⚠ ADD instruction found${NC}"
    echo "   Recommendation: Use COPY instead of ADD unless you need tar extraction"
    ((BEST_PRACTICES_FAIL++))
else
    echo -e "${GREEN}✓ Using COPY (preferred over ADD)${NC}"
    ((BEST_PRACTICES_PASS++))
fi

# Check 6: .dockerignore exists
if [ -f ".dockerignore" ]; then
    echo -e "${GREEN}✓ .dockerignore file exists${NC}"
    ((BEST_PRACTICES_PASS++))
else
    echo -e "${YELLOW}⚠ No .dockerignore file found${NC}"
    echo "   Recommendation: Create .dockerignore to exclude unnecessary files"
    ((BEST_PRACTICES_FAIL++))
fi

echo ""
echo "Best Practices Score: ${BEST_PRACTICES_PASS}/${BEST_PRACTICES_PASS + BEST_PRACTICES_FAIL}"
echo ""

# ==============================================================================
# CIS Docker Benchmark Checks
# ==============================================================================
echo "=== CIS Docker Benchmark Compliance ==="
echo ""

# CIS 4.1: Create a user for the container
if grep -q "^USER" "$DOCKERFILE_PATH"; then
    echo -e "${GREEN}✓ CIS 4.1: Container has a defined user${NC}"
else
    echo -e "${RED}✗ CIS 4.1: Container should run as non-root user${NC}"
fi

# CIS 4.6: Add HEALTHCHECK
if grep -q "^HEALTHCHECK" "$DOCKERFILE_PATH"; then
    echo -e "${GREEN}✓ CIS 4.6: HEALTHCHECK instruction added${NC}"
else
    echo -e "${YELLOW}⚠ CIS 4.6: Add HEALTHCHECK instruction${NC}"
fi

# CIS 4.7: Do not use latest tag
if ! grep "^FROM.*:latest" "$DOCKERFILE_PATH" > /dev/null; then
    echo -e "${GREEN}✓ CIS 4.7: Not using :latest tag${NC}"
else
    echo -e "${YELLOW}⚠ CIS 4.7: Avoid using :latest tag${NC}"
fi

echo ""

# ==============================================================================
# Generate Recommendations
# ==============================================================================
if [ "$ISSUE_COUNT" -gt 0 ] || [ "$BEST_PRACTICES_FAIL" -gt 0 ]; then
    echo "=== Remediation Recommendations ==="
    echo ""
    echo "1. Review all errors and warnings in: security-reports/hadolint-report.txt"
    echo "2. Fix security issues (non-root user, healthcheck, etc.)"
    echo "3. Use specific version tags for base images"
    echo "4. Minimize layers by combining RUN commands"
    echo "5. Remove unnecessary packages and files"
    echo "6. Scan base images for vulnerabilities"
    echo "7. Consider using multi-stage builds"
    echo "8. Review CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker"
    echo ""
fi

# ==============================================================================
# Generate Summary Report
# ==============================================================================
cat > security-reports/dockerfile-security-summary.txt << EOF
Dockerfile Security Scan Summary
=================================
Scan Date: $(date)
Dockerfile: ${DOCKERFILE_PATH}
Tool: Hadolint v${HADOLINT_VERSION}

Hadolint Issues:
- Errors: ${ERROR_COUNT:-0}
- Warnings: ${WARNING_COUNT:-0}
- Info: ${INFO_COUNT:-0}

Security Best Practices:
- Passed: ${BEST_PRACTICES_PASS}
- Failed: ${BEST_PRACTICES_FAIL}

CIS Compliance: See full report above

Detailed Reports:
- JSON: security-reports/hadolint-report.json
- Text: security-reports/hadolint-report.txt
EOF

# ==============================================================================
# Determine Exit Code
# ==============================================================================
echo "==============================================================================="

if [ "$ISSUE_COUNT" -eq 0 ] && [ "$BEST_PRACTICES_FAIL" -eq 0 ]; then
    echo -e "${GREEN}🐳 DOCKERFILE SECURITY SCAN - PASSED${NC}"
    echo "==============================================================================="
    exit 0
elif [ "$FAIL_ON_ERROR" = "true" ]; then
    echo -e "${RED}🐳 DOCKERFILE SECURITY SCAN - FAILED${NC}"
    echo "==============================================================================="
    exit 1
else
    echo -e "${YELLOW}🐳 DOCKERFILE SECURITY SCAN - WARNINGS (Not blocking)${NC}"
    echo "==============================================================================="
    echo "Set FAIL_ON_ERROR=true to enforce Dockerfile security standards"
    exit 0
fi
