# =============================================================================
# Helm Pipe - Lint, Package, and Push Helm Charts
# =============================================================================
# Production-ready image with Helm 3, plugins, and validation tools
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
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Helm
# =============================================================================
ENV HELM_VERSION=3.13.3
RUN curl -fsSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | \
    tar -xz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    rm -rf /tmp/linux-amd64 && \
    chmod +x /usr/local/bin/helm

# =============================================================================
# Install Helm Plugins
# =============================================================================
# helm-push: Push charts to ChartMuseum and OCI registries
RUN helm plugin install https://github.com/chartmuseum/helm-push || true

# helm-diff: Preview helm upgrade changes
RUN helm plugin install https://github.com/databus23/helm-diff || true

# helm-secrets: Manage secrets in Helm charts
RUN apt-get update && apt-get install -y gnupg && rm -rf /var/lib/apt/lists/* && \
    helm plugin install https://github.com/jkroepke/helm-secrets || true

# =============================================================================
# Install kubectl (for validating deployments)
# =============================================================================
RUN curl -fsSL https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl \
    -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# =============================================================================
# Install yamllint (for YAML validation)
# =============================================================================
RUN apt-get update && apt-get install -y python3-pip && \
    pip3 install --no-cache-dir yamllint && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install yq (for YAML processing)
# =============================================================================
ENV YQ_VERSION=4.35.2
RUN wget -q https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 \
    -O /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# =============================================================================
# Create Chart Directory
# =============================================================================
RUN mkdir -p /work/charts

# =============================================================================
# Copy and Setup Pipe
# =============================================================================
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

WORKDIR /work

# Verify installations
RUN helm version && kubectl version --client && yq --version

ENTRYPOINT ["/pipe.sh"]
