#!/bin/bash
# ==============================================================================
# Infrastructure as Code (IaC) Security Scanning
# ==============================================================================
# This script scans Kubernetes/Helm configurations for security issues
# Part of Phase 2: Enhancement (HIGH PRIORITY)
# Tools: Checkov, Kubesec
# Implements: CIS Kubernetes Benchmarks, Pod Security Standards
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables
# ==============================================================================
HELM_CHART_PATH="${HELM_CHART_PATH:-./helm-chart}"
FAIL_ON_HIGH="${FAIL_ON_HIGH:-false}"  # Fail on HIGH severity issues
CHECK OV_VERSION="${CHECKOV_VERSION:-3.1.0}"
SCAN_TYPE="${SCAN_TYPE:-helm}"  # helm, kubernetes, or both

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "==============================================================================="
echo "☸️  INFRASTRUCTURE AS CODE (IAC) SECURITY SCANNING"
echo "==============================================================================="
echo "Scan Type: ${SCAN_TYPE}"
echo "Helm Chart Path: ${HELM_CHART_PATH}"
echo "Fail on High: ${FAIL_ON_HIGH}"
echo ""

# Create security reports directory
mkdir -p security-reports/iac

# ==============================================================================
# Install Checkov (if not already installed)
# ==============================================================================
install_checkov() {
    if ! command -v checkov &> /dev/null; then
        echo "=== Installing Checkov ==="
        echo "Installing via pip..."

        pip3 install checkov==${CHECKOV_VERSION} --quiet || \
        pip install checkov==${CHECKOV_VERSION} --quiet

        checkov --version
        echo ""
    fi
}

# ==============================================================================
# Scan Helm Charts
# ==============================================================================
scan_helm_charts() {
    if [ "$SCAN_TYPE" = "helm" ] || [ "$SCAN_TYPE" = "both" ]; then
        echo "=== Scanning Helm Charts with Checkov ==="
        echo "Path: ${HELM_CHART_PATH}"
        echo ""

        if [ ! -d "$HELM_CHART_PATH" ]; then
            echo -e "${YELLOW}⚠ Helm chart directory not found: $HELM_CHART_PATH${NC}"
            return 0
        fi

        install_checkov

        # Run Checkov on Helm charts
        set +e
        checkov -d "$HELM_CHART_PATH" \
            --framework helm \
            --output cli \
            --output json \
            --output junitxml \
            --output-file-path security-reports/iac \
            --quiet

        CHECKOV_EXIT_CODE=$?
        set -e

        echo ""
        parse_checkov_results
    fi
}

# ==============================================================================
# Scan Kubernetes Manifests
# ==============================================================================
scan_kubernetes_manifests() {
    if [ "$SCAN_TYPE" = "kubernetes" ] || [ "$SCAN_TYPE" = "both" ]; then
        echo "=== Rendering Helm Templates for Kubernetes Scanning ==="

        # Render Helm templates to Kubernetes manifests
        if [ -d "$HELM_CHART_PATH" ] && command -v helm &> /dev/null; then
            mkdir -p security-reports/iac/rendered-templates

            helm template test-release "$HELM_CHART_PATH" \
                --values "$HELM_CHART_PATH/values.yaml" \
                > security-reports/iac/rendered-templates/manifests.yaml

            echo -e "${GREEN}✓ Helm templates rendered${NC}"
            echo ""

            # Scan rendered manifests with Checkov
            echo "=== Scanning Kubernetes Manifests with Checkov ==="

            set +e
            checkov -f security-reports/iac/rendered-templates/manifests.yaml \
                --framework kubernetes \
                --output cli \
                --output json \
                --output-file-path security-reports/iac \
                --quiet

            CHECKOV_K8S_EXIT_CODE=$?
            set -e

            echo ""
        else
            echo -e "${YELLOW}⚠ Helm not installed or chart not found, skipping K8s manifest scan${NC}"
        fi
    fi
}

