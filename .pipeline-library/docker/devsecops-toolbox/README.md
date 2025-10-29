# DevSecOps Toolbox Docker Image

All-in-one Docker image with pre-installed security scanning tools for DevSecOps pipelines.

## Tools Included

| Tool | Version | Purpose |
|------|---------|---------|
| GitLeaks | 8.18.0 | Secrets scanning |
| Trivy | 0.48.0 | Container & dependency scanning |
| Hadolint | 2.12.0 | Dockerfile linting |
| Checkov | 3.1.0 | IaC security scanning |
| Syft | 0.100.0 | SBOM generation |
| Grype | 0.74.0 | Vulnerability scanning |
| Helm | Latest | Kubernetes package management |
| Kubectl | Latest | Kubernetes CLI |
| Maven | 3.8.6 | Java build tool |
| JDK | 17 | Java runtime |

## Usage

### As Base Image

```dockerfile
FROM yourorg/devsecops-toolbox:1.0.0

# Your additional setup
COPY . /app
WORKDIR /app
```

### In Bitbucket Pipelines

```yaml
image: yourorg/devsecops-toolbox:1.0.0

pipelines:
  default:
    - step:
        name: Security Scans
        script:
          # All tools are pre-installed and in PATH
          - security-secrets-scan.sh
          - security-sca-scan.sh
          - security-dockerfile-scan.sh
          - security-sbom-generate.sh
```

### Run Locally

```bash
# Interactive shell
docker run -it --rm -v $(pwd):/workspace yourorg/devsecops-toolbox:1.0.0

# Run specific tool
docker run --rm -v $(pwd):/workspace yourorg/devsecops-toolbox:1.0.0 gitleaks detect --source . --verbose
```

## Building the Image

```bash
# Clone the pipeline library
git clone https://bitbucket.org/yourorg/bitbucket-pipeline-library.git
cd bitbucket-pipeline-library/docker/devsecops-toolbox

# Build
docker build -t yourorg/devsecops-toolbox:1.0.0 .

# Test
docker run --rm yourorg/devsecops-toolbox:1.0.0 gitleaks version

# Push to registry
docker push yourorg/devsecops-toolbox:1.0.0
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FAIL_ON_SECRETS` | `false` | Fail pipeline on secrets detection |
| `CVSS_THRESHOLD` | `7.0` | CVSS threshold for dependencies |
| `TRIVY_SEVERITY` | `CRITICAL,HIGH,MEDIUM` | Trivy severity levels |

## Examples

### Complete DevSecOps Pipeline

```yaml
image: yourorg/devsecops-toolbox:1.0.0

definitions:
  caches:
    maven: ~/.m2/repository

pipelines:
  default:
    # All security tools are pre-installed
    - step:
        name: 🔒 Security Scans
        caches:
          - maven
        script:
          - echo "Running security scans..."

          # Secrets scanning
          - export FAIL_ON_SECRETS=true
          - security-secrets-scan.sh

          # Dependency scanning
          - export CVSS_THRESHOLD=7.0
          - export FAIL_ON_CVSS=true
          - security-sca-scan.sh

          # Dockerfile scanning
          - security-dockerfile-scan.sh

          # SBOM generation
          - security-sbom-generate.sh

        artifacts:
          - security-reports/**

    - step:
        name: Build
        caches:
          - maven
        script:
          - mvn clean package

    - step:
        name: 🔒 Container Security
        services:
          - docker
        script:
          # Build container
          - docker build -t myapp:latest .

          # Scan container
          - trivy image myapp:latest

          # Generate container SBOM
          - syft myapp:latest -o cyclonedx-json > security-reports/container-sbom.json
```

### Multi-Stage Build with Security

```yaml
image: yourorg/devsecops-toolbox:1.0.0

pipelines:
  default:
    - parallel:
        - step:
            name: Secrets Scan
            script:
              - security-secrets-scan.sh

        - step:
            name: Dependency Scan
            caches:
              - maven
            script:
              - security-sca-scan.sh

        - step:
            name: Code Quality
            caches:
              - maven
            script:
              - mvn verify

    - step:
        name: Build & SBOM
        caches:
          - maven
        script:
          - mvn package
          - security-sbom-generate.sh
```

## Updating Tools

To update tool versions, modify the `ARG` statements in the Dockerfile:

```dockerfile
ARG GITLEAKS_VERSION=8.19.0  # Updated version
ARG TRIVY_VERSION=0.49.0     # Updated version
```

Then rebuild and push the image.

## Size Optimization

Current image size: ~800MB

To reduce size:
1. Use multi-stage build
2. Remove unnecessary tools
3. Use Alpine-based images where possible
4. Clean up apt cache

## Support

- Issues: https://bitbucket.org/yourorg/bitbucket-pipeline-library/issues
- Documentation: See main [README](../../README.md)

## License

MIT
