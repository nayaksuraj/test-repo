# =============================================================================
# Test Pipe - Multi-Language Test Execution
# =============================================================================
# Production-ready image with testing tools for Maven, Gradle, npm, Python,
# Go, .NET, PHP, Ruby, Rust + Docker for TestContainers
# =============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# =============================================================================
# Install Base Tools + Docker (for TestContainers)
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
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (for TestContainers support)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Java + Maven + Gradle
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
# Install Node.js + npm + yarn
# =============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest yarn jest mocha && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Python + pytest
# =============================================================================
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    && rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    pip3 install --no-cache-dir \
        pytest \
        pytest-cov \
        pytest-xdist \
        pytest-html \
        coverage \
        unittest-xml-reporting

# =============================================================================
# Install Go
# =============================================================================
ENV GO_VERSION=1.21.5
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | \
    tar -C /usr/local -xzf -
ENV PATH=/usr/local/go/bin:$PATH
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:$PATH

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
# Install PHP + PHPUnit
# =============================================================================
RUN apt-get update && apt-get install -y \
    php \
    php-cli \
    php-mbstring \
    php-xml \
    php-curl \
    composer \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install Ruby + RSpec
# =============================================================================
RUN apt-get update && apt-get install -y \
    ruby-full \
    && rm -rf /var/lib/apt/lists/* && \
    gem install rspec bundler

# =============================================================================
# Install Rust + Cargo
# =============================================================================
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH=/root/.cargo/bin:$PATH

# =============================================================================
# Copy and Setup Pipe
# =============================================================================
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

WORKDIR /work

ENTRYPOINT ["/pipe.sh"]
