FROM alpine:3.18

LABEL maintainer="devops@yourorg.com"
LABEL description="Bitbucket Pipe for secrets scanning with GitLeaks"

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    wget \
    jq \
    ca-certificates

# Install GitLeaks
ARG GITLEAKS_VERSION=8.18.0
RUN wget -q https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    tar -xzf gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    mv gitleaks /usr/local/bin/ && \
    rm gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz && \
    gitleaks version

# Copy helper functions
COPY common.sh /common.sh
RUN chmod +x /common.sh

# Copy pipe script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

WORKDIR /workspace

ENTRYPOINT ["/pipe.sh"]
