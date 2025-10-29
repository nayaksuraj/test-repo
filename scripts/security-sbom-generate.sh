#!/bin/bash
# ==============================================================================
# SBOM (Software Bill of Materials) Generation Script
# ==============================================================================
# This script generates SBOM for software supply chain security
# Part of Phase 1: Foundation (HIGH PRIORITY)
# Standards: CycloneDX, SPDX
# Implements: SLSA Level 2, NTIA Minimum Elements
# ==============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# ==============================================================================
# Configuration Variables
# ==============================================================================
SBOM_FORMAT="${SBOM_FORMAT:-cyclonedx}"  # cyclonedx or spdx
SBOM_VERSION="${SBOM_VERSION:-1.5}"
OUTPUT_DIR="${OUTPUT_DIR:-security-reports/sbom}"
ATTACH_TO_ARTIFACT="${ATTACH_TO_ARTIFACT:-true}"

# Maven/Gradle detection
BUILD_TOOL="maven"
if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    BUILD_TOOL="gradle"
fi

# Colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "==============================================================================="
echo "📦 SBOM GENERATION - SOFTWARE BILL OF MATERIALS"
echo "==============================================================================="
echo "Format: ${SBOM_FORMAT}"
echo "Version: ${SBOM_VERSION}"
echo "Build Tool: ${BUILD_TOOL}"
echo "Output Directory: ${OUTPUT_DIR}"
echo ""

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# ==============================================================================
# Generate SBOM using CycloneDX
# ==============================================================================
if [ "$SBOM_FORMAT" = "cyclonedx" ]; then
    echo "=== Generating CycloneDX SBOM ==="
    echo ""

    if [[ "$BUILD_TOOL" == "maven" ]]; then
        # Maven: Use CycloneDX Maven Plugin
        echo "Using CycloneDX Maven Plugin..."

        # Check if plugin is in pom.xml
        if ! grep -q "cyclonedx-maven-plugin" pom.xml 2>/dev/null; then
            echo "⚠️  Warning: cyclonedx-maven-plugin not found in pom.xml"
            echo "   Add the following to your pom.xml:"
            echo ""
            echo "<build>"
            echo "  <plugins>"
            echo "    <plugin>"
            echo "      <groupId>org.cyclonedx</groupId>"
            echo "      <artifactId>cyclonedx-maven-plugin</artifactId>"
            echo "      <version>2.7.10</version>"
            echo "      <executions>"
            echo "        <execution>"
            echo "          <phase>package</phase>"
            echo "          <goals><goal>makeAggregateBom</goal></goals>"
            echo "        </execution>"
            echo "      </executions>"
            echo "    </plugin>"
            echo "  </plugins>"
            echo "</build>"
            echo ""

            # Generate using Maven plugin directly
            mvn org.cyclonedx:cyclonedx-maven-plugin:2.7.10:makeAggregateBom \
                -DoutputFormat=all \
                -DoutputName=bom
        else
            # Use configured plugin
            mvn cyclonedx:makeAggregateBom \
                -DoutputFormat=all \
                -DoutputName=bom
        fi

        # Copy generated SBOM to output directory
        if [ -f "target/bom.json" ]; then
            cp target/bom.json "${OUTPUT_DIR}/sbom-cyclonedx.json"
            echo -e "${GREEN}✓ JSON SBOM generated${NC}"
        fi

        if [ -f "target/bom.xml" ]; then
            cp target/bom.xml "${OUTPUT_DIR}/sbom-cyclonedx.xml"
            echo -e "${GREEN}✓ XML SBOM generated${NC}"
        fi

    elif [[ "$BUILD_TOOL" == "gradle" ]]; then
        # Gradle: Use CycloneDX Gradle Plugin
        echo "Using CycloneDX Gradle Plugin..."

        if ! grep -q "org.cyclonedx.bom" build.gradle* 2>/dev/null; then
            echo "⚠️  Warning: CycloneDX plugin not found in build.gradle"
            echo "   Add: id 'org.cyclonedx.bom' version '1.8.2'"
        fi

        ./gradlew cyclonedxBom

        # Copy generated SBOM
        if [ -f "build/reports/bom.json" ]; then
            cp build/reports/bom.json "${OUTPUT_DIR}/sbom-cyclonedx.json"
            echo -e "${GREEN}✓ JSON SBOM generated${NC}"
        fi
    fi
fi

