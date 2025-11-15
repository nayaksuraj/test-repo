# =============================================================================
# Security Pipe - Comprehensive Security Scanning
# =============================================================================
# Production-ready image with GitLeaks, Trivy, Grype, Syft, Checkov,
# Hadolint, Bandit, OWASP Dependency-Check, and CycloneDX
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
    gnupg \
    software-properties-common \
    build-essential \
    bc \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Docker CLI (for container scanning)
# =============================================================================
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Java (for OWASP Dependency-Check)
# =============================================================================
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Install Maven (for dependency scanning)
ENV MAVEN_VERSION=3.9.5
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | \
    tar xzf - -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven
ENV PATH=/opt/maven/bin:$PATH

# Install Gradle (for dependency scanning)
ENV GRADLE_VERSION=8.5
RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle.zip && \
    unzip gradle.zip -d /opt && \
    rm gradle.zip && \
    ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle
ENV PATH=/opt/gradle/bin:$PATH

# =============================================================================
# Install Node.js (for npm audit)
# =============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Python + Bandit (SAST for Python)
# =============================================================================
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    pip3 install --no-cache-dir \
        bandit==1.7.6 \
        safety

# =============================================================================
# Install Checkov (IaC Scanning)
# =============================================================================
RUN pip3 install --no-cache-dir checkov==3.1.0

# =============================================================================
# Install GitLeaks (Secrets Detection)
# =============================================================================
ENV GITLEAKS_VERSION=8.18.1
RUN curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz | \
    tar -xz -C /usr/local/bin gitleaks && \
    chmod +x /usr/local/bin/gitleaks

# =============================================================================
# Install Trivy (Container/IaC/Filesystem Scanning)
# =============================================================================
ENV TRIVY_VERSION=0.48.0
RUN curl -fsSL https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz | \
    tar -xz -C /usr/local/bin trivy && \
    chmod +x /usr/local/bin/trivy

# =============================================================================
# Install Hadolint (Dockerfile Linter)
# =============================================================================
ENV HADOLINT_VERSION=2.12.0
RUN curl -fsSL https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64 \
    -o /usr/local/bin/hadolint && \
    chmod +x /usr/local/bin/hadolint

# =============================================================================
# Install Syft (SBOM Generation)
# =============================================================================
ENV SYFT_VERSION=0.100.0
RUN curl -fsSL https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz | \
    tar -xz -C /usr/local/bin syft && \
    chmod +x /usr/local/bin/syft

# =============================================================================
# Install Grype (Vulnerability Scanning)
# =============================================================================
ENV GRYPE_VERSION=0.74.0
RUN curl -fsSL https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz | \
    tar -xz -C /usr/local/bin grype && \
    chmod +x /usr/local/bin/grype

# =============================================================================
# Install OWASP Dependency-Check
# =============================================================================
ENV DEPENDENCY_CHECK_VERSION=9.0.7
RUN curl -fsSL https://github.com/jeremylong/DependencyCheck/releases/download/v${DEPENDENCY_CHECK_VERSION}/dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip \
    -o dependency-check.zip && \
    unzip dependency-check.zip -d /opt && \
    rm dependency-check.zip && \
    ln -s /opt/dependency-check /opt/owasp-dependency-check
ENV PATH=/opt/owasp-dependency-check/bin:$PATH

# =============================================================================
# Install CycloneDX CLI (SBOM Format Conversion)
# =============================================================================
RUN npm install -g @cyclonedx/cyclonedx-npm

# =============================================================================
# Create Security Reports Directory
# =============================================================================
RUN mkdir -p /work/security-reports

# =============================================================================
# Copy and Setup Pipe
# =============================================================================
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

WORKDIR /work

ENTRYPOINT ["/pipe.sh"]
