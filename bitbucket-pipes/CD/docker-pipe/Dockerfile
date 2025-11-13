# =============================================================================
# Docker Pipe - Build, Scan, and Push Docker Images
# =============================================================================
# Enterprise-grade Docker image build pipeline with security scanning
# Usage: pipe: docker://nayaksuraj/docker-pipe:1.0.0
# =============================================================================

FROM alpine:3.19

# Metadata
LABEL maintainer="nayaksuraj" \
      version="1.0.0" \
      description="Docker build, scan, and push pipe"

# Install Docker CLI and required tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    docker-cli \
    docker-cli-buildx \
    ca-certificates \
    jq \
    wget \
    tar \
    gzip

# Install Trivy for vulnerability scanning
ARG TRIVY_VERSION=0.48.0
RUN wget -qO- https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz | \
    tar -xzf - -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/trivy

# Copy pipe script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

# Set working directory
WORKDIR /work

# Health check
RUN docker --version && trivy --version

# Run the pipe
ENTRYPOINT ["/pipe.sh"]
