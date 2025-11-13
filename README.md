# Reusable Bitbucket Pipelines for CI/CD

A production-ready, reusable Bitbucket Pipeline configuration with comprehensive CI/CD workflows, security scanning, and DevSecOps best practices.

## 📋 Overview

This repository provides two complete Bitbucket Pipeline configurations that can be reused across multiple projects:

1. **bitbucket-pipelines.yml** - Standard CI/CD pipeline with Docker, Helm, and Kubernetes deployment
2. **bitbucket-pipelines-devsecops.yml** - Enhanced DevSecOps pipeline with shift-left security practices

Both pipelines follow Git Flow branching strategy and include parallel execution for optimal performance.

## 🎯 Two Approaches: Pipes vs Scripts

This repository provides **two ways** to implement CI/CD:

### ✨ **Recommended: Bitbucket Pipes** (Newer Approach)
Modular, Docker-based reusable components that can be versioned and shared across projects.
- 📍 Located in `bitbucket-pipes/` directory
- ✅ **Pros**: Versioned, portable, easier to maintain, language-agnostic
- 📖 See: [bitbucket-pipes/README.md](bitbucket-pipes/README.md) for full documentation
- 💡 Example: [bitbucket-pipelines-using-pipes-v2.yml](bitbucket-pipelines-using-pipes-v2.yml)

### 📜 **Traditional: Shell Scripts** (Legacy Approach)
Bash scripts that run directly in the pipeline environment.
- 📍 Located in `scripts/` directory
- ✅ **Pros**: Simple, no Docker required, easier to debug locally
- 📖 See: [scripts/README.md](scripts/README.md) for details
- 💡 Used by: [bitbucket-pipelines.yml](bitbucket-pipelines.yml) and [bitbucket-pipelines-devsecops.yml](bitbucket-pipelines-devsecops.yml)

