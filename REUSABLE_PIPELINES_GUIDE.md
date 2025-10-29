# Reusable Bitbucket Pipeline Components Guide

## Overview

This guide shows how to create reusable pipeline components (similar to GitHub Composite Actions) for Bitbucket Pipelines. There are three main approaches:

1. **Bitbucket Pipes** (Official) - Package as Docker images
2. **Remote YAML Templates** - Include YAML from another repository
3. **Shared Scripts Repository** - Git submodules or clone approach

---

## Approach 1: Bitbucket Pipes (Recommended)

### What are Bitbucket Pipes?

Bitbucket Pipes are Docker containers that run as steps in your pipeline, similar to GitHub Actions. They're the official way to create reusable components.

### Structure

Create a separate repository: `bitbucket-devsecops-pipes`

```
bitbucket-devsecops-pipes/
├── secrets-scan/
│   ├── pipe.yml
│   ├── Dockerfile
│   ├── pipe.sh
│   └── README.md
├── dependency-scan/
│   ├── pipe.yml
│   ├── Dockerfile
│   ├── pipe.sh
│   └── README.md
├── sbom-generate/
│   ├── pipe.yml
│   ├── Dockerfile
│   ├── pipe.sh
│   └── README.md
└── README.md
```

### Example: Secrets Scan Pipe

**Repository: `your-org/bitbucket-devsecops-pipes`**

#### secrets-scan/pipe.yml
```yaml
name: Secrets Scanner
image: yourorg/secrets-scan-pipe:1.0.0
description: Scan code for secrets and credentials using GitLeaks
repository: https://bitbucket.org/yourorg/bitbucket-devsecops-pipes

variables:
  - name: FAIL_ON_SECRETS
    type: boolean
    default: true
  - name: SCAN_PATH
    type: string
    default: "."
  - name: GITLEAKS_VERSION
    type: string
    default: "8.18.0"
  - name: DEBUG
    type: boolean
    default: false
```

#### secrets-scan/Dockerfile
```dockerfile
FROM alpine:3.18

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    wget \
    ca-certificates

# Install GitLeaks
ARG GITLEAKS_VERSION=8.18.0
RUN wget -q https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    tar -xzf gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    mv gitleaks /usr/local/bin/ && \
    rm gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz

# Copy pipe script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

ENTRYPOINT ["/pipe.sh"]
```

#### secrets-scan/pipe.sh
```bash
#!/bin/bash
set -e

# Bitbucket Pipes script for secrets scanning
source "$(dirname "$0")/common.sh"

FAIL_ON_SECRETS=${FAIL_ON_SECRETS:=true}
SCAN_PATH=${SCAN_PATH:="."}
DEBUG=${DEBUG:=false}

info "Running Secrets Scan with GitLeaks"
info "Scan Path: ${SCAN_PATH}"
info "Fail on Secrets: ${FAIL_ON_SECRETS}"

# Create reports directory
mkdir -p security-reports

# Run GitLeaks
run gitleaks detect \
    --source="${SCAN_PATH}" \
    --report-path=security-reports/gitleaks-report.json \
    --report-format=json \
    --verbose \
    --no-git

GITLEAKS_EXIT_CODE=$?

if [ $GITLEAKS_EXIT_CODE -eq 0 ]; then
    success "No secrets detected!"
else
    if [ -f "security-reports/gitleaks-report.json" ]; then
        SECRET_COUNT=$(jq '. | length' security-reports/gitleaks-report.json)
        error "Found ${SECRET_COUNT} secrets!"

        jq -r '.[] | "File: \(.File)\nLine: \(.StartLine)\nRule: \(.RuleID)\n"' \
            security-reports/gitleaks-report.json
    fi

    if [ "$FAIL_ON_SECRETS" = "true" ]; then
        fail "Secrets detected - blocking pipeline"
    else
        warning "Secrets detected - continuing (FAIL_ON_SECRETS=false)"
    fi
fi
```

