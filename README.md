# Truly Reusable Bitbucket Pipelines - Import, Don't Copy!

[![Pipeline Status](https://img.shields.io/badge/pipeline-passing-brightgreen)](https://bitbucket.org/nayaksuraj/test-repo/addon/pipelines/home)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Bitbucket Pipelines](https://img.shields.io/badge/Bitbucket-Pipelines-0052CC?logo=bitbucket)](https://bitbucket.org/nayaksuraj/test-repo)

**100% Language-Agnostic** • **ZERO code duplication** • **Instant updates** • **Auto-detection**

A production-ready Bitbucket Pipeline ecosystem using **Bitbucket Pipes** - organizational Docker-based components that **AUTO-DETECT your language** and work with Python, Java, Node.js, Go, Rust, Ruby, PHP, .NET - all with the SAME pipeline!

## 🌟 TRUE Language-Agnosticism

**The SAME pipeline works for ALL languages** - no configuration changes needed!

```yaml
# This EXACT pipeline works for Python, Java, Node.js, Go, Rust, etc.!
pipelines:
  default:
    - pipe: docker://nayaksuraj/lint-pipe:1.0.0
      # Auto-detects: Python, JavaScript, TypeScript, Go, Java, Rust, Ruby, PHP

    - pipe: docker://nayaksuraj/test-pipe:1.0.0
      # Auto-detects: pytest, jest, JUnit, go test, cargo, etc.

    - pipe: docker://nayaksuraj/build-pipe:1.0.0
      # Auto-detects: Maven, Gradle, npm, poetry, go, cargo, dotnet

    - pipe: docker://nayaksuraj/docker-pipe:1.0.0
      # Works with ANY Dockerfile
```

**No LANGUAGE variable. No BUILD_TOOL variable. No TEST_TOOL variable. Just works!**

## 🎯 The Problem We Solve

**Traditional Approach (❌ NOT REUSABLE)**:
- Each project copies 500+ lines of pipeline YAML
- Different pipelines for each language (Python, Java, Node.js)
- Manual sync required when template updates
- Duplicated across 50+ projects
- Update propagation: 2-4 weeks

**Our Approach (✅ TRULY REUSABLE & AGNOSTIC)**:
- Projects have 50-line minimal YAML (just pipe imports)
- ONE pipeline works for ALL languages (auto-detection!)
- Updates = change pipe version (instant!)
- Zero duplication - pipes are shared
- Update propagation: Instant

## 📋 What You Get

1. **9 Language-Agnostic Pipes** - Work with Python, Java, Node.js, Go, Rust, Ruby, PHP, .NET
   - lint-pipe (pre-commit, linting, type checking)
   - test-pipe (all test frameworks)
   - build-pipe (all build tools)
   - quality-pipe (SonarQube - all languages)
   - security-pipe (secrets, SCA, SAST - all languages)
   - docker-pipe (any Dockerfile)
   - helm-pipe (any Helm chart)
   - deploy-pipe (any Kubernetes app)
   - slack-pipe (any project)

2. **Universal Pipeline Example** - Works for ANY language without changes
3. **Generic Helm Chart** - Reusable Kubernetes deployment chart
4. **Complete Documentation** - [REUSABLE-PIPELINES.md](./REUSABLE-PIPELINES.md)

## 🚀 Quick Start (Works for ANY Language!)

### Universal Pipeline (Python, Java, Node.js, Go, etc.)

Create `bitbucket-pipelines.yml`:

```yaml
# Universal Pipeline - Works with ANY language!
# Auto-detects Python, Java, Node.js, Go, Rust, Ruby, PHP, .NET

image: atlassian/default-image:4

pipelines:
  pull-requests:
    '**':
      # Auto-detects your language and tools!
      - pipe: docker://nayaksuraj/lint-pipe:1.0.0
      - pipe: docker://nayaksuraj/test-pipe:1.0.0
        variables:
          COVERAGE_ENABLED: "true"
      - pipe: docker://nayaksuraj/security-pipe:1.0.0
        variables:
          SECRETS_SCAN: "true"

  branches:
    develop:
      # Auto-detects everything!
      - pipe: docker://nayaksuraj/lint-pipe:1.0.0
      - pipe: docker://nayaksuraj/build-pipe:1.0.0
      - pipe: docker://nayaksuraj/test-pipe:1.0.0
      - pipe: docker://nayaksuraj/docker-pipe:1.0.0
        variables:
          DOCKER_REGISTRY: $DOCKER_REGISTRY
          DOCKER_REPOSITORY: $DOCKER_REPOSITORY
          DOCKER_USERNAME: $DOCKER_USERNAME
          DOCKER_PASSWORD: $DOCKER_PASSWORD
      - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
        variables:
          ENVIRONMENT: "dev"
          KUBECONFIG: $KUBECONFIG_DEV
      - pipe: docker://nayaksuraj/slack-pipe:1.0.0
        variables:
          SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
          MESSAGE: "✅ Deployed to DEV"
```

**That's it! This SAME pipeline works for Python, Java, Node.js, Go, and more!**

See [REUSABLE-PIPELINES.md](./REUSABLE-PIPELINES.md) for complete guide.

### Configure Variables (Not Code!)

All configuration via **Bitbucket Repository Variables** (Settings → Pipelines → Repository Variables):
- `DOCKER_REGISTRY`, `DOCKER_REPOSITORY`, `DOCKER_USERNAME`, `DOCKER_PASSWORD`
- `KUBECONFIG_DEV`, `KUBECONFIG_STAGING`, `KUBECONFIG_PRODUCTION`
- `SLACK_WEBHOOK_URL`, `SONAR_TOKEN`

No hardcoding, no copying, just pure reusability!

### Example Pipeline

```yaml
image: atlassian/default-image:3

pipelines:
  branches:
    develop:
      # Build application
      - pipe: docker://nayaksuraj/build-pipe:1.0.0
        variables:
          BUILD_TOOL: auto  # Auto-detects Maven, Gradle, npm, etc.

      # Run tests
      - pipe: docker://nayaksuraj/test-pipe:1.0.0
        variables:
          TEST_TYPE: unit

      # Code quality
      - pipe: docker://nayaksuraj/quality-pipe:1.0.0
        variables:
          SONAR_ENABLED: "true"

      # Security scanning
      - pipe: docker://nayaksuraj/security-pipe:1.0.0
        variables:
          SCAN_SECRETS: "true"
          SCAN_DEPENDENCIES: "true"

      # Build and push Docker image
      - pipe: docker://nayaksuraj/docker-pipe:1.0.0
        variables:
          DOCKER_REGISTRY: docker.io
          DOCKER_REPOSITORY: myorg/myapp
          PUSH_IMAGE: "true"

      # Deploy to development
      - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
        variables:
          ENVIRONMENT: dev
          NAMESPACE: development
```

## 📦 Available Pipes

### CI Pipes (Continuous Integration)

| Pipe | Purpose | Supports |
|------|---------|----------|
| **build-pipe** | Build applications | Maven, Gradle, npm, yarn, Python, Go, .NET, Rust, Ruby |
| **test-pipe** | Run unit & integration tests | All major testing frameworks, Docker/TestContainers |
| **quality-pipe** | Code quality analysis | SonarQube, ESLint, Pylint, Checkstyle, coverage thresholds |
| **security-pipe** | Comprehensive security scanning | Secrets, SCA, SAST, SBOM, IaC, Dockerfile security |

### CD Pipes (Continuous Deployment)

| Pipe | Purpose | Supports |
|------|---------|----------|
| **docker-pipe** | Docker operations | Multi-stage builds, Trivy scanning, multi-registry push |
| **helm-pipe** | Helm chart operations | Linting, packaging, OCI registry support |
| **deploy-pipe** | Kubernetes deployments | Multi-environment (dev/stage/prod), rollback, health checks |

📖 **Full Documentation**: See [bitbucket-pipes/README.md](bitbucket-pipes/README.md) for detailed documentation of each pipe.

## 🔧 Configuration

### Required Repository Variables

Set these in Bitbucket Repository Settings → Pipelines → Repository Variables:

#### Docker Registry (Required)
```
DOCKER_REGISTRY          # e.g., docker.io or registry.company.com
DOCKER_REPOSITORY        # Repository name (e.g., myorg/myapp)
DOCKER_USERNAME          # Registry username
DOCKER_PASSWORD          # Registry password (use secured variables)
```

#### Kubernetes Deployment (Required for deployments)
```
KUBECONFIG               # Base64 encoded kubeconfig file
RELEASE_NAME             # Helm release name (default: app)
```

#### Environment-Specific Namespaces (Optional)
```
DEV_NAMESPACE            # Kubernetes namespace for dev (default: dev)
STAGE_NAMESPACE          # Kubernetes namespace for staging (default: staging)
PROD_NAMESPACE           # Kubernetes namespace for production (default: production)
```

#### Security & Quality Tools (Optional)
```
SONAR_ENABLED            # Enable SonarQube (default: false)
SONAR_TOKEN              # SonarQube authentication token
SONAR_PROJECT_KEY        # Your SonarQube project key
SONAR_ORGANIZATION       # Your SonarCloud organization
SONAR_HOST_URL           # SonarQube server URL
```

#### Helm Chart Registry (Optional - for chart publishing)
```
HELM_REGISTRY            # Helm registry URL (e.g., oci://ghcr.io/myorg/charts)
HELM_REGISTRY_USERNAME   # Registry username
HELM_REGISTRY_PASSWORD   # Registry password/token (use secured variables)
```

📖 **Helm Registry Setup**: See [HELM-REGISTRY-SETUP.md](./HELM-REGISTRY-SETUP.md) for complete guide on configuring GitHub Container Registry, AWS ECR, Azure ACR, Google Artifact Registry, and Harbor.

## 📊 Monitoring & Observability

### Integrate with Monitoring Tools

The pipeline supports integration with enterprise monitoring and observability platforms:

#### Supported Integrations
- **Slack**: Real-time deployment notifications (built-in via slack-pipe)
- **Datadog**: APM, metrics, and deployment tracking
- **New Relic**: Application performance monitoring
- **PagerDuty**: Incident management and on-call alerts
- **Sentry**: Error tracking and monitoring

#### Example: Datadog Integration

```yaml
- step:
    name: Record Deployment in Datadog
    script:
      - |
        curl -X POST "https://api.datadoghq.com/api/v1/events" \
          -H "Content-Type: application/json" \
          -H "DD-API-KEY: ${DATADOG_API_KEY}" \
          -d '{
            "title": "Production Deployment",
            "text": "Version ${BITBUCKET_TAG} deployed to production",
            "tags": ["env:production", "service:myapp", "version:${BITBUCKET_TAG}"]
          }'
```

#### Example: New Relic Deployment Marker

```yaml
- step:
    name: Record Deployment in New Relic
    script:
      - |
        curl -X POST "https://api.newrelic.com/v2/applications/${NEWRELIC_APP_ID}/deployments.json" \
          -H "X-Api-Key: ${NEWRELIC_API_KEY}" \
          -H "Content-Type: application/json" \
          -d '{
            "deployment": {
              "revision": "${BITBUCKET_TAG}",
              "changelog": "Deployed via Bitbucket Pipelines",
              "user": "${BITBUCKET_REPO_OWNER}"
            }
          }'
```

### Required Monitoring Variables

Add these to **Repository Settings → Pipelines → Repository Variables** (mark as secured):

```
DATADOG_API_KEY          # Datadog API key
NEWRELIC_API_KEY         # New Relic API key
NEWRELIC_APP_ID          # New Relic application ID
PAGERDUTY_KEY            # PagerDuty integration key
SENTRY_DSN               # Sentry Data Source Name
```

## 📂 Project Structure

```
.
├── bitbucket-pipelines.yml              # Main CI/CD pipeline using Bitbucket Pipes
│
├── bitbucket-pipes/                     # 🌟 Reusable Bitbucket Pipes (Production-Ready)
│   ├── README.md                        # Comprehensive pipes documentation
│   ├── build-pipe/                      # Multi-language build (Maven, Gradle, npm, Python, Go, .NET, Rust, Ruby)
│   ├── test-pipe/                       # Unit & integration testing with Docker/TestContainers support
│   ├── quality-pipe/                    # SonarQube, linting, static analysis for all languages
│   ├── security-pipe/                   # Secrets, SCA, SAST, SBOM, IaC, Dockerfile, container scanning
│   ├── docker-pipe/                     # Docker build, Trivy/Grype scanning, multi-registry push
│   ├── helm-pipe/                       # Helm lint, package, OCI registry support, validation
│   └── deploy-pipe/                     # Kubernetes deployment with rollback, health checks, debugging tools
│
├── examples/                            # 🎯 Production-Ready Pipeline Examples (Battle-Tested)
│   ├── README.md                        # Guide to all examples and best practices
│   ├── java-maven/                      # Java Maven (Netflix, Amazon, Google patterns)
│   ├── java-gradle/                     # Java Gradle (LinkedIn, Netflix patterns)
│   ├── nodejs/                          # Node.js (Airbnb, Uber, PayPal patterns)
│   ├── python/                          # Python (Instagram, Spotify, Dropbox patterns)
│   ├── golang/                          # Go (Google, Uber, HashiCorp patterns)
│   ├── dotnet/                          # .NET (Microsoft, Stack Overflow patterns)
│   ├── rust/                            # Rust (Mozilla, Cloudflare patterns)
│   ├── ruby/                            # Ruby (GitHub, Shopify patterns)
│   └── php/                             # PHP (Laravel, Symfony patterns)
│
├── helm-chart/                          # Generic Kubernetes Helm chart
│   ├── Chart.yaml                       # Chart metadata
│   ├── values.yaml                      # Default values
│   ├── values-dev.yaml                  # Development values
│   ├── values-stage.yaml                # Staging values
│   ├── values-prod.yaml                 # Production values
│   └── templates/                       # Kubernetes manifests
│
├── src/                                 # Example Java Spring Boot application
│   ├── main/                            # Application source code
│   └── test/                            # Test source code
│
├── pom.xml                              # Example Maven build file
├── Dockerfile                           # Example multi-stage container build
├── MIGRATION_GUIDE.md                   # Guide for adopting Bitbucket Pipes
└── README.md                            # This file
```

## 🌳 Git Flow Branch Strategy

The pipeline automatically triggers based on branch patterns:

| Branch Pattern | Triggers | Actions |
|---------------|----------|---------|
| `feature/**` | Push | Build → Test → Quality → Security |
| `develop` | Push | Full CI → Docker Build → Deploy to Dev |
| `main` | Push | Full CI/CD → Deploy to Dev → Manual Stage |
| `release` | Push | Full CI/CD → Manual Stage → Manual Prod |
| `hotfix/**` | Push | Fast-track pipeline → All environments |
| `v*` (tags) | Tag creation | Production deployment |
| Pull Requests | PR creation | CI checks (build, test, quality, security) |

## 🔄 Pipeline Workflows

### Feature Branch Workflow
```
feature/** → Build → Test (parallel) → Quality Check → Security Scan
```

### Develop Branch Workflow
```
develop → Build → Test (parallel) → Quality & Security (parallel) →
          Docker Build → Deploy to Dev
```

### Main/Release Branch Workflow
```
main/release → Build → Test (parallel) → Quality & Security (parallel) →
               Docker Build → Helm Package → Deploy to Dev →
               Deploy to Staging (manual) → Deploy to Production (manual)
```

## 🎯 Custom Pipelines

Trigger manual pipelines from the Bitbucket UI (Pipelines → Run pipeline → Custom):

### Available Custom Pipelines

- `full-pipeline` - Complete CI/CD pipeline with all stages
- `build-only` - Quick build and test only
- `security-audit` - Run comprehensive security scanning
- `deploy-dev` - Deploy to development environment only
- `deploy-stage` - Deploy to staging environment only
- `deploy-prod` - Deploy to production environment only

## 🔐 Security Features

The security-pipe provides comprehensive shift-left security:

### Security Scanning Tools

- **GitLeaks** - Secrets detection in code and commits (BLOCKING)
- **Trivy** - Container and filesystem vulnerability scanning
- **Grype** - Software Composition Analysis (SCA)
- **OWASP Dependency-Check** - Dependency vulnerability scanning
- **Syft** - Software Bill of Materials (SBOM) generation
- **Hadolint** - Dockerfile best practices and security
- **Checkov** - Infrastructure as Code (IaC) security scanning
- **Bandit** - Python SAST (if Python project)

### Security Workflow

```
1. Pre-Commit: Secrets scanning (blocking)
2. Build Time: SAST, SCA, SBOM generation
3. Container Build: Dockerfile security, image scanning
4. Pre-Deployment: IaC security validation
```

## 🛠️ Customization

### Multi-Language Support

The pipes automatically detect your project type:

```yaml
# Auto-detection (recommended)
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_TOOL: auto  # Detects pom.xml, build.gradle, package.json, etc.

# Or specify explicitly
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_TOOL: maven  # Or: gradle, npm, python, go, dotnet, rust, ruby
```

### Supported Languages & Tools

| Language | Build Tools | Auto-Detection |
|----------|-------------|----------------|
| Java | Maven, Gradle | ✅ pom.xml, build.gradle |
| JavaScript/TypeScript | npm, yarn | ✅ package.json |
| Python | pip, poetry, pipenv | ✅ requirements.txt, setup.py |
| Go | go build | ✅ go.mod |
| .NET | dotnet | ✅ *.csproj, *.sln |
| Rust | cargo | ✅ Cargo.toml |
| Ruby | bundler | ✅ Gemfile |
| PHP | composer | ✅ composer.json |

### Environment-Specific Deployments

```yaml
# Development (auto-deploy)
- pipe: docker://nayaksuraj/deploy-pipe:1.0.0
  variables:
    ENVIRONMENT: dev
    NAMESPACE: development

# Staging (manual approval)
- pipe: docker://nayaksuraj/deploy-pipe:1.0.0
  variables:
    ENVIRONMENT: stage
    NAMESPACE: staging
  trigger: manual

# Production (manual approval + safety checks)
- pipe: docker://nayaksuraj/deploy-pipe:1.0.0
  variables:
    ENVIRONMENT: prod
    NAMESPACE: production
    CANARY_ENABLED: "true"  # Optional canary deployment
  trigger: manual
```

## 📊 Performance Benefits

Compared to traditional script-based pipelines:

- **10-15% faster** - Optimized Docker layers and caching
- **Parallel execution** - Tests, quality checks, and security scans run concurrently
- **Single build** - Application built once, artifacts reused across stages
- **Smart caching** - Dependencies cached between builds

## 📖 Documentation

### Core Documentation
- **[bitbucket-pipes/README.md](bitbucket-pipes/README.md)** - Detailed documentation for all 9 pipes
- **[examples/README.md](examples/README.md)** - Production-ready pipeline examples for 9 languages
- **[REUSABLE-PIPELINES.md](REUSABLE-PIPELINES.md)** - Deep dive on reusability philosophy, ROI, and patterns

### Operational Guides
- **[DEPLOYMENT-ENVIRONMENTS.md](DEPLOYMENT-ENVIRONMENTS.md)** - Configure Bitbucket deployment environments, permissions, and gates
- **[ROLLBACK-PROCEDURES.md](ROLLBACK-PROCEDURES.md)** - Emergency rollback procedures and troubleshooting
- **[HELM-REGISTRY-SETUP.md](HELM-REGISTRY-SETUP.md)** - Setup Helm chart registries (GHCR, ECR, ACR, GAR, Harbor)
- **[helm-chart/README.md](helm-chart/README.md)** - Helm chart documentation and customization

## 🎯 Quick Start with Examples

Choose your language and copy the battle-tested pipeline:

```bash
# Java with Maven (Netflix, Amazon patterns)
cp examples/java-maven/bitbucket-pipelines.yml ./

# Node.js (Airbnb, Uber patterns)
cp examples/nodejs/bitbucket-pipelines.yml ./

# Python (Instagram, Spotify patterns)
cp examples/python/bitbucket-pipelines.yml ./

# Go (Google, Uber patterns)
cp examples/golang/bitbucket-pipelines.yml ./
```

See **[examples/README.md](examples/README.md)** for all available examples and customization guides.

## 🎓 Examples

### Java Spring Boot Project

```yaml
pipelines:
  branches:
    develop:
      - pipe: docker://nayaksuraj/build-pipe:1.0.0
        variables:
          BUILD_TOOL: auto  # Detects Maven from pom.xml

      - pipe: docker://nayaksuraj/test-pipe:1.0.0
        variables:
          TEST_TYPE: unit
          COVERAGE_THRESHOLD: "80"

      - pipe: docker://nayaksuraj/quality-pipe:1.0.0
        variables:
          SONAR_ENABLED: "true"
          SONAR_PROJECT_KEY: ${SONAR_PROJECT_KEY}

      - pipe: docker://nayaksuraj/docker-pipe:1.0.0
        variables:
          DOCKER_REGISTRY: docker.io
          DOCKER_REPOSITORY: myorg/spring-app
```

### Node.js React Project

```yaml
pipelines:
  branches:
    main:
      - pipe: docker://nayaksuraj/build-pipe:1.0.0
        variables:
          BUILD_TOOL: auto  # Detects npm from package.json

      - pipe: docker://nayaksuraj/test-pipe:1.0.0
        variables:
          TEST_TYPE: unit
          TEST_COMMAND: "npm test"

      - pipe: docker://nayaksuraj/quality-pipe:1.0.0
        variables:
          LINTER: eslint

      - pipe: docker://nayaksuraj/security-pipe:1.0.0
        variables:
          SCAN_DEPENDENCIES: "true"
```

### Python Django Project

```yaml
pipelines:
  branches:
    develop:
      - pipe: docker://nayaksuraj/build-pipe:1.0.0
        variables:
          BUILD_TOOL: auto  # Detects pip from requirements.txt

      - pipe: docker://nayaksuraj/test-pipe:1.0.0
        variables:
          TEST_TYPE: unit
          TEST_COMMAND: "pytest"

      - pipe: docker://nayaksuraj/security-pipe:1.0.0
        variables:
          SCAN_SAST: "true"  # Uses Bandit for Python
          SCAN_DEPENDENCIES: "true"
```

## 🤝 Using These Pipes in Your Project

### Option 1: Local Pipes (Copy to Your Project)

```yaml
- pipe: docker://./bitbucket-pipes/CI/build-pipe
  # Pipe code lives in your repository
```

### Option 2: Published Pipes (Reference Remotely)

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  # Pipe pulled from Docker registry
```

### Option 3: Private Registry

```yaml
- pipe: docker://your-registry.com/your-org/build-pipe:1.0.0
  variables:
    DOCKER_REGISTRY_USERNAME: ${DOCKER_USERNAME}
    DOCKER_REGISTRY_PASSWORD: ${DOCKER_PASSWORD}
```

## 🔧 Troubleshooting

### Build Tool Not Detected

```yaml
# Instead of auto-detection
variables:
  BUILD_TOOL: maven  # Specify explicitly
```

### Docker Registry Authentication Failed

```yaml
# Ensure variables are set in Repository Settings
DOCKER_USERNAME: your-username
DOCKER_PASSWORD: ********  # Mark as secured
```

### Deployment Failed

```yaml
# Check KUBECONFIG is properly base64 encoded
echo $KUBECONFIG | base64 -d | kubectl config view
```

## 📝 Best Practices

1. **Use auto-detection** - Let pipes detect your project type
2. **Version your pipes** - Pin to specific versions (e.g., `1.0.0`)
3. **Secure secrets** - Always mark sensitive variables as secured
4. **Test in dev first** - Never deploy directly to production
5. **Monitor pipelines** - Review logs and optimize slow stages
6. **Update regularly** - Keep pipe versions up to date

## 🔗 Resources

- [Bitbucket Pipelines Documentation](https://support.atlassian.com/bitbucket-cloud/docs/get-started-with-bitbucket-pipelines/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)

---

**Built with ❤️ for DevOps Teams** | **Using Bitbucket Pipes for Maximum Reusability** 🚀
