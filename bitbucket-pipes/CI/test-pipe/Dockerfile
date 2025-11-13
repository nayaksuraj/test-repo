FROM alpine:3.19

LABEL maintainer="nayaksuraj"
LABEL description="Generic test execution pipe for multiple frameworks"

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
    go \
    dotnet8-sdk

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

# Set environment variables
ENV PATH="/opt/maven/bin:/opt/gradle/bin:${PATH}"
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk"

# Install common test tools
RUN pip3 install --no-cache-dir pytest pytest-cov unittest-xml-reporting

# Create working directory
WORKDIR /work

# Copy pipe script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

ENTRYPOINT ["/pipe.sh"]
