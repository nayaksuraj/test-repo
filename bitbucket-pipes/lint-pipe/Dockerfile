# =============================================================================
# Lint Pipe - Docker Image
# =============================================================================
# Language-agnostic image with package managers for on-demand tool installation
FROM alpine:3.18

# Metadata
LABEL maintainer="nayaksuraj"
LABEL description="Bitbucket Pipe for linting, formatting, and type checking"
LABEL version="1.0.0"

# Install base dependencies and package managers
RUN apk add --no-cache \
    bash \
    git \
    curl \
    ca-certificates \
    python3 \
    py3-pip \
    nodejs \
    npm \
    go

# Copy pipe files
COPY pipe.sh /pipe.sh
COPY pipe.yml /pipe.yml

# Make script executable
RUN chmod +x /pipe.sh

# Set working directory
WORKDIR /workspace

# Default entrypoint
ENTRYPOINT ["/pipe.sh"]