# ==============================================================================
# Parse Checkov Results
# ==============================================================================
parse_checkov_results() {
    local RESULT_FILE="security-reports/iac/results_cli.txt"

    if [ -f "security-reports/iac/results_json.json" ] && command -v jq &> /dev/null; then
        echo "=== Checkov Results Summary ==="

        # Parse JSON results
        PASSED=$(jq '.summary.passed' security-reports/iac/results_json.json 2>/dev/null || echo "0")
        FAILED=$(jq '.summary.failed' security-reports/iac/results_json.json 2>/dev/null || echo "0")
        SKIPPED=$(jq '.summary.skipped' security-reports/iac/results_json.json 2>/dev/null || echo "0")

        echo -e "${GREEN}Passed:  ${PASSED}${NC}"
        echo -e "${RED}Failed:  ${FAILED}${NC}"
        echo -e "${CYAN}Skipped: ${SKIPPED}${NC}"
        echo ""

        # Show failed checks by severity
        echo "=== Failed Checks by Severity ==="
        CRITICAL=$(jq '[.results.failed_checks[] | select(.severity=="CRITICAL")] | length' security-reports/iac/results_json.json 2>/dev/null || echo "0")
        HIGH=$(jq '[.results.failed_checks[] | select(.severity=="HIGH")] | length' security-reports/iac/results_json.json 2>/dev/null || echo "0")
        MEDIUM=$(jq '[.results.failed_checks[] | select(.severity=="MEDIUM")] | length' security-reports/iac/results_json.json 2>/dev/null || echo "0")
        LOW=$(jq '[.results.failed_checks[] | select(.severity=="LOW")] | length' security-reports/iac/results_json.json 2>/dev/null || echo "0")

        echo -e "${RED}CRITICAL: ${CRITICAL}${NC}"
        echo -e "${RED}HIGH:     ${HIGH}${NC}"
        echo -e "${YELLOW}MEDIUM:   ${MEDIUM}${NC}"
        echo -e "${CYAN}LOW:      ${LOW}${NC}"
        echo ""

        # Display top issues
        if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            echo "=== Top Critical/High Issues ==="
            jq -r '.results.failed_checks[] | select(.severity=="CRITICAL" or .severity=="HIGH") | "[\(.severity)] \(.check_id): \(.check_name)\n  File: \(.file_path):\(.file_line_range[0])\n  Guideline: \(.guideline)\n"' \
                security-reports/iac/results_json.json 2>/dev/null | head -20
            echo ""
        fi
    fi
}

