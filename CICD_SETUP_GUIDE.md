# CI/CD Pipeline Setup Guide

## Overview

This repository contains a comprehensive, production-ready CI/CD pipeline with:

- **Git Flow** branching strategy
- **Dockerization** with multi-stage builds
- **Helm charts** for Kubernetes deployment
- **Trivy** security scanning
- **SonarQube** code quality analysis
- **TestContainers** for integration tests
- **Multi-environment deployment** (dev, stage, prod)

## Architecture

```
┌─────────────┐
│  Git Flow   │
│  Branches   │
└──────┬──────┘
       │
       ├─ feature/* ──> Unit + Integration Tests + Quality
       ├─ develop ────> Tests + Docker Build + Deploy to DEV
       ├─ main ───────> Tests + Docker + Deploy to DEV + STAGE (manual)
       ├─ release ────> Full Pipeline + Deploy to PROD (manual)
       └─ hotfix/* ───> Fast-track to all environments
```

## Pipeline Stages

### 1. Code Checkout
Automatic - handled by Bitbucket Pipelines

### 2. Unit Tests
- **Tool**: JUnit 5 with Mockito
- **Coverage**: JaCoCo (minimum 80% recommended)
- **Script**: `scripts/test.sh`

### 3. Integration Tests
- **Tool**: Maven Failsafe + TestContainers
- **Requirements**: Docker daemon must be running
- **Script**: `scripts/integration-test.sh`

### 4. Code Quality Analysis
- **Tools**:
  - SonarQube/SonarCloud
  - Checkstyle
  - SpotBugs
  - OWASP Dependency Check
- **Script**: `scripts/quality.sh`

### 5. Build and Package
- **Tool**: Maven
- **Output**: Spring Boot JAR
- **Scripts**: `scripts/build.sh`, `scripts/package.sh`

### 6. Docker Build and Push
- **Base Image**: eclipse-temurin:17-jre-alpine
- **Registry**: Configurable (DockerHub, ECR, Harbor, etc.)
- **Tags**: `{env}-{git-sha}`, `{env}-latest`, `{env}-{version}`
- **Script**: `scripts/docker-build.sh`

### 7. Docker Vulnerability Scan
- **Tool**: Trivy
- **Severity**: CRITICAL, HIGH, MEDIUM
- **Script**: `scripts/docker-scan.sh`

### 8. Helm Chart Package
- **Chart Location**: `./helm-chart`
- **Validation**: Lint + Template validation
- **Script**: `scripts/helm-package.sh`

### 9-11. Deployments
- **DEV**: Auto-deploy on develop/main
- **STAGE**: Manual approval required
- **PROD**: Manual approval required
- **Scripts**: `scripts/deploy-{dev|stage|prod}.sh`

## Git Flow Branching Strategy

### Branch Hierarchy

```
release (prod)     ←── hotfix/*
    ↑
main (stage)       ←── develop, hotfix/*
    ↑
develop (dev)      ←── feature/*, hotfix/*
    ↑
feature/* (dev)
```

### Branch Pipelines

| Branch | Tests | Docker | Scan | Deploy |
|--------|-------|--------|------|--------|
| `feature/*` | ✓ Unit + Integration | ✗ | ✗ | ✗ |
| `develop` | ✓ Unit + Integration | ✓ | ✓ | DEV (auto) |
| `main` | ✓ Unit + Integration | ✓ | ✓ | DEV + STAGE (manual) |
| `release` | ✓ Unit + Integration | ✓ | ✓ | DEV + STAGE + PROD (manual) |
| `hotfix/*` | ✓ Unit + Integration | ✓ | ✓ | All envs (manual) |

## Prerequisites

### Local Development
- Java 17+
- Maven 3.8+
- Docker
- Helm 3
- kubectl (for local testing)

### CI/CD Environment (Bitbucket)
- Docker service enabled
- Pipeline variables configured (see below)

### Kubernetes Cluster
- Development namespace
- Staging namespace
- Production namespace
- Ingress controller (optional)
- Cert-manager for TLS (optional)

## Configuration

### Required Bitbucket Pipeline Variables

#### Docker Registry
```
DOCKER_REGISTRY=your-registry.example.com
DOCKER_REPOSITORY=demo-app
DOCKER_USERNAME=<username>
DOCKER_PASSWORD=<secured>
```

#### Helm Registry
```
HELM_REGISTRY=oci://your-registry.example.com/helm-charts
HELM_REGISTRY_USERNAME=<username>
HELM_REGISTRY_PASSWORD=<secured>
HELM_PUSH=true
```

#### Kubernetes Configuration
```
KUBECONFIG=<base64-encoded-kubeconfig>
DEV_NAMESPACE=dev
STAGE_NAMESPACE=staging
PROD_NAMESPACE=production
```

#### SonarQube (Optional)
```
SONAR_ENABLED=true
SONAR_HOST_URL=https://sonarcloud.io
SONAR_TOKEN=<secured>
SONAR_PROJECT_KEY=demo-app
SONAR_ORGANIZATION=your-org
```

