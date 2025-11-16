# Helm Chart Registry Setup Guide

Complete guide for configuring Helm chart registries with Bitbucket Pipelines for packaging and pushing Helm charts.

## 📋 Table of Contents

- [Overview](#overview)
- [Supported Registries](#supported-registries)
- [Quick Start](#quick-start)
- [Registry Configuration](#registry-configuration)
- [Pipeline Integration](#pipeline-integration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

The `helm-pipe` supports pushing Helm charts to:
- **OCI Registries**: GitHub Container Registry (GHCR), AWS ECR, Azure ACR, Google Artifact Registry, Harbor
- **Traditional Registries**: ChartMuseum, Artifactory, Nexus

### Why Use a Helm Registry?

- **Versioning**: Track chart versions alongside application versions
- **Reusability**: Share charts across teams and projects
- **Security**: Private charts with access control
- **Automation**: Integrate with CI/CD pipelines
- **Consistency**: Single source of truth for deployments

## 🏪 Supported Registries

### OCI Registries (Recommended)

| Registry | Type | Free Tier | Enterprise |
|----------|------|-----------|------------|
| **GitHub Container Registry** | OCI | ✅ Public repos | ✅ Private repos |
| **AWS ECR** | OCI | ✅ 500 MB/month | ✅ Unlimited |
| **Azure ACR** | OCI | ❌ | ✅ |
| **Google Artifact Registry** | OCI | ✅ 0.5 GB storage | ✅ Unlimited |
| **Harbor** | OCI | ✅ Self-hosted | ✅ Enterprise |

### Traditional Registries

| Registry | Type | Free Tier | Enterprise |
|----------|------|-----------|------------|
| **ChartMuseum** | Traditional | ✅ Self-hosted | ✅ |
| **JFrog Artifactory** | Traditional | ❌ | ✅ |
| **Sonatype Nexus** | Traditional | ✅ OSS version | ✅ Pro |

## 🚀 Quick Start

### Step 1: Choose Your Registry

We recommend **GitHub Container Registry (GHCR)** for most use cases:
- Free for public repositories
- Excellent OCI support
- Easy authentication with GitHub tokens
- Integrated with GitHub Packages

### Step 2: Configure Bitbucket Variables

Add these to **Repository Settings → Pipelines → Repository Variables**:

```bash
HELM_REGISTRY=oci://ghcr.io/your-org/charts
HELM_REGISTRY_USERNAME=your-github-username
HELM_REGISTRY_PASSWORD=ghp_xxxxxxxxxxxxx  # Mark as SECURED ⚠️
```

### Step 3: Update Pipeline

Your pipeline automatically uses these variables:

```yaml
- pipe: docker://nayaksuraj/helm-pipe:1.0.0
  variables:
    HELM_CHART_PATH: "./helm-chart"
    HELM_REGISTRY: $HELM_REGISTRY
    HELM_REGISTRY_USERNAME: $HELM_REGISTRY_USERNAME
    HELM_REGISTRY_PASSWORD: $HELM_REGISTRY_PASSWORD
    PUSH_CHART: "true"
```

## 📦 Registry Configuration

### GitHub Container Registry (GHCR)

#### 1. Create GitHub Personal Access Token

1. Go to **GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic)**
2. Click **Generate new token (classic)**
3. Configure:
   - **Note**: `Bitbucket Helm Pipeline`
   - **Expiration**: `No expiration` (or set based on policy)
   - **Scopes**: Select:
     - ✅ `write:packages` (Upload packages)
     - ✅ `read:packages` (Download packages)
     - ✅ `delete:packages` (Delete packages)
4. Click **Generate token**
5. Copy token immediately (won't be shown again)

#### 2. Configure Bitbucket Variables

```bash
# Repository Settings → Pipelines → Repository Variables
HELM_REGISTRY=oci://ghcr.io/your-github-org/charts
HELM_REGISTRY_USERNAME=your-github-username
HELM_REGISTRY_PASSWORD=ghp_xxxxxxxxxxxxxxxxxxxxx  # ⚠️ Mark as SECURED
```

#### 3. Pipeline Configuration

```yaml
- pipe: docker://nayaksuraj/helm-pipe:1.0.0
  variables:
    HELM_CHART_PATH: "./helm-chart"
    CHART_VERSION: "${BITBUCKET_TAG#v}"
    HELM_REGISTRY: $HELM_REGISTRY
    HELM_REGISTRY_USERNAME: $HELM_REGISTRY_USERNAME
    HELM_REGISTRY_PASSWORD: $HELM_REGISTRY_PASSWORD
    LINT_CHART: "true"
    PACKAGE_CHART: "true"
    PUSH_CHART: "true"
```

#### 4. Verify

```bash
# Pull published chart
helm pull oci://ghcr.io/your-org/charts/myapp --version 1.0.0

# Install from registry
helm install myapp oci://ghcr.io/your-org/charts/myapp --version 1.0.0
```

### AWS Elastic Container Registry (ECR)

#### 1. Create ECR Repository

```bash
# Create repository for Helm charts
aws ecr create-repository \
  --repository-name charts/myapp \
  --region us-east-1

# Enable OCI artifact support
aws ecr put-registry-policy \
  --policy-text file://oci-policy.json \
  --region us-east-1
```

#### 2. Get ECR Password

```bash
# Get login password (valid for 12 hours)
aws ecr get-login-password --region us-east-1
```

#### 3. Configure Bitbucket Variables

```bash
HELM_REGISTRY=oci://123456789012.dkr.ecr.us-east-1.amazonaws.com/charts
HELM_REGISTRY_USERNAME=AWS
HELM_REGISTRY_PASSWORD=<password-from-step-2>  # ⚠️ Mark as SECURED

# Note: ECR password expires after 12 hours
# For automation, use AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# and generate password in pipeline
```

#### 4. Pipeline with Dynamic Token

```yaml
- step:
    name: Push Helm Chart to ECR
    script:
      # Generate ECR token dynamically
      - export ECR_PASSWORD=$(aws ecr get-login-password --region us-east-1)
      - pipe: docker://nayaksuraj/helm-pipe:1.0.0
        variables:
          HELM_CHART_PATH: "./helm-chart"
          HELM_REGISTRY: "oci://123456789012.dkr.ecr.us-east-1.amazonaws.com/charts"
          HELM_REGISTRY_USERNAME: "AWS"
          HELM_REGISTRY_PASSWORD: $ECR_PASSWORD
          PUSH_CHART: "true"
```

### Azure Container Registry (ACR)

#### 1. Create ACR and Enable Admin Access

```bash
# Create registry
az acr create \
  --resource-group myResourceGroup \
  --name myregistry \
  --sku Standard

# Enable admin user
az acr update -n myregistry --admin-enabled true

# Get credentials
az acr credential show --name myregistry
```

#### 2. Configure Bitbucket Variables

```bash
HELM_REGISTRY=oci://myregistry.azurecr.io/helm
HELM_REGISTRY_USERNAME=myregistry  # Registry name
HELM_REGISTRY_PASSWORD=<password-from-step-1>  # ⚠️ Mark as SECURED
```

#### 3. Pipeline Configuration

```yaml
- pipe: docker://nayaksuraj/helm-pipe:1.0.0
  variables:
    HELM_CHART_PATH: "./helm-chart"
    HELM_REGISTRY: $HELM_REGISTRY
    HELM_REGISTRY_USERNAME: $HELM_REGISTRY_USERNAME
    HELM_REGISTRY_PASSWORD: $HELM_REGISTRY_PASSWORD
    PUSH_CHART: "true"
```

### Google Artifact Registry

#### 1. Create Artifact Registry Repository

```bash
# Create repository
gcloud artifacts repositories create charts \
  --repository-format=docker \
  --location=us-central1 \
  --description="Helm charts"

# Create service account
gcloud iam service-accounts create helm-pusher \
  --display-name="Helm Chart Pusher"

# Grant permissions
gcloud artifacts repositories add-iam-policy-binding charts \
  --location=us-central1 \
  --member="serviceAccount:helm-pusher@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Create JSON key
gcloud iam service-accounts keys create key.json \
  --iam-account=helm-pusher@PROJECT_ID.iam.gserviceaccount.com
```

#### 2. Configure Bitbucket Variables

```bash
HELM_REGISTRY=oci://us-central1-docker.pkg.dev/PROJECT_ID/charts
HELM_REGISTRY_USERNAME=_json_key
HELM_REGISTRY_PASSWORD=<entire-contents-of-key.json>  # ⚠️ Mark as SECURED
```

#### 3. Pipeline Configuration

```yaml
- pipe: docker://nayaksuraj/helm-pipe:1.0.0
  variables:
    HELM_CHART_PATH: "./helm-chart"
    HELM_REGISTRY: $HELM_REGISTRY
    HELM_REGISTRY_USERNAME: "_json_key"
    HELM_REGISTRY_PASSWORD: $HELM_REGISTRY_PASSWORD
    PUSH_CHART: "true"
```

### Harbor (Self-hosted OCI Registry)

#### 1. Deploy Harbor

```bash
# Using Docker Compose
wget https://github.com/goharbor/harbor/releases/download/v2.9.0/harbor-offline-installer-v2.9.0.tgz
tar xvf harbor-offline-installer-v2.9.0.tgz
cd harbor
./install.sh
```

#### 2. Create Project and Robot Account

1. Log into Harbor UI
2. Create new project: `charts`
3. Go to **Robot Accounts → New Robot Account**
4. Name: `helm-pusher`
5. Permissions: Push/Pull artifacts
6. Save credentials

#### 3. Configure Bitbucket Variables

```bash
HELM_REGISTRY=oci://harbor.example.com/charts
HELM_REGISTRY_USERNAME=robot$helm-pusher
HELM_REGISTRY_PASSWORD=<robot-token>  # ⚠️ Mark as SECURED
```

## 🔄 Pipeline Integration

### Complete Pipeline Example

```yaml
image: atlassian/default-image:4

definitions:
  caches:
    docker: /var/lib/docker

pipelines:
  # Pull Requests - Lint and Package Only
  pull-requests:
    '**':
      - step:
          name: Validate Helm Chart
          script:
            - pipe: docker://nayaksuraj/helm-pipe:1.0.0
              variables:
                HELM_CHART_PATH: "./helm-chart"
                LINT_CHART: "true"
                PACKAGE_CHART: "true"
                PUSH_CHART: "false"  # Don't push from PRs

  # Main Branch - Package and Push
  branches:
    main:
      - step:
          name: Package and Push Helm Chart
          script:
            - pipe: docker://nayaksuraj/helm-pipe:1.0.0
              variables:
                HELM_CHART_PATH: "./helm-chart"
                CHART_VERSION: "1.0.0-${BITBUCKET_COMMIT:0:7}"
                HELM_REGISTRY: $HELM_REGISTRY
                HELM_REGISTRY_USERNAME: $HELM_REGISTRY_USERNAME
                HELM_REGISTRY_PASSWORD: $HELM_REGISTRY_PASSWORD
                LINT_CHART: "true"
                PACKAGE_CHART: "true"
                PUSH_CHART: "true"

  # Tagged Releases - Production Release
  tags:
    'v*':
      - step:
          name: Release Helm Chart
          script:
            - pipe: docker://nayaksuraj/helm-pipe:1.0.0
              variables:
                HELM_CHART_PATH: "./helm-chart"
                CHART_VERSION: "${BITBUCKET_TAG#v}"  # Remove 'v' prefix
                HELM_REGISTRY: $HELM_REGISTRY
                HELM_REGISTRY_USERNAME: $HELM_REGISTRY_USERNAME
                HELM_REGISTRY_PASSWORD: $HELM_REGISTRY_PASSWORD
                LINT_CHART: "true"
                PACKAGE_CHART: "true"
                PUSH_CHART: "true"
          artifacts:
            - helm-packages/**
```

## ✅ Best Practices

### 1. Semantic Versioning

Use semantic versioning for chart versions:

```yaml
# Production release
CHART_VERSION: "1.2.3"

# Pre-release
CHART_VERSION: "1.2.3-rc.1"

# Development
CHART_VERSION: "1.2.3-dev.${BITBUCKET_COMMIT:0:7}"
```

### 2. Secure Credentials

- ✅ Always mark `HELM_REGISTRY_PASSWORD` as **SECURED**
- ✅ Use short-lived tokens when possible
- ✅ Rotate credentials regularly
- ✅ Use service accounts, not personal accounts
- ❌ Never hardcode credentials in pipeline YAML

### 3. Multi-Environment Charts

```
helm-chart/
├── Chart.yaml
├── values.yaml               # Default values
├── values-dev.yaml          # Development overrides
├── values-staging.yaml      # Staging overrides
└── values-production.yaml   # Production overrides
```

### 4. Chart Versioning Strategy

```yaml
# Development builds
CHART_VERSION: "0.0.0-dev.${BITBUCKET_BUILD_NUMBER}"

# Staging builds
CHART_VERSION: "0.0.0-staging.${BITBUCKET_COMMIT:0:7}"

# Production releases (from tags)
CHART_VERSION: "${BITBUCKET_TAG#v}"  # v1.2.3 → 1.2.3
```

### 5. Registry Organization

```
# Organize by application
oci://registry/charts/myapp

# Or by environment
oci://registry/production/myapp
oci://registry/staging/myapp

# Or by team
oci://registry/team-backend/myapp
oci://registry/team-frontend/webapp
```

## 🔍 Troubleshooting

### Authentication Failures

```bash
# Error: failed to authorize: failed to fetch anonymous token
# Solution: Verify credentials are correct

# Test authentication manually
helm registry login $HELM_REGISTRY \
  --username $HELM_REGISTRY_USERNAME \
  --password $HELM_REGISTRY_PASSWORD
```

### Version Already Exists

```bash
# Error: version 1.0.0 already exists
# Solution: Bump version or delete existing chart

# Delete from GHCR
gh api --method DELETE \
  /user/packages/container/charts%2Fmyapp/versions/VERSION_ID

# Delete from Harbor
curl -X DELETE \
  https://harbor.example.com/api/v2.0/projects/charts/repositories/myapp/artifacts/1.0.0
```

### OCI Format Issues

```bash
# Error: unsupported protocol scheme
# Solution: Ensure registry URL starts with oci://

# ✅ Correct
HELM_REGISTRY=oci://ghcr.io/org/charts

# ❌ Wrong
HELM_REGISTRY=ghcr.io/org/charts
HELM_REGISTRY=https://ghcr.io/org/charts
```

### Push Timeout

```bash
# Error: timeout waiting for push
# Solution: Increase timeout or check network

# Check chart size
du -h helm-packages/*.tgz

# Large charts may need longer timeout
# Consider splitting into multiple charts
```

## 📚 Additional Resources

- [Helm OCI Support](https://helm.sh/docs/topics/registries/)
- [GitHub Packages Documentation](https://docs.github.com/en/packages)
- [AWS ECR Helm Support](https://docs.aws.amazon.com/AmazonECR/latest/userguide/push-oci-artifact.html)
- [Azure ACR Helm Charts](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-helm-repos)
- [Google Artifact Registry](https://cloud.google.com/artifact-registry/docs/helm)
- [Harbor Documentation](https://goharbor.io/docs/)

---

**Maintained by**: DevOps Team
**Last Updated**: 2025-11-15
**Review Cycle**: Quarterly
