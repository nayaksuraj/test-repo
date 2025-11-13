# =============================================================================
# Helm Pipe - Lint, Package, and Push Helm Charts
# =============================================================================
# Enterprise-grade Helm chart management pipeline
# Usage: pipe: docker://nayaksuraj/helm-pipe:1.0.0
# =============================================================================

FROM alpine:3.19

# Metadata
LABEL maintainer="nayaksuraj" \
      version="1.0.0" \
      description="Helm chart lint, package, and push pipe"

# Install Helm and required tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates \
    jq \
    wget \
    tar \
    gzip

# Install Helm
ARG HELM_VERSION=3.13.3
RUN wget -q https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
    tar -xzf helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64 && \
    chmod +x /usr/local/bin/helm

# Install helm plugins for OCI support
RUN helm plugin install https://github.com/chartmuseum/helm-push || true

# Copy pipe script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

# Set working directory
WORKDIR /work

# Health check
RUN helm version

# Run the pipe
ENTRYPOINT ["/pipe.sh"]
