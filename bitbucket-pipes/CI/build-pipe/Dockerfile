# =============================================================================
# Build Pipe - Generic Application Builder
# =============================================================================
# Supports: Maven, Gradle, npm, Python, Go, .NET, and more
# Usage: pipe: docker://nayaksuraj/build-pipe:1.0.0
# =============================================================================

FROM alpine:3.19

# Install common build tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    ca-certificates \
    jq

# Install build tool detection script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

# Set working directory
WORKDIR /work

# Run the pipe
ENTRYPOINT ["/pipe.sh"]
