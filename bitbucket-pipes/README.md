# Bitbucket Pipes - Reusable CI/CD Components

Production-ready, reusable Bitbucket Pipes for building, testing, securing, and deploying applications. These pipes work like GitHub Composite Actions but are implemented as Docker containers.

## 📦 Available Pipes

### CI Pipes (Continuous Integration)

| Pipe | Purpose | Version | Status |
|------|---------|---------|--------|
| [build-pipe](./CI/build-pipe/) | Build applications (Maven, Gradle, npm, Python, Go, .NET, Rust) | 1.0.0 | ✅ Ready |
| [test-pipe](./CI/test-pipe/) | Run unit & integration tests with coverage | 1.0.0 | ✅ Ready |
| [quality-pipe](./CI/quality-pipe/) | Code quality analysis (SonarQube, linting, coverage) | 1.0.0 | ✅ Ready |
| [security-pipe](./CI/security-pipe/) | Security scanning (secrets, SCA, SAST, SBOM, IaC) | 1.0.0 | ✅ Ready |

### CD Pipes (Continuous Deployment)

| Pipe | Purpose | Version | Status |
|------|---------|---------|--------|
| [docker-pipe](./CD/docker-pipe/) | Build, scan, and push Docker images | 1.0.0 | ✅ Ready |
| [helm-pipe](./CD/helm-pipe/) | Lint, package, and push Helm charts | 1.0.0 | ✅ Ready |
| [deploy-pipe](./CD/deploy-pipe/) | Deploy to Kubernetes (dev/stage/prod) | 1.0.0 | ✅ Ready |

### Notification Pipes

| Pipe | Purpose | Version | Status |
|------|---------|---------|--------|
| [slack-pipe](./slack-pipe/) | Send rich Slack notifications with deployment status | 1.0.0 | ✅ Ready |

## 🚀 Quick Start

### Simple Pipeline with Pipes

```yaml
image: alpine:3.19

pipelines:
  default:
    # CI - Build & Test
    - pipe: docker://nayaksuraj/build-pipe:1.0.0
    - pipe: docker://nayaksuraj/test-pipe:1.0.0
      variables:
        COVERAGE_ENABLED: "true"

    # CI - Quality & Security
    - parallel:
        - pipe: docker://nayaksuraj/quality-pipe:1.0.0
          variables:
            SONAR_ENABLED: "true"
            SONAR_TOKEN: $SONAR_TOKEN
        - pipe: docker://nayaksuraj/security-pipe:1.0.0
          variables:
            SECRETS_SCAN: "true"
            SCA_SCAN: "true"
            SBOM_GENERATE: "true"

    # CD - Build & Deploy
    - pipe: docker://nayaksuraj/docker-pipe:1.0.0
      variables:
        DOCKER_REGISTRY: $DOCKER_REGISTRY
        DOCKER_USERNAME: $DOCKER_USERNAME
        DOCKER_PASSWORD: $DOCKER_PASSWORD
        SCAN_IMAGE: "true"

    - pipe: docker://nayaksuraj/helm-pipe:1.0.0
      variables:
        LINT_CHART: "true"
        PACKAGE_CHART: "true"

    - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
      variables:
        ENVIRONMENT: "dev"
        KUBECONFIG: $KUBECONFIG

    # Notify - Slack notification
    - pipe: docker://nayaksuraj/slack-pipe:1.0.0
      variables:
        SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
        MESSAGE: "✅ Deployed to dev successfully"
        ENVIRONMENT: "dev"
        STATUS: "success"
```

## 📚 Documentation

Each pipe has comprehensive documentation:

- **README.md** - Complete usage guide with examples
- **pipe.yml** - All configurable variables and defaults
- **Dockerfile** - Container specification
- **pipe.sh** - Implementation source code

## 🏗️ Building and Publishing Pipes

### Build a Single Pipe

```bash
cd bitbucket-pipes/CI/build-pipe
docker build -t nayaksuraj/build-pipe:1.0.0 .
docker push nayaksuraj/build-pipe:1.0.0
```

### Build All Pipes

```bash
# CI Pipes
docker build -t nayaksuraj/build-pipe:1.0.0 bitbucket-pipes/CI/build-pipe
docker build -t nayaksuraj/test-pipe:1.0.0 bitbucket-pipes/CI/test-pipe
docker build -t nayaksuraj/quality-pipe:1.0.0 bitbucket-pipes/CI/quality-pipe
docker build -t nayaksuraj/security-pipe:1.0.0 bitbucket-pipes/CI/security-pipe

# CD Pipes
docker build -t nayaksuraj/docker-pipe:1.0.0 bitbucket-pipes/CD/docker-pipe
docker build -t nayaksuraj/helm-pipe:1.0.0 bitbucket-pipes/CD/helm-pipe
docker build -t nayaksuraj/deploy-pipe:1.0.0 bitbucket-pipes/CD/deploy-pipe

# Push all
docker push nayaksuraj/build-pipe:1.0.0
docker push nayaksuraj/test-pipe:1.0.0
docker push nayaksuraj/quality-pipe:1.0.0
docker push nayaksuraj/security-pipe:1.0.0
docker push nayaksuraj/docker-pipe:1.0.0
docker push nayaksuraj/helm-pipe:1.0.0
docker push nayaksuraj/deploy-pipe:1.0.0
```

### Use Latest Tag

```bash
# Tag as latest
docker tag nayaksuraj/build-pipe:1.0.0 nayaksuraj/build-pipe:latest
docker push nayaksuraj/build-pipe:latest
```

## 🎯 Use Cases

