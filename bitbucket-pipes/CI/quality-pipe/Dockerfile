# =============================================================================
# Quality Pipe - Code Quality & Static Analysis
# =============================================================================
# Production-ready image with SonarQube, linters, and analysis tools
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
    gnupg \
    software-properties-common \
    build-essential \
    xmlstarlet \
    bc \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Java (for Maven/Gradle/SonarQube)
# =============================================================================
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Install Maven
ENV MAVEN_VERSION=3.9.5
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | \
    tar xzf - -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven
ENV PATH=/opt/maven/bin:$PATH

# Install Gradle
ENV GRADLE_VERSION=8.5
RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle.zip && \
    unzip gradle.zip -d /opt && \
    rm gradle.zip && \
    ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle
ENV PATH=/opt/gradle/bin:$PATH

# =============================================================================
# Install SonarScanner CLI
# =============================================================================
ENV SONAR_SCANNER_VERSION=5.0.1.3006
RUN curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip -o sonar-scanner.zip && \
    unzip sonar-scanner.zip -d /opt && \
    rm sonar-scanner.zip && \
    ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux /opt/sonar-scanner
ENV PATH=/opt/sonar-scanner/bin:$PATH

# =============================================================================
# Install Node.js + JavaScript Linters
# =============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    npm install -g \
        eslint \
        prettier \
        jshint \
        tslint \
        stylelint \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Python + Python Quality Tools
# =============================================================================
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    pip3 install --no-cache-dir \
        pylint \
        flake8 \
        mypy \
        black \
        bandit \
        coverage \
        radon

# =============================================================================
# Install Go + Go Quality Tools
# =============================================================================
ENV GO_VERSION=1.21.5
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | \
    tar -C /usr/local -xzf -
ENV PATH=/usr/local/go/bin:$PATH
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:$PATH

# Install Go linters
RUN go install golang.org/x/lint/golint@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest

# =============================================================================
# Install .NET SDK
# =============================================================================
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Java Quality Tools
# =============================================================================
# These will be downloaded by Maven/Gradle plugins during execution:
# - Checkstyle (via maven-checkstyle-plugin)
# - SpotBugs (via spotbugs-maven-plugin)
# - PMD (via maven-pmd-plugin)
# - JaCoCo (via jacoco-maven-plugin)

# =============================================================================
# Copy and Setup Pipe
# =============================================================================
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

WORKDIR /work

ENTRYPOINT ["/pipe.sh"]
