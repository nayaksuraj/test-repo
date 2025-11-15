# =============================================================================
# Slack Notification Pipe - Docker Image
# =============================================================================
FROM alpine:3.18

# Metadata
LABEL maintainer="nayaksuraj"
LABEL description="Bitbucket Pipe for sending rich Slack notifications"
LABEL version="1.0.0"

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    ca-certificates \
    git

# Copy pipe files
COPY pipe.sh /pipe.sh
COPY pipe.yml /pipe.yml

# Make script executable
RUN chmod +x /pipe.sh

# Set working directory
WORKDIR /workspace

# Default entrypoint
ENTRYPOINT ["/pipe.sh"]