### Java Spring Boot Application

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_TOOL: "maven"
    BUILD_ARGS: "-DskipTests"

- pipe: docker://nayaksuraj/test-pipe:1.0.0
  variables:
    TEST_TOOL: "maven"
    INTEGRATION_TESTS: "true"
```

### Node.js Application

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_COMMAND: "npm ci && npm run build"

- pipe: docker://nayaksuraj/test-pipe:1.0.0
  variables:
    TEST_COMMAND: "npm test"
    COVERAGE_ENABLED: "true"
```

### Python Application

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_TOOL: "python"

- pipe: docker://nayaksuraj/test-pipe:1.0.0
  variables:
    TEST_TOOL: "pytest"
    TEST_ARGS: "--cov=src --cov-report=xml"
```

### Go Application

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_TOOL: "go"

- pipe: docker://nayaksuraj/test-pipe:1.0.0
  variables:
    TEST_TOOL: "go"
    COVERAGE_ENABLED: "true"
```

## 🔐 Security Scanning

### Complete Security Pipeline

```yaml
- pipe: docker://nayaksuraj/security-pipe:1.0.0
  variables:
    SECRETS_SCAN: "true"          # GitLeaks
    SCA_SCAN: "true"              # Dependency vulnerabilities
    SAST_SCAN: "true"             # Static analysis
    SBOM_GENERATE: "true"         # Software Bill of Materials
    IAC_SCAN: "true"              # Kubernetes/Helm security
    DOCKERFILE_SCAN: "true"       # Dockerfile best practices
    CONTAINER_SCAN: "true"        # Container image vulnerabilities
    FAIL_ON_HIGH: "true"          # Fail on HIGH/CRITICAL
```

## 🚢 Multi-Environment Deployment

### Deploy to Dev (Auto)

```yaml
branches:
  develop:
    - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
      variables:
        ENVIRONMENT: "dev"
        NAMESPACE: "dev"
        KUBECONFIG: $DEV_KUBECONFIG
```

### Deploy to Staging (Manual)

```yaml
branches:
  main:
    - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
      variables:
        ENVIRONMENT: "stage"
        NAMESPACE: "staging"
        KUBECONFIG: $STAGE_KUBECONFIG
      trigger: manual
```

### Deploy to Production (Manual with Approval)

```yaml
branches:
  release:
    - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
      variables:
        ENVIRONMENT: "prod"
        NAMESPACE: "production"
        KUBECONFIG: $PROD_KUBECONFIG
        WAIT_FOR_ROLLOUT: "true"
        ROLLOUT_TIMEOUT: "600"
      trigger: manual
```

## 🔄 Comparison with GitHub Actions

| Feature | GitHub Actions | Bitbucket Pipes |
|---------|----------------|-----------------|
| **Implementation** | YAML Composite Actions | Docker Containers |
| **Reusability** | `.github/actions/` | Docker Registry |
| **Versioning** | Git tags | Docker image tags |
| **Language** | YAML + shell | Any language |
| **Marketplace** | Large (1000s) | Smaller |
| **Isolation** | Process | Container |

## ✨ Features

All pipes include:

- ✅ **Generic**: Work with multiple languages/frameworks
- ✅ **Auto-detection**: Automatically detect build tools
- ✅ **Colored Output**: Visual feedback (🟢🟡🔴)
- ✅ **Debug Mode**: Verbose output for troubleshooting
- ✅ **Error Handling**: Proper exit codes and messages
- ✅ **Cloud-Agnostic**: Works with any cloud provider
- ✅ **Production-Ready**: Enterprise-grade quality
- ✅ **Well-Documented**: Comprehensive README files

## 📊 Statistics

- **Total Pipes**: 7 (4 CI + 3 CD)
- **Total Lines of Code**: ~4,500 lines
- **Total Documentation**: ~3,500 lines
- **Supported Languages**: 10+ (Java, Node.js, Python, Go, .NET, Rust, Ruby, PHP, etc.)
- **Container Size**: 100-500 MB per pipe (optimized Alpine-based)

## 🛠️ Development

### Local Testing

Test a pipe locally before publishing:

```bash
cd bitbucket-pipes/CI/build-pipe
docker build -t test-build-pipe .

# Test with Maven project
docker run --rm -v $(pwd)/test-project:/work test-build-pipe
```

### Continuous Improvement

Pipes are versioned using semantic versioning:
- `1.0.0` - Initial release
- `1.0.1` - Bug fixes
- `1.1.0` - New features (backward compatible)
- `2.0.0` - Breaking changes

## 📝 Contributing

To add a new pipe:

1. Create directory under `CI/` or `CD/`
2. Add required files: `Dockerfile`, `pipe.yml`, `pipe.sh`, `README.md`
3. Make `pipe.sh` executable: `chmod +x pipe.sh`
4. Test locally
5. Build and publish: `docker build -t nayaksuraj/[name]:1.0.0 .`
6. Update this README

## 📖 Additional Resources

- [Bitbucket Pipes Documentation](https://support.atlassian.com/bitbucket-cloud/docs/what-are-pipes/)
- [Write a Pipe](https://support.atlassian.com/bitbucket-cloud/docs/write-a-pipe-for-bitbucket-pipelines/)
- [Pipes Toolkit](https://bitbucket.org/atlassian/bitbucket-pipes-toolkit-python)
- [Official Pipes](https://bitbucket.org/product/features/pipelines/integrations)

## 📄 License

These pipes are part of the reusable Bitbucket Pipes collection and are provided as-is for demonstration and production use.

---

**Built with ❤️ for DevOps Teams**

For questions or issues, please open an issue in the repository.
