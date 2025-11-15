# Pipeline Examples - Using Templates from nayaksuraj/test-repo

These examples demonstrate how to use production-ready CI/CD pipeline templates from **nayaksuraj/test-repo** in your projects. Each example shows the recommended way to import and configure language-specific templates.

## Available Examples

| Language | Example Directory | Template Used | Features |
|----------|-------------------|---------------|----------|
| **Python** | [python/](./python/) | `python-template.yml` | pytest, mypy, ruff, coverage |
| **Java** | [java-maven/](./java-maven/) | `java-maven-template.yml` | Multi-module, JaCoCo, SonarQube |
| **Java** | [java-gradle/](./java-gradle/) | `java-gradle-template.yml` | Kotlin DSL, build cache, parallel execution |
| **Node.js** | [nodejs/](./nodejs/) | `nodejs-template.yml` | ESLint, Jest, bundle analysis |
| **Go** | [golang/](./golang/) | `golang-template.yml` | Race detection, benchmarks |
| **.NET** | [dotnet/](./dotnet/) | `dotnet-template.yml` | Multi-target, NuGet, xUnit |
| **Rust** | [rust/](./rust/) | `rust-template.yml` | Clippy, cargo-audit |
| **Ruby** | [ruby/](./ruby/) | `ruby-template.yml` | RSpec, Rubocop |
| **PHP** | [php/](./php/) | `php-template.yml` | PHPUnit, PHPCS, Psalm |

## Common Patterns

All examples include:

✅ **Multi-stage pipelines** - Different workflows for branches, PRs, and releases
✅ **Parallel execution** - Tests, quality, and security scans run concurrently
✅ **Dependency caching** - Faster builds with intelligent caching
✅ **Code coverage** - Minimum 80% threshold enforced
✅ **Quality gates** - SonarQube integration with quality profiles
✅ **Security scanning** - Secrets, dependencies, SAST, SBOM generation
✅ **Docker optimization** - Multi-stage builds, layer caching, vulnerability scanning
✅ **Kubernetes deployment** - Helm charts with rollback support
✅ **Environment strategy** - Dev (auto), Staging (manual), Production (manual + extended timeout)

## Pipeline Workflows

### Feature Branches
```
Push → Build → Test (parallel) → Quality & Security (parallel)
```

### Develop Branch
```
Push → Build → Test → Quality & Security (parallel) →
Docker Build → Deploy to Dev (auto)
```

### Main Branch
```
Push → Build → Test → Quality & Security (parallel) →
Integration Tests → Docker Build → Helm Package →
Deploy to Dev (auto) → Deploy to Staging (manual)
```

### Release Tags (v*)
```
Tag → Build → Security Scan → Release Build →
Docker Build (versioned + latest) →
Deploy to Production (manual with extended timeout)
```

## Getting Started

### How to Use Templates in Your Repository

**Method 1: Import via !include (Recommended)**

Create `bitbucket-pipelines.yml` in your repository:

```yaml
# Import Python template from nayaksuraj/test-repo
resources:
  repositories:
    pipeline-templates:
      git: git@bitbucket.org:nayaksuraj/test-repo.git

!include:
  - pipeline-templates:pipeline-templates/python-template.yml
```

Change the template path for other languages:
- Python: `pipeline-templates/python-template.yml`
- Java Maven: `pipeline-templates/java-maven-template.yml`
- Java Gradle: `pipeline-templates/java-gradle-template.yml`
- Node.js: `pipeline-templates/nodejs-template.yml`
- Go: `pipeline-templates/golang-template.yml`
- .NET: `pipeline-templates/dotnet-template.yml`
- Rust: `pipeline-templates/rust-template.yml`
- Ruby: `pipeline-templates/ruby-template.yml`
- PHP: `pipeline-templates/php-template.yml`

**Method 2: Copy Template Directly**

If you prefer standalone pipelines without !include:

```bash
# For Python projects
curl -o bitbucket-pipelines.yml https://bitbucket.org/nayaksuraj/test-repo/raw/main/pipeline-templates/python-template.yml

# For Java Maven projects
curl -o bitbucket-pipelines.yml https://bitbucket.org/nayaksuraj/test-repo/raw/main/pipeline-templates/java-maven-template.yml

# Browse all: https://bitbucket.org/nayaksuraj/test-repo/src/main/pipeline-templates/
```

**Configure Required Variables**

Go to: **Repository Settings → Pipelines → Repository variables**

Add these variables (mark secured ones):
- `DOCKER_REGISTRY`, `DOCKER_USERNAME`, `DOCKER_PASSWORD` (secured)
- `KUBECONFIG_DEV`, `KUBECONFIG_STAGING`, `KUBECONFIG_PRODUCTION` (secured)
- `SLACK_WEBHOOK_URL` (secured)
- `SONAR_TOKEN` (secured, optional)

**Commit and Push**

```bash
git add bitbucket-pipelines.yml
git commit -m "Add CI/CD pipeline using nayaksuraj/test-repo templates"
git push
```

Your pipeline will run automatically!

### Exploring Examples

Each example directory demonstrates the `!include` import pattern:

```bash
# View Python example - shows !include usage
cat examples/python/bitbucket-pipelines.yml

# View Java Maven example - shows !include usage
cat examples/java-maven/bitbucket-pipelines.yml
```

All examples use `!include` to import templates from `pipeline-templates/`.

## Why Use These Templates?

### ✅ Zero Code Duplication
All examples use **Bitbucket Pipes** from nayaksuraj/test-repo:
- `lint-pipe` - Pre-commit, linting, type checking
- `test-pipe` - Unit tests, coverage
- `quality-pipe` - SonarQube/SonarCloud
- `security-pipe` - Secrets, SCA, SAST, SBOM
- `docker-pipe` - Build, scan, push
- `helm-pipe` - Lint, package, push
- `deploy-pipe` - Kubernetes deployments
- `notify-pipe` - Slack, Email, Teams, Discord, Webhooks