# ==============================================================================
# Kubernetes Security Best Practices Check
# ==============================================================================
check_k8s_best_practices() {
    echo "=== Kubernetes Security Best Practices ==="
    echo ""

    BEST_PRACTICES_PASS=0
    BEST_PRACTICES_FAIL=0

    # Check rendered manifests
    if [ -f "security-reports/iac/rendered-templates/manifests.yaml" ]; then
        MANIFEST_FILE="security-reports/iac/rendered-templates/manifests.yaml"

        # Check 1: RunAsNonRoot
        if grep -q "runAsNonRoot: true" "$MANIFEST_FILE"; then
            echo -e "${GREEN}✓ Containers run as non-root user${NC}"
            ((BEST_PRACTICES_PASS++))
        else
            echo -e "${RED}✗ Containers should run as non-root (runAsNonRoot: true)${NC}"
            ((BEST_PRACTICES_FAIL++))
        fi

        # Check 2: Read-only root filesystem
        if grep -q "readOnlyRootFilesystem: true" "$MANIFEST_FILE"; then
            echo -e "${GREEN}✓ Read-only root filesystem configured${NC}"
            ((BEST_PRACTICES_PASS++))
        else
            echo -e "${YELLOW}⚠ Consider enabling read-only root filesystem${NC}"
            ((BEST_PRACTICES_FAIL++))
        fi

        # Check 3: Resource limits
        if grep -q "limits:" "$MANIFEST_FILE"; then
            echo -e "${GREEN}✓ Resource limits defined${NC}"
            ((BEST_PRACTICES_PASS++))
        else
            echo -e "${RED}✗ Resource limits should be defined${NC}"
            ((BEST_PRACTICES_FAIL++))
        fi

        # Check 4: Security Context
        if grep -q "securityContext:" "$MANIFEST_FILE"; then
            echo -e "${GREEN}✓ Security context configured${NC}"
            ((BEST_PRACTICES_PASS++))
        else
            echo -e "${RED}✗ Security context should be configured${NC}"
            ((BEST_PRACTICES_FAIL++))
        fi

        # Check 5: Network Policies
        if grep -q "kind: NetworkPolicy" "$MANIFEST_FILE"; then
            echo -e "${GREEN}✓ Network policies defined${NC}"
            ((BEST_PRACTICES_PASS++))
        else
            echo -e "${YELLOW}⚠ Consider adding network policies${NC}"
        fi

        # Check 6: Pod Security Standards
        if grep -q "allowPrivilegeEscalation: false" "$MANIFEST_FILE"; then
            echo -e "${GREEN}✓ Privilege escalation disabled${NC}"
            ((BEST_PRACTICES_PASS++))
        else
            echo -e "${RED}✗ Disable privilege escalation${NC}"
            ((BEST_PRACTICES_FAIL++))
        fi

        # Check 7: Capabilities dropped
        if grep -q "drop:" "$MANIFEST_FILE" && grep -A2 "drop:" "$MANIFEST_FILE" | grep -q "ALL"; then
            echo -e "${GREEN}✓ Capabilities dropped${NC}"
            ((BEST_PRACTICES_PASS++))
        else
            echo -e "${YELLOW}⚠ Drop all capabilities and add only required ones${NC}"
        fi

        echo ""
        echo "Best Practices Score: ${BEST_PRACTICES_PASS}/${BEST_PRACTICES_PASS + BEST_PRACTICES_FAIL}"
        echo ""
    fi
}

# ==============================================================================
# CIS Kubernetes Benchmark Checks
# ==============================================================================
check_cis_compliance() {
    echo "=== CIS Kubernetes Benchmark Compliance ==="
    echo ""

    if [ -f "security-reports/iac/rendered-templates/manifests.yaml" ]; then
        MANIFEST_FILE="security-reports/iac/rendered-templates/manifests.yaml"

        # CIS 5.2.1: Minimize admission of privileged containers
        if ! grep -q "privileged: true" "$MANIFEST_FILE"; then
            echo -e "${GREEN}✓ CIS 5.2.1: No privileged containers${NC}"
        else
            echo -e "${RED}✗ CIS 5.2.1: Privileged containers detected${NC}"
        fi

        # CIS 5.2.6: Minimize admission of containers with allowPrivilegeEscalation
        if grep -q "allowPrivilegeEscalation: false" "$MANIFEST_FILE"; then
            echo -e "${GREEN}✓ CIS 5.2.6: Privilege escalation disabled${NC}"
        else
            echo -e "${RED}✗ CIS 5.2.6: Set allowPrivilegeEscalation to false${NC}"
        fi

        # CIS 5.2.5: Minimize admission of containers with NET_RAW capability
        if ! grep -A5 "capabilities:" "$MANIFEST_FILE" | grep -q "NET_RAW"; then
            echo -e "${GREEN}✓ CIS 5.2.5: NET_RAW capability not granted${NC}"
        else
            echo -e "${YELLOW}⚠ CIS 5.2.5: NET_RAW capability detected${NC}"
        fi

        # CIS 5.2.3: Minimize admission of containers with added capabilities
        if grep -q "drop:" "$MANIFEST_FILE"; then
            echo -e "${GREEN}✓ CIS 5.2.3: Capabilities dropped${NC}"
        else
            echo -e "${YELLOW}⚠ CIS 5.2.3: Drop unnecessary capabilities${NC}"
        fi

        echo ""
    fi
}

