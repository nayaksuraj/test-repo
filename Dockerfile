# ==============================================================================
# Optimized Dockerfile for Spring Boot Applications
# ==============================================================================
# This Dockerfile follows industry best practices:
# - Uses pre-built artifacts (no duplicate builds)
# - Minimal runtime image size
# - Non-root user for security
# - Health checks for container orchestration
# ==============================================================================
# IMPORTANT: This Dockerfile expects a pre-built JAR file in target/ directory
# The JAR is built once in the CI pipeline to avoid duplication
# ==============================================================================

# ==============================================================================
# Runtime Stage (Single stage - artifact already built)
# ==============================================================================
FROM eclipse-temurin:17-jre-alpine

# Metadata labels (OCI standard)
LABEL maintainer="your-team@example.com"
LABEL org.opencontainers.image.source="https://bitbucket.org/your-org/your-repo"
LABEL org.opencontainers.image.description="Spring Boot Application"
LABEL org.opencontainers.image.licenses="MIT"

# Install curl for health checks and debugging
RUN apk add --no-cache curl

# Create a non-root user for running the application
RUN addgroup -g 1001 -S appuser && \
    adduser -u 1001 -S appuser -G appuser

# Set working directory
WORKDIR /app

# Copy the pre-built JAR from CI pipeline artifacts
# This JAR was already built in the package.sh script
COPY target/*.jar app.jar

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose the application port (Spring Boot default)
EXPOSE 8080

# Health check (using Spring Boot Actuator health endpoint)
# Adjust the interval and timeout based on your application needs
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# JVM tuning for containerized environments
# -XX:+UseContainerSupport: Respect container memory limits
# -XX:MaxRAMPercentage: Use up to 75% of container memory
# -XX:+ExitOnOutOfMemoryError: Exit on OOM to allow container restart
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:+ExitOnOutOfMemoryError \
               -Djava.security.egd=file:/dev/./urandom"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