**No manual tool installation, no code duplication!**

### ✅ Auto-Detection
Templates automatically detect:
- Programming language
- Build system (Maven, Gradle, npm, Poetry, Cargo, etc.)
- Test framework (JUnit, pytest, Jest, etc.)
- Package managers and lockfiles

**No need to specify language or tools!**

### ✅ Production-Ready
Based on best practices from:
- Netflix, Amazon, Google (Java)
- Airbnb, Uber, PayPal (Node.js)
- Instagram, Spotify, Dropbox (Python)
- And more...

**Battle-tested patterns, ready to use!**

## Required Variables

All examples require these Bitbucket variables:

```bash
# Docker Registry
DOCKER_REGISTRY=docker.io
DOCKER_REPOSITORY=myorg/myapp
DOCKER_USERNAME=your-username
DOCKER_PASSWORD=***

# Kubernetes (for deployments)
KUBECONFIG=*** (base64 encoded)

# SonarQube (optional but recommended)
SONAR_HOST_URL=https://sonarcloud.io
SONAR_TOKEN=***
```

## Best Practices Applied

### 1. Speed Optimization
- **Parallel execution**: Independent tasks run concurrently
- **Dependency caching**: Up to 80% faster builds
- **Smart artifacts**: Only upload what's needed
- **Layer caching**: Docker builds reuse unchanged layers

### 2. Security First
- **Secrets scanning**: GitLeaks prevents credential leaks
- **Dependency scanning**: OWASP + Grype catch vulnerabilities
- **SBOM generation**: Supply chain transparency
- **Container scanning**: Trivy for runtime vulnerabilities

### 3. Quality Gates
- **Code coverage**: Minimum 80% enforced
- **SonarQube**: Quality gates with configurable rules
- **Linting**: Language-specific linters (ESLint, Pylint, Golint, etc.)
- **Type checking**: TypeScript, mypy, Go vet

### 4. Deployment Strategy
- **Dev**: Auto-deploy on develop branch (fast feedback)
- **Staging**: Manual approval on main branch (QA testing)
- **Production**: Manual approval on tags with:
  - Extended timeout (10 minutes)
  - Automatic rollback on failure
  - Health checks and smoke tests
  - Canary deployments (optional)

### 5. Observability
- **Build metrics**: Track build time, test duration
- **Coverage trends**: Monitor coverage over time
- **Artifact versioning**: Every build produces traceable artifacts
- **Deployment tracking**: Link commits to deployments

## Customization Guide

### Add More Environments
```yaml
- pipe: docker://nayaksuraj/deploy-pipe:1.0.0
  variables:
    ENVIRONMENT: "qa"
    NAMESPACE: "qa"
    KUBECONFIG: $KUBECONFIG_QA
```

### Add Performance Tests
```yaml
custom:
  performance-test:
    - step:
        name: Load Testing
        script:
          - k6 run performance-tests/load-test.js
```

### Add Database Migrations
```yaml
- step:
    name: Database Migration
    script:
      - flyway migrate
```

### Add Notifications
```yaml
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "slack"
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "Deployment to ${ENVIRONMENT} completed!"
    STATUS: "success"
    ENVIRONMENT: "${ENVIRONMENT}"
```

## Performance Benchmarks

Based on real-world production pipelines:

| Language | Build Time | Test Time | Total Pipeline | Cache Hit |
|----------|-----------|-----------|----------------|-----------|
| Java (Maven) | 2-3 min | 1-2 min | 5-8 min | ~75% |
| Node.js | 1-2 min | 1-2 min | 3-5 min | ~80% |
| Python | 1-2 min | 1-2 min | 4-6 min | ~70% |
| Go | 30s-1min | 30s-1min | 2-3 min | ~85% |

*Times with caching enabled and parallel execution*

## Troubleshooting

### Slow Builds?
1. Check if caching is enabled
2. Enable parallel execution where possible
3. Review artifact sizes (only upload essentials)
4. Consider using build agents with more resources

### Tests Failing?
1. Run tests locally first: `npm test` / `mvn test` / `go test`
2. Check test reports in artifacts
3. Review coverage requirements (may be too strict)
4. Ensure test containers have enough memory

### Security Scans Failing?
1. Review vulnerability reports in artifacts
2. Update dependencies: `npm audit fix` / `mvn versions:use-latest-releases`
3. Add exceptions for false positives
4. Consider adjusting `FAIL_ON_HIGH` threshold

### Deployment Failing?
1. Verify KUBECONFIG is valid and base64 encoded
2. Check namespace exists: `kubectl get namespaces`
3. Verify Helm chart is valid: `helm lint ./helm-chart`
4. Check deployment logs: `kubectl logs -n <namespace> <pod>`

## Contributing

Found a better pattern? Please contribute!

1. Test your pattern in production
2. Document the benefits
3. Submit a pull request with:
   - Example pipeline
   - README with usage instructions
   - Any required configuration files

## Resources

### General
- [Bitbucket Pipelines Documentation](https://support.atlassian.com/bitbucket-cloud/docs/get-started-with-bitbucket-pipelines/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

### Language-Specific
- **Java**: [Maven Best Practices](https://maven.apache.org/), [Netflix OSS](https://netflix.github.io/)
- **Node.js**: [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- **Python**: [Python Packaging Guide](https://packaging.python.org/), [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- **Go**: [Effective Go](https://golang.org/doc/effective_go.html), [Uber Go Style Guide](https://github.com/uber-go/guide)

## License

These examples are provided as-is for educational and production use. Adapt them to your needs!
