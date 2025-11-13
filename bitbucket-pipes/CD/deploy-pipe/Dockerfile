# =============================================================================
# Deploy Pipe - Deploy to Kubernetes using Helm
# =============================================================================
# Enterprise-grade Kubernetes deployment pipeline
# Usage: pipe: docker://nayaksuraj/deploy-pipe:1.0.0
# =============================================================================

FROM alpine:3.19

# Metadata
LABEL maintainer="nayaksuraj" \
      version="1.0.0" \
      description="Kubernetes deployment pipe using Helm"

# Install kubectl, helm, and required tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates \
    jq \
    wget \
    tar \
    gzip

# Install kubectl
ARG KUBECTL_VERSION=1.28.4
RUN wget -q https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Helm
ARG HELM_VERSION=3.13.3
RUN wget -q https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
    tar -xzf helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64 && \
    chmod +x /usr/local/bin/helm

# Copy pipe script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

# Set working directory
WORKDIR /work

# Health check
RUN kubectl version --client && helm version

# Run the pipe
ENTRYPOINT ["/pipe.sh"]