#### secrets-scan/README.md
```markdown
# Secrets Scanner Pipe

Scans your code for secrets and credentials using GitLeaks.

## Usage

```yaml
- pipe: docker://yourorg/secrets-scan-pipe:1.0.0
  variables:
    FAIL_ON_SECRETS: true
    SCAN_PATH: "."
```

## Variables

- `FAIL_ON_SECRETS` (default: `true`): Fail pipeline if secrets found
- `SCAN_PATH` (default: `"."`): Path to scan
- `GITLEAKS_VERSION` (default: `"8.18.0"`): GitLeaks version
```

---

## Approach 2: Remote YAML Templates

### Structure

Create a repository: `pipeline-templates`

```
pipeline-templates/
├── templates/
│   ├── security/
│   │   ├── secrets-scan.yml
│   │   ├── dependency-scan.yml
│   │   ├── sbom-generate.yml
│   │   └── container-scan.yml
│   ├── build/
│   │   ├── maven-build.yml
│   │   └── docker-build.yml
│   └── deploy/
│       ├── kubernetes-deploy.yml
│       └── helm-deploy.yml
└── README.md
```

### Example: Security Template

**templates/security/secrets-scan.yml**
```yaml
definitions:
  steps:
    - step: &secrets-scan
        name: 🔒 Secrets Scanning
        image: alpine/git:latest
        script:
          # Download the security script
          - apk add --no-cache wget bash
          - wget -O /tmp/security-secrets-scan.sh https://raw.githubusercontent.com/yourorg/pipeline-templates/main/scripts/security-secrets-scan.sh
          - chmod +x /tmp/security-secrets-scan.sh

          # Run the scan
          - export FAIL_ON_SECRETS=${FAIL_ON_SECRETS:-true}
          - /tmp/security-secrets-scan.sh
        artifacts:
          - security-reports/**
```

### Using Remote Templates in Your Pipeline

**In your application repository's bitbucket-pipelines.yml:**

```yaml
# Method 1: Using Bitbucket Pipes (Recommended)
image: maven:3.8.6-openjdk-17

pipelines:
  default:
    # Use your custom pipe
    - pipe: docker://yourorg/secrets-scan-pipe:1.0.0
      variables:
        FAIL_ON_SECRETS: true

    - pipe: docker://yourorg/dependency-scan-pipe:1.0.0
      variables:
        CVSS_THRESHOLD: 7.0
        FAIL_ON_CVSS: true

    - step:
        name: Build Application
        script:
          - mvn clean package

# Method 2: Remote YAML reference (Bitbucket doesn't support this directly)
# But you can use a workaround with scripts
```

---

## Approach 3: Shared Scripts via Docker Image

### Create a Base Docker Image with All Tools

**Repository: `pipeline-toolbox`**

#### Dockerfile
```dockerfile
FROM maven:3.8.6-openjdk-17

LABEL maintainer="devops@yourorg.com"
LABEL description="DevSecOps toolbox with all security scanning tools"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    unzip \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install GitLeaks
ARG GITLEAKS_VERSION=8.18.0
RUN wget -q https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    tar -xzf gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    mv gitleaks /usr/local/bin/ && \
    rm gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz

# Install Trivy
ARG TRIVY_VERSION=0.48.0
RUN wget -q https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
    tar -xzf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
    mv trivy /usr/local/bin/ && \
    rm trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz

# Install Hadolint
ARG HADOLINT_VERSION=2.12.0
RUN wget -q -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64 && \
    chmod +x /usr/local/bin/hadolint

# Install Checkov
RUN pip3 install checkov==3.1.0

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Copy all reusable scripts
COPY scripts/ /opt/devsecops-scripts/
RUN chmod +x /opt/devsecops-scripts/*.sh

# Add scripts to PATH
ENV PATH="/opt/devsecops-scripts:${PATH}"

WORKDIR /workspace
```

### Build and Publish

```bash
# Build the image
docker build -t yourorg/devsecops-toolbox:1.0.0 .

# Push to Docker Hub or private registry
docker push yourorg/devsecops-toolbox:1.0.0
```

### Use in Your Pipeline

