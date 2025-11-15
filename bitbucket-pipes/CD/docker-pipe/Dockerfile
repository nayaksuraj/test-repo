# =============================================================================
# Docker Pipe - Build, Scan, and Push Docker Images
# =============================================================================
# Production-ready image with Docker, Buildx, Trivy, and Grype
# =============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# =============================================================================
# Install Base Tools
# =============================================================================
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    git \
    ca-certificates \
    jq \
    unzip \
    tar \
    gzip \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Docker CLI + Buildx
# =============================================================================
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Trivy (Comprehensive Vulnerability Scanner)
# =============================================================================
ENV TRIVY_VERSION=0.48.0
RUN curl -fsSL https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz | \
    tar -xz -C /usr/local/bin trivy && \
    chmod +x /usr/local/bin/trivy

# =============================================================================
# Install Grype (Alternative Vulnerability Scanner)
# =============================================================================
ENV GRYPE_VERSION=0.74.0
RUN curl -fsSL https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz | \
    tar -xz -C /usr/local/bin grype && \
    chmod +x /usr/local/bin/grype

# =============================================================================
# Install Dive (Image Layer Analysis - Optional but useful)
# =============================================================================
ENV DIVE_VERSION=0.11.0
RUN curl -fsSL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz | \
    tar -xz -C /usr/local/bin dive && \
    chmod +x /usr/local/bin/dive

# =============================================================================
# Create Build Info Directory
# =============================================================================
RUN mkdir -p /work/build-info

# =============================================================================
# Copy and Setup Pipe
# =============================================================================
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

WORKDIR /work

# Verify installations
RUN docker --version && trivy --version && grype version

ENTRYPOINT ["/pipe.sh"]
