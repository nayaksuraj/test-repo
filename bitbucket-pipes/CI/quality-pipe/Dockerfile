FROM alpine:3.19

LABEL maintainer="nayaksuraj"
LABEL description="Generic code quality and analysis pipe for multiple languages"

# Install base dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    git \
    ca-certificates \
    openjdk11-jre \
    nodejs \
    npm \
    python3 \
    py3-pip \
    xmlstarlet \
    bc

# Install Maven
RUN wget -q https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz && \
    tar -xzf apache-maven-3.9.5-bin.tar.gz -C /opt && \
    ln -s /opt/apache-maven-3.9.5 /opt/maven && \
    rm apache-maven-3.9.5-bin.tar.gz

# Install Gradle
RUN wget -q https://services.gradle.org/distributions/gradle-8.5-bin.zip && \
    unzip -q gradle-8.5-bin.zip -d /opt && \
    ln -s /opt/gradle-8.5 /opt/gradle && \
    rm gradle-8.5-bin.zip

# Install SonarScanner CLI
RUN wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip && \
    unzip -q sonar-scanner-cli-5.0.1.3006-linux.zip -d /opt && \
    ln -s /opt/sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner && \
    rm sonar-scanner-cli-5.0.1.3006-linux.zip

# Set environment variables
ENV PATH="/opt/maven/bin:/opt/gradle/bin:/opt/sonar-scanner/bin:${PATH}"
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk"

# Install quality tools
RUN pip3 install --no-cache-dir \
    pylint \
    flake8 \
    mypy \
    black \
    bandit

RUN npm install -g \
    eslint \
    prettier \
    jshint

# Create working directory
WORKDIR /work

# Copy pipe script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

ENTRYPOINT ["/pipe.sh"]