**bitbucket-pipelines.yml:**

```yaml
image: yourorg/devsecops-toolbox:1.0.0

pipelines:
  default:
    - step:
        name: 🔒 Secrets Scan
        script:
          - security-secrets-scan.sh
        artifacts:
          - security-reports/**

    - step:
        name: 🔒 Dependency Scan
        script:
          - security-sca-scan.sh
        artifacts:
          - security-reports/**

    - step:
        name: Build
        script:
          - mvn clean package
```

---

## Recommended Implementation Strategy

### Step 1: Create Shared Repository Structure

Create repository: `yourorg/bitbucket-pipeline-library`

```
bitbucket-pipeline-library/
├── pipes/                          # Bitbucket Pipes
│   ├── secrets-scan/
│   ├── dependency-scan/
│   ├── sbom-generate/
│   ├── dockerfile-scan/
│   ├── container-scan/
│   └── iac-scan/
├── docker/                         # Docker images
│   ├── devsecops-toolbox/
│   │   ├── Dockerfile
│   │   └── README.md
│   └── build-base/
├── scripts/                        # Shared scripts
│   ├── security/
│   │   ├── security-secrets-scan.sh
│   │   ├── security-sca-scan.sh
│   │   ├── security-sbom-generate.sh
│   │   ├── security-dockerfile-scan.sh
│   │   └── security-iac-scan.sh
│   ├── build/
│   └── deploy/
├── templates/                      # YAML templates
│   ├── security-steps.yml
│   ├── build-steps.yml
│   └── deploy-steps.yml
├── docs/
│   ├── usage.md
│   └── development.md
└── README.md
```

### Step 2: Create Helper Script for Downloading

**In your app repository, create: `.bitbucket/scripts/use-shared-scripts.sh`**

```bash
#!/bin/bash
# Download shared scripts from pipeline library

LIBRARY_REPO="https://bitbucket.org/yourorg/bitbucket-pipeline-library.git"
LIBRARY_VERSION="${LIBRARY_VERSION:-main}"
SCRIPTS_DIR="/tmp/shared-pipeline-scripts"

echo "Downloading shared pipeline scripts..."
git clone --depth 1 --branch ${LIBRARY_VERSION} ${LIBRARY_REPO} ${SCRIPTS_DIR}

# Copy scripts to current directory
cp -r ${SCRIPTS_DIR}/scripts/* ./scripts/

echo "Shared scripts downloaded successfully"
```

### Step 3: Use in Pipeline

**bitbucket-pipelines.yml:**

```yaml
image: maven:3.8.6-openjdk-17

definitions:
  steps:
    - step: &download-shared-scripts
        name: Download Shared Scripts
        script:
          - apt-get update && apt-get install -y git
          - chmod +x .bitbucket/scripts/use-shared-scripts.sh
          - ./.bitbucket/scripts/use-shared-scripts.sh
        artifacts:
          - scripts/**

pipelines:
  default:
    # Download shared scripts first
    - step: *download-shared-scripts

    # Now use the scripts
    - step:
        name: 🔒 Secrets Scan
        script:
          - chmod +x scripts/security/security-secrets-scan.sh
          - ./scripts/security/security-secrets-scan.sh

    - step:
        name: 🔒 Dependency Scan
        script:
          - chmod +x scripts/security/security-sca-scan.sh
          - ./scripts/security/security-sca-scan.sh
```

---

## Complete Example: Using All Three Approaches

I'll create a complete working example for you in the next files.

### Benefits of Each Approach

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| **Bitbucket Pipes** | Official, clean syntax, versioned | Requires Docker registry | Production use |
| **Docker Image** | Fast, pre-installed tools | Image size, maintenance | Multiple projects |
| **Git Clone** | Simple, no Docker needed | Slower, downloads every time | Quick prototypes |

---

## Next Steps

1. Choose your approach (I recommend Bitbucket Pipes for production)
2. Create the shared repository
3. Build and publish pipes/docker images
4. Update your application pipelines to use them
5. Version and maintain the library

Let me create the complete implementation files for you!
