# ==============================================================================
# DevSecOps Toolbox - All-in-One Security Scanning Image
# ==============================================================================
# This image contains all security tools needed for DevSecOps pipelines
# Use as base image: FROM yourorg/devsecops-toolbox:1.0.0
# ==============================================================================

FROM maven:3.8.6-openjdk-17

LABEL maintainer="devops@yourorg.com"
LABEL description="DevSecOps toolbox with all security scanning tools pre-installed"
LABEL version="1.0.0"

# ==============================================================================
# Install System Dependencies
# ==============================================================================
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    unzip \
    python3 \
    python3-pip \
    bc \
    xmllint \
    libxml2-utils \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Install Security Tools
# ==============================================================================

# GitLeaks - Secrets Scanner
ARG GITLEAKS_VERSION=8.18.0
RUN wget -q https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    tar -xzf gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    mv gitleaks /usr/local/bin/ && \
    rm gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    gitleaks version

# Trivy - Container & Dependency Scanner
ARG TRIVY_VERSION=0.48.0
RUN wget -q https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
    tar -xzf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
    mv trivy /usr/local/bin/ && \
    rm trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
    trivy --version

# Hadolint - Dockerfile Linter
ARG HADOLINT_VERSION=2.12.0
RUN wget -q -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64 && \
    chmod +x /usr/local/bin/hadolint && \
    hadolint --version

# Checkov - IaC Security Scanner
RUN pip3 install --no-cache-dir \
    checkov==3.1.0 \
    && checkov --version

# Syft - SBOM Generator for Containers
ARG SYFT_VERSION=0.100.0
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin v${SYFT_VERSION} && \
    syft version

# Grype - Vulnerability Scanner (Alternative to Trivy)
ARG GRYPE_VERSION=0.74.0
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin v${GRYPE_VERSION} && \
    grype version

# ==============================================================================
# Install Additional Tools
# ==============================================================================

# Helm - Kubernetes Package Manager
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    helm version

# Kubectl - Kubernetes CLI
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl && \
    kubectl version --client

# ==============================================================================
# Copy Reusable Scripts
# ==============================================================================
COPY scripts/ /opt/devsecops-scripts/
RUN chmod +x /opt/devsecops-scripts/**/*.sh

# Add scripts to PATH
ENV PATH="/opt/devsecops-scripts:${PATH}"

# ==============================================================================
# Configuration
# ==============================================================================
WORKDIR /workspace

# Set default environment variables
ENV FAIL_ON_SECRETS=false \
    CVSS_THRESHOLD=7.0 \
    TRIVY_SEVERITY=CRITICAL,HIGH,MEDIUM

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD which gitleaks && which trivy && which hadolint || exit 1

# Metadata
LABEL org.opencontainers.image.title="DevSecOps Toolbox"
LABEL org.opencontainers.image.description="Complete security scanning toolbox for CI/CD pipelines"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.created="2025-10-29"
LABEL tools="gitleaks,trivy,hadolint,checkov,syft,grype,helm,kubectl"

CMD ["/bin/bash"]
