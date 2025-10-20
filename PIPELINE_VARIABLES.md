# Bitbucket Pipeline Variables Configuration

## Overview

This document lists all the environment variables that need to be configured in Bitbucket Repository Settings for the CI/CD pipeline to work correctly.

## How to Configure

1. Go to your Bitbucket repository
2. Navigate to **Repository Settings** > **Pipelines** > **Repository variables**
3. Add the following variables

## Required Variables

### Docker Registry Configuration

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `DOCKER_REGISTRY` | Plain text | Docker registry URL | `registry.example.com` |
| `DOCKER_REPOSITORY` | Plain text | Docker repository name | `demo-app` |
| `DOCKER_USERNAME` | Plain text | Docker registry username | `myuser` |
| `DOCKER_PASSWORD` | **Secured** | Docker registry password/token | `***` |

### Helm Registry Configuration

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `HELM_REGISTRY` | Plain text | Helm chart registry (OCI format) | `oci://registry.example.com/helm-charts` |
| `HELM_REGISTRY_USERNAME` | Plain text | Helm registry username | `myuser` |
| `HELM_REGISTRY_PASSWORD` | **Secured** | Helm registry password/token | `***` |
| `HELM_PUSH` | Plain text | Enable/disable helm push | `true` |

### Kubernetes Configuration

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `KUBECONFIG` | **Secured** | Base64-encoded kubeconfig file | `YXBpVmVyc2lvbjp...` |
| `DEV_NAMESPACE` | Plain text | Development namespace | `dev` |
| `STAGE_NAMESPACE` | Plain text | Staging namespace | `staging` |
| `PROD_NAMESPACE` | Plain text | Production namespace | `production` |

**To encode kubeconfig:**
```bash
cat ~/.kube/config | base64
```

**To use in pipeline:**
```bash
echo $KUBECONFIG | base64 -d > ~/.kube/config
```

## Optional Variables

### SonarQube Configuration

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `SONAR_ENABLED` | Plain text | Enable SonarQube analysis | `true` |
| `SONAR_HOST_URL` | Plain text | SonarQube server URL | `https://sonarcloud.io` |
| `SONAR_TOKEN` | **Secured** | SonarQube authentication token | `***` |
| `SONAR_PROJECT_KEY` | Plain text | SonarQube project key | `demo-app` |
| `SONAR_ORGANIZATION` | Plain text | SonarQube organization | `your-org` |

### Security Scanning

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `TRIVY_SEVERITY` | Plain text | Severity levels to report | `CRITICAL,HIGH,MEDIUM` |
| `TRIVY_EXIT_CODE` | Plain text | Exit code on vulnerabilities | `0` (warn) or `1` (fail) |
| `OWASP_CHECK_ENABLED` | Plain text | Enable OWASP dependency check | `true` |

### Testing Configuration

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `COVERAGE_THRESHOLD` | Plain text | Minimum code coverage % | `80` |
| `FAIL_ON_LOW_COVERAGE` | Plain text | Fail build on low coverage | `false` |

## Variable Groups (Recommended)

For better organization, consider creating variable groups:

### Development Group
```
DOCKER_REGISTRY=dev-registry.example.com
DEV_NAMESPACE=dev
```

### Staging Group
```
DOCKER_REGISTRY=stage-registry.example.com
STAGE_NAMESPACE=staging
```

### Production Group
```
DOCKER_REGISTRY=prod-registry.example.com
PROD_NAMESPACE=production
```

## Security Best Practices

1. **Always mark sensitive values as "Secured"**
   - Passwords
   - Tokens
   - API keys
   - Kubeconfig

2. **Use separate credentials for each environment**
   - Different registry credentials for prod vs dev
   - Separate Kubernetes clusters

3. **Rotate credentials regularly**
   - Update Docker registry tokens
   - Rotate Kubernetes service account tokens

4. **Limit permissions**
   - Use least-privilege principle
   - Read-only access where possible

## Validation

After configuring variables, test the pipeline with a feature branch:

```bash
git checkout -b feature/test-pipeline
git commit --allow-empty -m "Test pipeline configuration"
git push origin feature/test-pipeline
```

Check the pipeline execution in Bitbucket Pipelines UI.

## Troubleshooting

### Pipeline Fails: "DOCKER_REGISTRY not set"
- Verify variable is created in Repository Variables
- Check variable name (case-sensitive)
- Ensure variable is not deployment-specific

### Pipeline Fails: "Cannot connect to Kubernetes cluster"
- Verify KUBECONFIG is correctly base64-encoded
- Check cluster connectivity from Bitbucket Pipelines
- Verify service account has necessary permissions

### Docker Push Fails: "Authentication required"
- Check DOCKER_USERNAME and DOCKER_PASSWORD are set
- Verify credentials are valid
- Test docker login manually:
  ```bash
  echo $DOCKER_PASSWORD | docker login $DOCKER_REGISTRY -u $DOCKER_USERNAME --password-stdin
  ```

### Helm Push Fails
- Verify HELM_REGISTRY format (should start with `oci://`)
- Check HELM_REGISTRY_USERNAME and HELM_REGISTRY_PASSWORD
- Ensure Helm 3.8+ is installed (OCI support)

## Quick Reference

### Minimal Configuration (Development Only)

```yaml
# Required
DOCKER_REGISTRY=docker.io
DOCKER_REPOSITORY=myuser/demo-app
DOCKER_USERNAME=myuser
DOCKER_PASSWORD=***

# Optional (disable others)
HELM_PUSH=false
SONAR_ENABLED=false
```

### Full Production Configuration

```yaml
# Docker
DOCKER_REGISTRY=registry.example.com
DOCKER_REPOSITORY=demo-app
DOCKER_USERNAME=cicd-user
DOCKER_PASSWORD=***

# Helm
HELM_REGISTRY=oci://registry.example.com/helm
HELM_REGISTRY_USERNAME=cicd-user
HELM_REGISTRY_PASSWORD=***
HELM_PUSH=true

# Kubernetes
KUBECONFIG=***
DEV_NAMESPACE=dev
STAGE_NAMESPACE=staging
PROD_NAMESPACE=production

# SonarQube
SONAR_ENABLED=true
SONAR_HOST_URL=https://sonarcloud.io
SONAR_TOKEN=***
SONAR_PROJECT_KEY=demo-app
SONAR_ORGANIZATION=my-org

# Security
TRIVY_EXIT_CODE=1
OWASP_CHECK_ENABLED=true
```

## Support

For issues with pipeline variables:
1. Check variable names (case-sensitive)
2. Verify secured variables are marked as "Secured"
3. Test credentials manually
4. Review pipeline logs for specific errors
5. Contact DevOps team
