#!/bin/bash
# ==============================================================================
# Secrets Scanning Script - SHIFT-LEFT SECURITY
# ==============================================================================
# This script scans for secrets, credentials, and sensitive data in code
# Part of Phase 1: Foundation (CRITICAL)
# Tools: GitLeaks
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables
# ==============================================================================
GITLEAKS_VERSION="${GITLEAKS_VERSION:-8.18.0}"
FAIL_ON_SECRETS="${FAIL_ON_SECRETS:-true}"  # Block pipeline if secrets found
SCAN_PATH="${SCAN_PATH:-.}"
REPORT_FORMAT="${REPORT_FORMAT:-json}"  # json, sarif, csv

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "==============================================================================="
echo "🔒 SECRETS SCANNING - SHIFT-LEFT SECURITY"
echo "==============================================================================="
echo "Tool: GitLeaks v${GITLEAKS_VERSION}"
echo "Scan Path: ${SCAN_PATH}"
echo "Fail on Detection: ${FAIL_ON_SECRETS}"
echo ""

# ==============================================================================
# Install GitLeaks (if not already installed)
# ==============================================================================
if ! command -v gitleaks &> /dev/null; then
    echo "=== Installing GitLeaks ==="
    echo "Version: $GITLEAKS_VERSION"

    # Download and install GitLeaks
    wget -q https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz
    tar -xzf gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz
    chmod +x gitleaks
    sudo mv gitleaks /usr/local/bin/ 2>/dev/null || mv gitleaks /tmp/
    rm gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz

    # Add to PATH if moved to /tmp
    export PATH="/tmp:$PATH"

    gitleaks version
    echo ""
fi

# Create security reports directory
mkdir -p security-reports

# ==============================================================================
# Run GitLeaks Scan
# ==============================================================================
echo "=== Scanning for Secrets and Credentials ==="
echo ""

# Run GitLeaks detect
set +e  # Temporarily disable exit on error to capture exit code
gitleaks detect \
    --source="${SCAN_PATH}" \
    --report-path=security-reports/gitleaks-report.json \
    --report-format=json \
    --verbose \
    --no-git

GITLEAKS_EXIT_CODE=$?
set -e

# Generate additional formats
if [ -f "security-reports/gitleaks-report.json" ]; then
    # Generate SARIF format for GitHub integration
    gitleaks detect \
        --source="${SCAN_PATH}" \
        --report-path=security-reports/gitleaks-report.sarif \
        --report-format=sarif \
        --no-git 2>/dev/null || echo "SARIF generation skipped"
fi

# ==============================================================================
# Parse Results
# ==============================================================================
echo ""
echo "=== Scan Results ==="

if [ $GITLEAKS_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ No secrets detected!${NC}"
    echo ""
    echo "=== Summary ==="
    echo "Status: PASS"
    echo "Secrets Found: 0"
    echo "Report: security-reports/gitleaks-report.json"
    echo ""
    echo "==============================================================================="
    echo "🔒 SECRETS SCANNING COMPLETE - PASSED"
    echo "==============================================================================="
    exit 0
else
    echo -e "${RED}✗ SECRETS DETECTED!${NC}"
    echo ""

    # Parse JSON report if jq is available
    if command -v jq &> /dev/null && [ -f "security-reports/gitleaks-report.json" ]; then
        SECRET_COUNT=$(jq '. | length' security-reports/gitleaks-report.json 2>/dev/null || echo "Unknown")

        echo "=== Detected Secrets Summary ==="
        echo "Total Secrets Found: ${SECRET_COUNT}"
        echo ""

        echo "=== Details ==="
        jq -r '.[] | "File: \(.File)\nLine: \(.StartLine)\nRule: \(.RuleID)\nSecret: \(.Secret[0:20])...\n"' \
            security-reports/gitleaks-report.json 2>/dev/null || \
            cat security-reports/gitleaks-report.json
    else
        echo "=== Details ==="
        [ -f "security-reports/gitleaks-report.json" ] && cat security-reports/gitleaks-report.json
    fi

    echo ""
    echo "=== Remediation Steps ==="
    echo "1. Remove secrets from the codebase"
    echo "2. Use environment variables or secret management tools (Vault, AWS Secrets Manager)"
    echo "3. Rotate compromised credentials immediately"
    echo "4. Add sensitive patterns to .gitignore"
    echo "5. Use git-filter-repo to remove secrets from git history (if already committed)"
    echo ""

    echo "=== Reports Generated ==="
    echo "JSON Report: security-reports/gitleaks-report.json"
    [ -f "security-reports/gitleaks-report.sarif" ] && echo "SARIF Report: security-reports/gitleaks-report.sarif"
    echo ""

    if [ "$FAIL_ON_SECRETS" = "true" ]; then
        echo "==============================================================================="
        echo -e "${RED}🔒 SECRETS SCANNING FAILED - BLOCKING PIPELINE${NC}"
        echo "==============================================================================="
        exit 1
    else
        echo "==============================================================================="
        echo -e "${YELLOW}🔒 SECRETS SCANNING COMPLETE - WARNING ONLY${NC}"
        echo "==============================================================================="
        exit 0
    fi
fi
