FROM python:3.11-alpine

# Install dependencies
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    git

# Install Python packages for email and templating
RUN pip install --no-cache-dir \
    requests \
    jinja2

# Copy pipe script
COPY pipe.sh /pipe.sh
RUN chmod +x /pipe.sh

# Set working directory
WORKDIR /work

# Run the pipe
ENTRYPOINT ["/pipe.sh"]
