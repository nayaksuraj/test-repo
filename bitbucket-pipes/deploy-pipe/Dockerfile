# =============================================================================
# Deploy Pipe - Deploy to Kubernetes using Helm
# =============================================================================
# Production-ready image with kubectl, Helm, and deployment tools
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
# Install kubectl
# =============================================================================
ENV KUBECTL_VERSION=1.28.4
RUN curl -fsSL https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

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
# helm-diff: Preview deployment changes before applying
RUN helm plugin install https://github.com/databus23/helm-diff || true

# =============================================================================
# Install k9s (Kubernetes CLI Dashboard - for debugging)
# =============================================================================
ENV K9S_VERSION=0.29.1
RUN curl -fsSL https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_amd64.tar.gz | \
    tar -xz -C /usr/local/bin k9s && \
    chmod +x /usr/local/bin/k9s

# =============================================================================
# Install kubectx and kubens (context and namespace switching)
# =============================================================================
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
    ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
    ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# =============================================================================
# Install yq (for YAML processing)
# =============================================================================
ENV YQ_VERSION=4.35.2
RUN wget -q https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 \
    -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# =============================================================================
# Install kustomize (for Kubernetes customizations)
# =============================================================================
ENV KUSTOMIZE_VERSION=5.3.0
RUN curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | \
    tar -xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/kustomize

# =============================================================================
# Create Deployment Info Directory
# =============================================================================
RUN mkdir -p /work/deployment-info

# =============================================================================
# Copy and Setup Pipe
# =============================================================================
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

WORKDIR /work

# Verify installations
RUN kubectl version --client && helm version && kustomize version

ENTRYPOINT ["/pipe.sh"]