**Which should I use?**
- **New projects**: Use Bitbucket Pipes (recommended)
- **Existing projects**: Continue with scripts, or migrate gradually
- **See**: [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for migration instructions

## 🚀 Quick Start

### For a New Project

1. Copy the desired pipeline file to your project root:
   ```bash
   # Standard pipeline
   cp bitbucket-pipelines.yml /path/to/your/project/

   # OR DevSecOps pipeline
   cp bitbucket-pipelines-devsecops.yml /path/to/your/project/bitbucket-pipelines.yml
   ```

2. Copy the scripts directory:
   ```bash
   cp -r scripts /path/to/your/project/
   ```

3. Configure repository variables in Bitbucket:
   - Go to Repository Settings → Pipelines → Repository Variables
   - Add required variables (see Configuration section below)

4. Push to your repository and watch the pipeline run!

## 📦 What's Included

### Standard Pipeline Features

- ✅ **Git Flow Support**: feature/*, develop, main, release, hotfix/* branches
- ✅ **Parallel Execution**: Tests and quality checks run concurrently
- ✅ **Docker Build & Push**: Containerization with security scanning
- ✅ **Helm Packaging**: Kubernetes deployment with Helm charts
- ✅ **Multi-Environment**: dev (auto), staging (manual), production (manual)
- ✅ **Vulnerability Scanning**: Trivy security scans
- ✅ **Tag-based Deployments**: Production releases via Git tags

### DevSecOps Pipeline Additional Features

- 🔒 **Shift-Left Security**: Security checks at every pipeline stage
- 🔒 **Secrets Scanning**: GitLeaks integration (blocking)
- 🔒 **SAST**: Static Application Security Testing
- 🔒 **SCA**: Software Composition Analysis (dependency scanning)
- 🔒 **SBOM Generation**: Software Bill of Materials (CycloneDX)
- 🔒 **Dockerfile Security**: Hadolint scanning
- 🔒 **IaC Security**: Helm/Kubernetes security validation
- 🔒 **Enhanced Container Scanning**: Comprehensive Trivy scans

## 🔧 Configuration

### Required Repository Variables

Set these in Bitbucket Repository Settings → Pipelines → Repository Variables:

#### Docker Registry
```
DOCKER_REGISTRY          # e.g., docker.io or registry.company.com
DOCKER_USERNAME          # Registry username
DOCKER_PASSWORD          # Registry password (use secured variables)
DOCKER_REPOSITORY        # Repository name (e.g., myapp)
```

#### Kubernetes Deployment
```
KUBECONFIG               # Base64 encoded kubeconfig file
DEV_NAMESPACE            # Kubernetes namespace for dev (default: dev)
STAGE_NAMESPACE          # Kubernetes namespace for staging (default: staging)
PROD_NAMESPACE           # Kubernetes namespace for production (default: production)
```

#### Helm Registry (Optional)
```
HELM_REGISTRY            # Helm chart registry URL
HELM_REGISTRY_USERNAME   # Helm registry username
HELM_REGISTRY_PASSWORD   # Helm registry password
HELM_PUSH                # Set to "true" to push charts
```

#### Security Tools (DevSecOps Pipeline)
```
SONAR_ENABLED            # Enable SonarQube (default: false)
SONAR_TOKEN              # SonarQube authentication token
SONAR_HOST_URL           # SonarQube server URL
FAIL_ON_SECRETS          # Fail pipeline on secrets found (default: true)
TRIVY_SEVERITY           # Scan severity levels (default: CRITICAL,HIGH,MEDIUM)
```

## 📂 Project Structure

```
.
├── bitbucket-pipelines.yml              # Standard CI/CD pipeline (uses scripts/)
├── bitbucket-pipelines-devsecops.yml    # DevSecOps enhanced pipeline (uses scripts/)
├── bitbucket-pipelines-using-pipes-v2.yml  # Example pipeline using Bitbucket Pipes
│
├── bitbucket-pipes/                     # ⭐ Reusable Bitbucket Pipes (RECOMMENDED)
│   ├── README.md                        # Pipes documentation
│   ├── CI/                              # Continuous Integration pipes
│   │   ├── build-pipe/                  # Generic build pipe (Maven, Gradle, npm, Python, Go, .NET, Rust, Ruby)
│   │   ├── test-pipe/                   # Unit & integration testing
│   │   ├── quality-pipe/                # SonarQube, linting, static analysis
│   │   └── security-pipe/               # Comprehensive security scanning
│   └── CD/                              # Continuous Deployment pipes
│       ├── docker-pipe/                 # Docker build, scan, and push
│       ├── helm-pipe/                   # Helm chart operations
│       └── deploy-pipe/                 # Kubernetes deployment
│
├── scripts/                             # Traditional shell scripts (legacy approach)
│   ├── build.sh                         # Application build
│   ├── package.sh                       # Application packaging
│   ├── test.sh                          # Unit tests
│   ├── integration-test.sh              # Integration tests
│   ├── quality.sh                       # Code quality checks
│   ├── docker-build.sh                  # Docker image build
│   ├── docker-scan.sh                   # Container vulnerability scan
│   ├── helm-package.sh                  # Helm chart packaging
│   ├── deploy-dev.sh                    # Development deployment
│   ├── deploy-stage.sh                  # Staging deployment
│   ├── deploy-prod.sh                   # Production deployment
│   ├── security-secrets-scan.sh         # Secrets scanning
│   ├── security-sca-scan.sh             # Dependency scanning
│   ├── security-dockerfile-scan.sh      # Dockerfile security
│   ├── security-iac-scan.sh             # IaC security
│   └── security-sbom-generate.sh        # SBOM generation
│
├── helm-chart/                          # Kubernetes Helm chart
├── Dockerfile                           # Container image definition
├── MIGRATION_GUIDE.md                   # Guide for migrating from scripts to pipes
└── README.md                            # This file
```

## 🌳 Git Flow Branch Strategy

| Branch Pattern | Triggers | Actions |
|---------------|----------|---------|
| `feature/**` | Push | Tests + Build |
| `develop` | Push | Full pipeline + Deploy to dev |
| `main` | Push | Full pipeline + Deploy to dev + Manual staging |
| `release` | Push | Full pipeline + Manual staging + Manual production |
| `hotfix/**` | Push | Fast-track pipeline + All environments |
| `v*` (tags) | Tag creation | Production deployment |
| Pull Requests | PR creation | Tests + Quality checks + Build |

## 🔄 Pipeline Workflows

### Feature Branch Workflow
```
feature/* → Unit Tests → Integration Tests → Code Quality → Build
            (parallel)
```

### Develop Branch Workflow
```
develop → Tests (parallel) → Build → Docker Build & Push →
         Scan & Helm Package (parallel) → Deploy to Dev
```

### Main/Release Workflow
```
main/release → Tests (parallel) → Build → Docker Build & Push →
              Scan & Helm Package (parallel) → Deploy to Dev →
              Deploy to Staging (manual) → Deploy to Production (manual)
```

### DevSecOps Workflow (Enhanced)
```
Any branch → Secrets Scan → SAST & SCA (parallel with tests) →
            Build + SBOM → Dockerfile Security → Docker Build →
            Container Scan & IaC Security (parallel) → Deployments
```

## 🎯 Custom Pipelines

Both pipeline files include custom/manual pipelines that can be triggered from the Bitbucket UI:

### Standard Pipeline
- `full-pipeline` - Run complete pipeline with all steps
- `build-and-test` - Quick build and test only
- `docker-only` - Build and scan Docker image only
- `deploy-dev-only` - Deploy to development only
- `deploy-stage-only` - Deploy to staging only
- `emergency-prod-deploy` - Emergency production deploy (skip tests)

### DevSecOps Pipeline
- `full-devsecops-pipeline` - Complete security pipeline
- `security-audit` - Run all security scans only
- `secure-build` - Build with comprehensive security checks

## 🔐 Security Features (DevSecOps Pipeline)

### Shift-Left Security Approach
Security is integrated at every stage:

1. **Pre-Commit**: Secrets scanning (blocking)
2. **Build Time**: SAST, SCA, SBOM generation
3. **Container Build**: Dockerfile security, image scanning
4. **Pre-Deployment**: IaC security validation

### Security Tools
- **GitLeaks**: Secrets detection in code and commits
- **OWASP Dependency-Check**: Dependency vulnerability scanning
- **Trivy**: Container and filesystem vulnerability scanning
- **Hadolint**: Dockerfile best practices and security
- **Checkov**: Infrastructure as Code security scanning
- **CycloneDX**: SBOM generation for supply chain security

## 🛠️ Customization

### Adapting for Different Tech Stacks

The pipelines are designed to be framework-agnostic. Modify the following:

1. **Change the base image** in the pipeline YAML:
   ```yaml
   image: maven:3.8.6-openjdk-17    # Change to node:18, python:3.11, etc.
   ```

2. **Update build scripts** in `scripts/` directory to match your build tools

3. **Adjust caches** for your package manager:
   ```yaml
   caches:
     - maven-local    # Change to npm, pip, gradle, etc.
   ```

### Example: Node.js Project
```yaml
image: node:18-alpine
definitions:
  caches:
    node-modules: node_modules
  steps:
    - step: &build
        caches:
          - node-modules
        script:
          - npm ci
          - npm run build
```

### Example: Python Project
```yaml
image: python:3.11-slim
definitions:
  caches:
    pip-cache: ~/.cache/pip
  steps:
    - step: &build
        caches:
          - pip-cache
        script:
          - pip install -r requirements.txt
          - pytest
```

## 📊 Performance Optimizations

- **Parallel Execution**: Tests and quality checks run concurrently
- **Single Build Approach**: Application built once, reused across steps
- **Smart Caching**: Dependencies cached between builds
- **Artifact Reuse**: Build artifacts shared across pipeline steps
- **Expected Performance**: 40-60% faster than sequential pipelines

## 📖 Documentation

- **CICD_SETUP_GUIDE.md** - Step-by-step CI/CD setup instructions
- **DEVSECOPS_QUICKSTART.md** - Quick start guide for DevSecOps pipeline
- **DEVSECOPS_ASSESSMENT.md** - Security maturity assessment
- **PIPELINE_VARIABLES.md** - Complete list of configurable variables

## 🤝 Contributing

This is a reference implementation. Feel free to fork and customize for your needs.

## 📝 License

This project is provided as-is for demonstration and educational purposes.

## 🔗 Resources

- [Bitbucket Pipelines Documentation](https://support.atlassian.com/bitbucket-cloud/docs/get-started-with-bitbucket-pipelines/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Helm Documentation](https://helm.sh/docs/)
- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)

---

**Built with ❤️ for DevOps and Security Teams**
