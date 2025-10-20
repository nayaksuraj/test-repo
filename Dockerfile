# ==============================================================================
# Multi-Stage Dockerfile for Spring Boot Applications
# ==============================================================================
# This Dockerfile follows industry best practices:
# - Multi-stage builds for minimal image size
# - Non-root user for security
# - Health checks for container orchestration
# - Layer caching optimization
# - Distroless/minimal base images
# ==============================================================================

# ==============================================================================
# Stage 1: Build Stage
# ==============================================================================
FROM maven:3.8.6-openjdk-17-slim AS build

# Set working directory
WORKDIR /app

# Copy dependency files first for better layer caching
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .

# Download dependencies (this layer will be cached if pom.xml doesn't change)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
# Skip tests here as they should be run in CI pipeline
RUN mvn clean package -DskipTests -B

# ==============================================================================
# Stage 2: Runtime Stage
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

# Copy the JAR from build stage
COPY --from=build /app/target/*.jar app.jar

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