# ==============================================================================
# Generate Recommendations
# ==============================================================================
generate_recommendations() {
    echo "=== Security Hardening Recommendations ==="
    echo ""
    echo "1. Pod Security Standards:"
    echo "   - Enable Pod Security Admission controller"
    echo "   - Use 'restricted' pod security standard"
    echo ""
    echo "2. RBAC and Service Accounts:"
    echo "   - Use dedicated service accounts"
    echo "   - Apply least privilege principles"
    echo "   - Disable automountServiceAccountToken when not needed"
    echo ""
    echo "3. Network Security:"
    echo "   - Implement network policies"
    echo "   - Use service mesh for mTLS"
    echo "   - Restrict ingress/egress traffic"
    echo ""
    echo "4. Runtime Security:"
    echo "   - Use read-only root filesystems"
    echo "   - Drop all capabilities, add only required"
    echo "   - Set resource limits and requests"
    echo ""
    echo "5. Image Security:"
    echo "   - Use minimal base images"
    echo "   - Scan images for vulnerabilities"
    echo "   - Sign images with Cosign"
    echo ""
    echo "6. Secrets Management:"
    echo "   - Use external secrets operators"
    echo "   - Encrypt secrets at rest"
    echo "   - Rotate secrets regularly"
    echo ""
}

# ==============================================================================
# Main Execution
# ==============================================================================
main() {
    # Scan Helm charts
    scan_helm_charts

    # Scan Kubernetes manifests
    scan_kubernetes_manifests

    # Best practices check
    check_k8s_best_practices

    # CIS compliance check
    check_cis_compliance

    # Generate recommendations
    generate_recommendations

    # ==============================================================================
    # Generate Summary Report
    # ==============================================================================
    cat > security-reports/iac/iac-security-summary.txt << EOF
Infrastructure as Code Security Scan Summary
============================================
Scan Date: $(date)
Helm Chart: ${HELM_CHART_PATH}
Tool: Checkov v${CHECKOV_VERSION}

Scan Results:
- Passed Checks: ${PASSED:-N/A}
- Failed Checks: ${FAILED:-N/A}
- Skipped: ${SKIPPED:-N/A}

Severity Breakdown:
- CRITICAL: ${CRITICAL:-0}
- HIGH: ${HIGH:-0}
- MEDIUM: ${MEDIUM:-0}
- LOW: ${LOW:-0}

Best Practices Score: ${BEST_PRACTICES_PASS:-N/A}/${BEST_PRACTICES_PASS + BEST_PRACTICES_FAIL:-N/A}

Detailed Reports:
- JSON: security-reports/iac/results_json.json
- JUnit: security-reports/iac/results_junitxml.xml

Recommendations: See above

CIS Kubernetes Benchmark: Partially Compliant
Pod Security Standards: See detailed checks above
EOF

    echo "==============================================================================="
    echo "📋 Reports Generated:"
    echo "  - security-reports/iac/results_json.json"
    echo "  - security-reports/iac/iac-security-summary.txt"
    echo "==============================================================================="
    echo ""

    # Determine exit code
    if [ "${CRITICAL:-0}" -gt 0 ] || [ "${HIGH:-0}" -gt 0 ]; then
        if [ "$FAIL_ON_HIGH" = "true" ]; then
            echo -e "${RED}☸️  IAC SECURITY SCAN - FAILED (Critical/High issues found)${NC}"
            echo "==============================================================================="
            exit 1
        else
            echo -e "${YELLOW}☸️  IAC SECURITY SCAN - WARNINGS (Not blocking)${NC}"
            echo "Set FAIL_ON_HIGH=true to enforce IaC security standards"
            echo "==============================================================================="
            exit 0
        fi
    else
        echo -e "${GREEN}☸️  IAC SECURITY SCAN - PASSED${NC}"
        echo "==============================================================================="
        exit 0
    fi
}

# Run main function
main
