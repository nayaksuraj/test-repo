#!/bin/bash
# Bitbucket Pipe: Secrets Scanner
# Scans code for secrets and credentials using GitLeaks

set -e
source /common.sh

# ==============================================================================
# Configuration
# ==============================================================================
FAIL_ON_SECRETS="${FAIL_ON_SECRETS:-true}"
SCAN_PATH="${SCAN_PATH:-.}"
GITLEAKS_VERSION="${GITLEAKS_VERSION:-8.18.0}"
REPORT_FORMAT="${REPORT_FORMAT:-json}"
DEBUG="${DEBUG:-false}"

# ==============================================================================
# Main
# ==============================================================================
info "Secrets Scanner Pipe"
info "GitLeaks version: ${GITLEAKS_VERSION}"
info "Scan path: ${SCAN_PATH}"
info "Fail on secrets: ${FAIL_ON_SECRETS}"
echo ""

# Validate inputs
if [ ! -d "${SCAN_PATH}" ] && [ ! -f "${SCAN_PATH}" ]; then
    fail "Scan path does not exist: ${SCAN_PATH}"
fi

# Create reports directory
mkdir -p security-reports

# Run GitLeaks scan
info "Scanning for secrets..."

set +e
gitleaks detect \
    --source="${SCAN_PATH}" \
    --report-path=security-reports/gitleaks-report.json \
    --report-format=json \
    --verbose \
    --no-git

GITLEAKS_EXIT_CODE=$?
set -e

# Generate additional formats if requested
if [ "${REPORT_FORMAT}" != "json" ]; then
    gitleaks detect \
        --source="${SCAN_PATH}" \
        --report-path="security-reports/gitleaks-report.${REPORT_FORMAT}" \
        --report-format="${REPORT_FORMAT}" \
        --no-git 2>/dev/null || warning "Failed to generate ${REPORT_FORMAT} report"
fi

# Parse results
echo ""
if [ $GITLEAKS_EXIT_CODE -eq 0 ]; then
    success "No secrets detected!"
    export_metadata "SECRETS_FOUND" "0"
    export_metadata "SCAN_STATUS" "PASS"
    exit 0
else
    error "Secrets detected!"

    if [ -f "security-reports/gitleaks-report.json" ]; then
        SECRET_COUNT=$(jq '. | length' security-reports/gitleaks-report.json 2>/dev/null || echo "Unknown")

        error "Total secrets found: ${SECRET_COUNT}"
        export_metadata "SECRETS_FOUND" "${SECRET_COUNT}"
        export_metadata "SCAN_STATUS" "FAIL"

        echo ""
        warning "Secrets details:"
        jq -r '.[] | "  File: \(.File):\(.StartLine)\n  Rule: \(.RuleID)\n  Secret: \(.Secret[0:20])...\n"' \
            security-reports/gitleaks-report.json 2>/dev/null || cat security-reports/gitleaks-report.json
    fi

    echo ""
    warning "Remediation steps:"
    echo "  1. Remove secrets from code"
    echo "  2. Use environment variables or secret managers"
    echo "  3. Rotate compromised credentials"
    echo "  4. Use .gitignore for sensitive files"

    if [ "${FAIL_ON_SECRETS}" = "true" ]; then
        fail "Secrets detected - blocking pipeline"
    else
        warning "Secrets detected - continuing (FAIL_ON_SECRETS=false)"
        exit 0
    fi
fi
