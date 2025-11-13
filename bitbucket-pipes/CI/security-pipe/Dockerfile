FROM alpine:3.19

LABEL maintainer="nayaksuraj"
LABEL description="Comprehensive security scanning pipe for shift-left security"

# Install base dependencies
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    jq \
    git \
    ca-certificates \
    openjdk11-jre \
    python3 \
    py3-pip \
    nodejs \
    npm \
    unzip \
    tar \
    docker-cli \
    bc

# Install Maven (for OWASP Dependency-Check)
RUN wget -q https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz && \
    tar -xzf apache-maven-3.9.5-bin.tar.gz -C /opt && \
    ln -s /opt/apache-maven-3.9.5 /opt/maven && \
    rm apache-maven-3.9.5-bin.tar.gz

# Install Gradle
RUN wget -q https://services.gradle.org/distributions/gradle-8.5-bin.zip && \
    unzip -q gradle-8.5-bin.zip -d /opt && \
    ln -s /opt/gradle-8.5 /opt/gradle && \
    rm gradle-8.5-bin.zip

# Set environment variables
ENV PATH="/opt/maven/bin:/opt/gradle/bin:${PATH}"
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk"

# Install Checkov (IaC scanning)
RUN pip3 install --no-cache-dir \
    checkov==3.1.0 \
    bandit==1.7.6

# Install Trivy (Container/IaC scanning)
RUN wget -q https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz && \
    tar -xzf trivy_0.48.0_Linux-64bit.tar.gz && \
    mv trivy /usr/local/bin/ && \
    rm trivy_0.48.0_Linux-64bit.tar.gz

# Install Hadolint (Dockerfile scanning)
RUN wget -q https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 && \
    chmod +x hadolint-Linux-x86_64 && \
    mv hadolint-Linux-x86_64 /usr/local/bin/hadolint

# Install Syft (SBOM generation)
RUN wget -q https://github.com/anchore/syft/releases/download/v0.100.0/syft_0.100.0_linux_amd64.tar.gz && \
    tar -xzf syft_0.100.0_linux_amd64.tar.gz && \
    mv syft /usr/local/bin/ && \
    rm syft_0.100.0_linux_amd64.tar.gz

# Install Grype (Vulnerability scanning)
RUN wget -q https://github.com/anchore/grype/releases/download/v0.74.0/grype_0.74.0_linux_amd64.tar.gz && \
    tar -xzf grype_0.74.0_linux_amd64.tar.gz && \
    mv grype /usr/local/bin/ && \
    rm grype_0.74.0_linux_amd64.tar.gz

# Create security reports directory
RUN mkdir -p /work/security-reports

# Create working directory
WORKDIR /work

# Copy pipe script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

ENTRYPOINT ["/pipe.sh"]