#### Security Scanning
```
TRIVY_SEVERITY=CRITICAL,HIGH,MEDIUM
TRIVY_EXIT_CODE=0  # Set to 1 to fail build on vulnerabilities
OWASP_CHECK_ENABLED=true
```

### Environment-Specific Helm Values

Edit these files for each environment:
- `helm-chart/values-dev.yaml`
- `helm-chart/values-stage.yaml`
- `helm-chart/values-prod.yaml`

Key configurations:
- Replica count
- Resource limits
- Ingress hosts
- Environment variables

## Usage

### Feature Development

```bash
# Create feature branch
git checkout develop
git checkout -b feature/my-feature

# Make changes, commit, push
git add .
git commit -m "Add new feature"
git push origin feature/my-feature

# Pipeline runs: Unit Tests + Integration Tests + Quality
```

### Deploy to Development

```bash
# Merge to develop
git checkout develop
git merge feature/my-feature
git push origin develop

# Pipeline runs: Full pipeline + Auto-deploy to DEV
```

### Deploy to Staging

```bash
# Merge to main
git checkout main
git merge develop
git push origin main

# Pipeline runs: Full pipeline + Auto-deploy to DEV
# Manual approval required for STAGE deployment
```

### Deploy to Production

```bash
# Create release branch
git checkout main
git checkout -b release
git push origin release

# Pipeline runs: Full pipeline
# Manual approval required for STAGE and PROD
```

### Hotfix

```bash
# Create hotfix branch
git checkout -b hotfix/critical-fix

# Make fix, commit, push
git push origin hotfix/critical-fix

# Pipeline allows deployment to all environments
# Merge back to develop, main, and release
```

## Deployment Strategies

### Development
- **Strategy**: Rolling update
- **Approval**: Automatic
- **Replicas**: 1
- **Resources**: Minimal

### Staging
- **Strategy**: Blue-Green
- **Approval**: Manual
- **Replicas**: 2
- **Resources**: Production-like

### Production
- **Strategy**: Canary (optional)
- **Approval**: Manual
- **Replicas**: 3+
- **Resources**: High availability

## Monitoring and Observability

### Health Checks
- Liveness: `/actuator/health/liveness`
- Readiness: `/actuator/health/readiness`

### Metrics
- Prometheus: `/actuator/prometheus`
- Grafana dashboards (configure separately)

### Logs
- Centralized logging via ELK or Loki
- JSON format for structured logging

## Troubleshooting

### Pipeline Failures

#### Unit Tests Failing
```bash
# Run locally
mvn clean test

# Check coverage
open target/site/jacoco/index.html
```

#### Integration Tests Failing
```bash
# Ensure Docker is running
docker info

# Run locally
mvn verify
```

#### Docker Build Failing
```bash
# Test Docker build locally
chmod +x scripts/docker-build.sh
export DOCKER_REGISTRY=localhost:5000
export DOCKER_REPOSITORY=demo-app
export DOCKER_PUSH=false
./scripts/docker-build.sh
```

#### Helm Deployment Failing
```bash
# Validate Helm chart locally
helm lint ./helm-chart

# Test template rendering
helm template test ./helm-chart -f helm-chart/values-dev.yaml

# Check Kubernetes connectivity
kubectl cluster-info
kubectl get nodes
```

### Rollback

#### Helm Rollback
```bash
# List release history
helm history demo-app -n production

# Rollback to previous version
helm rollback demo-app -n production

# Rollback to specific revision
helm rollback demo-app 5 -n production
```

## Security Best Practices

1. **Secret Management**: Use Kubernetes Secrets or External Secrets Operator
2. **Image Scanning**: Trivy scans on every build
3. **RBAC**: Configure proper Kubernetes RBAC
4. **Network Policies**: Restrict pod-to-pod communication
5. **Non-root Containers**: All containers run as non-root user
6. **Dependency Scanning**: OWASP Dependency Check

## Customization

### Reusing This Pipeline

This pipeline is designed to be reusable. To adapt for your project:

1. **Update Docker registry and repository names**
   - Edit pipeline variables

2. **Customize Helm values**
   - Edit `helm-chart/values-*.yaml` files
   - Update `helm-chart/Chart.yaml`

3. **Adjust resource limits**
   - Modify values files based on your app's needs

4. **Configure monitoring**
   - Add ServiceMonitor for Prometheus
   - Set up Grafana dashboards

5. **Update deployment scripts**
   - Modify `scripts/deploy-*.sh` if needed

## Cost Optimization

1. Use spot instances for dev/staging
2. Enable HPA for auto-scaling
3. Set appropriate resource requests/limits
4. Use Docker layer caching
5. Implement pod disruption budgets

## Support and Contribution

For issues or questions:
1. Check troubleshooting section
2. Review Bitbucket Pipeline logs
3. Check Kubernetes pod logs: `kubectl logs -n <namespace> <pod-name>`
4. Contact DevOps team

## License

[Your License Here]