# ==============================================================================
# Generate SPDX SBOM (Optional)
# ==============================================================================
if [ "$SBOM_FORMAT" = "spdx" ] || [ "$SBOM_FORMAT" = "both" ]; then
    echo ""
    echo "=== Generating SPDX SBOM ==="
    echo ""

    if [[ "$BUILD_TOOL" == "maven" ]]; then
        # Maven: Use SPDX Maven Plugin
        if grep -q "spdx-maven-plugin" pom.xml 2>/dev/null; then
            mvn spdx:createSPDX
            cp target/*.spdx "${OUTPUT_DIR}/sbom-spdx.json" 2>/dev/null || echo "SPDX generation skipped"
        else
            echo "⚠️  SPDX plugin not configured, skipping"
        fi
    fi
fi

# ==============================================================================
# Generate Container SBOM (if Docker image exists)
# ==============================================================================
echo ""
echo "=== Checking for Container Image SBOM ==="

if [ -f "build-info/docker-image.txt" ]; then
    source build-info/docker-image.txt

    if [ -n "$DOCKER_IMAGE" ]; then
        echo "Generating SBOM for container image: $DOCKER_IMAGE"

        # Check if Syft is installed
        if command -v syft &> /dev/null; then
            syft "$DOCKER_IMAGE" -o cyclonedx-json > "${OUTPUT_DIR}/sbom-container-cyclonedx.json"
            syft "$DOCKER_IMAGE" -o spdx-json > "${OUTPUT_DIR}/sbom-container-spdx.json"
            echo -e "${GREEN}✓ Container SBOM generated${NC}"
        else
            echo "⚠️  Syft not installed. Install with: curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"
        fi
    fi
else
    echo "No container image found, skipping container SBOM"
fi

# ==============================================================================
# Validate SBOM
# ==============================================================================
echo ""
echo "=== Validating SBOM ==="

if [ -f "${OUTPUT_DIR}/sbom-cyclonedx.json" ]; then
    if command -v jq &> /dev/null; then
        # Validate JSON structure
        if jq empty "${OUTPUT_DIR}/sbom-cyclonedx.json" 2>/dev/null; then
            echo -e "${GREEN}✓ SBOM JSON is valid${NC}"

            # Display summary
            COMPONENT_COUNT=$(jq '.components | length' "${OUTPUT_DIR}/sbom-cyclonedx.json" 2>/dev/null || echo "Unknown")
            DEPENDENCY_COUNT=$(jq '.dependencies | length' "${OUTPUT_DIR}/sbom-cyclonedx.json" 2>/dev/null || echo "Unknown")

            echo ""
            echo "=== SBOM Summary ==="
            echo "Components: ${COMPONENT_COUNT}"
            echo "Dependencies: ${DEPENDENCY_COUNT}"
            echo "Format: CycloneDX ${SBOM_VERSION}"
        else
            echo "⚠️  SBOM JSON validation failed"
        fi
    fi
fi

# ==============================================================================
# Attach SBOM to Artifacts
# ==============================================================================
if [ "$ATTACH_TO_ARTIFACT" = "true" ]; then
    echo ""
    echo "=== Attaching SBOM to Build Artifacts ==="

    # Create build-info directory if it doesn't exist
    mkdir -p build-info

    # Copy SBOM to build artifacts
    if [ -f "${OUTPUT_DIR}/sbom-cyclonedx.json" ]; then
        cp "${OUTPUT_DIR}/sbom-cyclonedx.json" build-info/
        echo -e "${GREEN}✓ SBOM attached to build artifacts${NC}"
    fi

    # Create SBOM metadata
    cat > build-info/sbom-info.txt << EOF
SBOM_FORMAT=${SBOM_FORMAT}
SBOM_VERSION=${SBOM_VERSION}
SBOM_GENERATED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SBOM_TOOL=CycloneDX
BUILD_TOOL=${BUILD_TOOL}
EOF
fi

# ==============================================================================
# Generate Human-Readable Report
# ==============================================================================
echo ""
echo "=== Generating Human-Readable Report ==="

if [ -f "${OUTPUT_DIR}/sbom-cyclonedx.json" ] && command -v jq &> /dev/null; then
    # Create a simple text report
    cat > "${OUTPUT_DIR}/sbom-report.txt" << EOF
Software Bill of Materials (SBOM) Report
Generated: $(date)
Format: CycloneDX ${SBOM_VERSION}

=== Top-Level Component ===
$(jq -r '.metadata.component | "Name: \(.name)\nVersion: \(.version)\nType: \(.type)\nGroup: \(.group // "N/A")"' "${OUTPUT_DIR}/sbom-cyclonedx.json")

=== Component Summary ===
Total Components: $(jq '.components | length' "${OUTPUT_DIR}/sbom-cyclonedx.json")

=== Component Breakdown by Type ===
$(jq -r '.components | group_by(.type) | .[] | "\(.[0].type): \(length)"' "${OUTPUT_DIR}/sbom-cyclonedx.json")

=== Top 10 Dependencies ===
$(jq -r '.components[:10] | .[] | "- \(.name):\(.version) (\(.purl // "no purl"))"' "${OUTPUT_DIR}/sbom-cyclonedx.json")

=== License Summary ===
$(jq -r '[.components[].licenses[]?.license.id // "Unknown"] | group_by(.) | .[] | "\(.[0]): \(length)"' "${OUTPUT_DIR}/sbom-cyclonedx.json" 2>/dev/null || echo "License information not available")

For full details, see: ${OUTPUT_DIR}/sbom-cyclonedx.json
EOF

    echo -e "${GREEN}✓ Human-readable report generated${NC}"
    cat "${OUTPUT_DIR}/sbom-report.txt"
fi

# ==============================================================================
# Summary
# ==============================================================================
echo ""
echo "==============================================================================="
echo "📦 SBOM GENERATION COMPLETE"
echo "==============================================================================="
echo ""
echo "=== Generated Files ==="
find "${OUTPUT_DIR}" -type f -exec echo "  - {}" \;
echo ""

echo "=== SBOM Use Cases ==="
echo "1. Supply Chain Security: Track all dependencies"
echo "2. Vulnerability Management: Map CVEs to components"
echo "3. License Compliance: Identify license obligations"
echo "4. Incident Response: Quickly identify affected components"
echo "5. Regulatory Compliance: NTIA, FDA, CISA requirements"
echo ""

echo "=== Next Steps ==="
echo "1. Publish SBOM to artifact repository"
echo "2. Integrate with vulnerability scanning tools"
echo "3. Maintain SBOM alongside container images"
echo "4. Include SBOM in software releases"
echo ""
echo -e "${GREEN}✓ SBOM generation successful${NC}"
