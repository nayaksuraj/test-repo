# Reusable Bitbucket Pipeline - Usage Guide

This guide explains how to reuse the `bitbucket-pipelines.yml` configuration in any project.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Configuration](#configuration)
4. [Supported Project Types](#supported-project-types)
5. [Customization Examples](#customization-examples)
6. [Advanced Usage](#advanced-usage)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This pipeline configuration is designed to be **project-agnostic** and **easily customizable**. It supports:

- **Multiple build tools**: Maven, Gradle, npm, yarn, Python pip, etc.
- **Flexible deployment**: Customizable via environment variables
- **Security scanning**: Optional security checks
- **Branch workflows**: Different pipelines for different branch types
- **Manual controls**: Custom pipelines for specific scenarios

---

## Quick Start

### Step 1: Copy the Pipeline File

Copy `bitbucket-pipelines.yml` from this repository to your project's root directory:

```bash
cp bitbucket-pipelines.yml /path/to/your/project/
```

### Step 2: Customize the Docker Image (Optional)

Edit the first line of `bitbucket-pipelines.yml` to match your project's needs:

```yaml
# For Java/Maven projects
image: maven:3.8.6-openjdk-17

# For Node.js projects
image: node:18

# For Python projects
image: python:3.11

# For Gradle projects
image: gradle:8.0-jdk17

# For .NET projects
image: mcr.microsoft.com/dotnet/sdk:7.0
```

### Step 3: Configure Build Commands

Set up repository variables in Bitbucket:

1. Go to your repository in Bitbucket
2. Click **Repository Settings** → **Pipelines** → **Repository Variables**
3. Add your custom build commands (see [Configuration](#configuration) section)

### Step 4: Push and Test

Commit and push the pipeline file to trigger your first build:

```bash
git add bitbucket-pipelines.yml
git commit -m "Add reusable Bitbucket pipeline"
git push
```

---

## Configuration

### Required Variables (Set in Bitbucket Repository Variables)

These variables customize the pipeline for your specific project:

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `BUILD_COMMAND` | Command to build your project | `mvn clean compile` | `npm run build` |
| `TEST_COMMAND` | Command to run tests | `mvn test` | `npm test` |
| `PACKAGE_COMMAND` | Command to package the app | `mvn package -DskipTests` | `npm run package` |
| `QUALITY_COMMAND` | Code quality/linting command | `mvn verify -DskipTests` | `npm run lint` |
| `ARTIFACT_PATH` | Path to build artifacts | `target/*.jar` | `dist/**` |
| `DEPLOY_STAGING_SCRIPT` | Staging deployment commands | _(empty)_ | See examples below |
| `DEPLOY_PRODUCTION_SCRIPT` | Production deployment commands | _(empty)_ | See examples below |

### Optional Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SONAR_TOKEN` | SonarQube authentication token | `abc123...` |
| `SONAR_HOST_URL` | SonarQube server URL | `https://sonar.company.com` |
| `SNYK_TOKEN` | Snyk security scanning token | `xyz789...` |
| `DOCKER_IMAGE` | Docker image name for builds | `myapp:latest` |

---

## Supported Project Types

### Java (Maven)

**No configuration needed!** The default values work out of the box.

```yaml
image: maven:3.8.6-openjdk-17
```

### Java (Gradle)

**Repository Variables:**
```
BUILD_COMMAND = gradle clean build -x test
TEST_COMMAND = gradle test
PACKAGE_COMMAND = gradle build -x test
QUALITY_COMMAND = gradle check -x test
ARTIFACT_PATH = build/libs/*.jar
```

**Docker Image:**
```yaml
image: gradle:8.0-jdk17
```

### Node.js (npm)

**Repository Variables:**
```
BUILD_COMMAND = npm ci && npm run build
TEST_COMMAND = npm test
PACKAGE_COMMAND = npm run build
QUALITY_COMMAND = npm run lint
ARTIFACT_PATH = dist/**
```

**Docker Image:**
```yaml
image: node:18
```

### Node.js (yarn)

**Repository Variables:**
```
BUILD_COMMAND = yarn install && yarn build
TEST_COMMAND = yarn test
PACKAGE_COMMAND = yarn build
QUALITY_COMMAND = yarn lint
ARTIFACT_PATH = dist/**
```

**Docker Image:**
```yaml
image: node:18
```

### Python

**Repository Variables:**
```
BUILD_COMMAND = pip install -r requirements.txt
TEST_COMMAND = pytest
PACKAGE_COMMAND = python setup.py sdist bdist_wheel
QUALITY_COMMAND = flake8 . && black --check .
ARTIFACT_PATH = dist/**
```

**Docker Image:**
```yaml
image: python:3.11
```

### .NET

**Repository Variables:**
```
BUILD_COMMAND = dotnet build
TEST_COMMAND = dotnet test
PACKAGE_COMMAND = dotnet publish -c Release -o out
QUALITY_COMMAND = dotnet format --verify-no-changes
ARTIFACT_PATH = out/**
```

**Docker Image:**
```yaml
image: mcr.microsoft.com/dotnet/sdk:7.0
```

### Go

**Repository Variables:**
```
BUILD_COMMAND = go build ./...
TEST_COMMAND = go test ./...
PACKAGE_COMMAND = go build -o app
QUALITY_COMMAND = golangci-lint run
ARTIFACT_PATH = app
```

**Docker Image:**
```yaml
image: golang:1.21
```

---

## Customization Examples

### Example 1: Node.js Project with Docker Deployment

**bitbucket-pipelines.yml** (modify image):
```yaml
image: node:18
```

**Repository Variables:**
```
BUILD_COMMAND = npm ci && npm run build
TEST_COMMAND = npm test
PACKAGE_COMMAND = npm run build
QUALITY_COMMAND = npm run lint
ARTIFACT_PATH = dist/**

DEPLOY_STAGING_SCRIPT = docker build -t myapp:staging . && docker push registry.example.com/myapp:staging && ssh user@staging-server 'docker pull registry.example.com/myapp:staging && docker-compose up -d'

DEPLOY_PRODUCTION_SCRIPT = docker build -t myapp:latest . && docker push registry.example.com/myapp:latest && ssh user@prod-server 'docker pull registry.example.com/myapp:latest && docker-compose up -d'
```

### Example 2: Python Flask Application with AWS Deployment

**bitbucket-pipelines.yml** (modify image):
```yaml
image: python:3.11
```

**Repository Variables:**
```
BUILD_COMMAND = pip install -r requirements.txt
TEST_COMMAND = pytest tests/
PACKAGE_COMMAND = pip install -r requirements.txt && python -m compileall .
QUALITY_COMMAND = flake8 . && black --check . && pylint app/
ARTIFACT_PATH = **/*.pyc

DEPLOY_STAGING_SCRIPT = pip install awscli && aws s3 sync . s3://staging-bucket/ --exclude "*.git*" && aws elasticbeanstalk update-environment --environment-name staging-env --version-label $BITBUCKET_BUILD_NUMBER

DEPLOY_PRODUCTION_SCRIPT = pip install awscli && aws s3 sync . s3://prod-bucket/ --exclude "*.git*" && aws elasticbeanstalk update-environment --environment-name prod-env --version-label $BITBUCKET_BUILD_NUMBER
```

### Example 3: React App with S3/CloudFront Deployment

**bitbucket-pipelines.yml** (modify image):
```yaml
image: node:18
```

**Repository Variables:**
```
BUILD_COMMAND = npm ci && npm run build
TEST_COMMAND = npm test -- --coverage
PACKAGE_COMMAND = npm run build
QUALITY_COMMAND = npm run lint && npm run type-check
ARTIFACT_PATH = build/**

DEPLOY_STAGING_SCRIPT = npm install -g aws-cli && aws s3 sync build/ s3://staging-website-bucket/ --delete && aws cloudfront create-invalidation --distribution-id E1234STAGING --paths "/*"

DEPLOY_PRODUCTION_SCRIPT = npm install -g aws-cli && aws s3 sync build/ s3://prod-website-bucket/ --delete && aws cloudfront create-invalidation --distribution-id E1234PROD --paths "/*"
```

### Example 4: Spring Boot with Kubernetes Deployment

**Repository Variables:**
```
# Use default Maven commands (no need to set BUILD_COMMAND, etc.)

DEPLOY_STAGING_SCRIPT = kubectl config use-context staging-cluster && kubectl set image deployment/myapp myapp=registry.example.com/myapp:$BITBUCKET_COMMIT --record && kubectl rollout status deployment/myapp

DEPLOY_PRODUCTION_SCRIPT = kubectl config use-context prod-cluster && kubectl set image deployment/myapp myapp=registry.example.com/myapp:$BITBUCKET_COMMIT --record && kubectl rollout status deployment/myapp
```

---

## Advanced Usage

### Using Multiple Build Tools

If your project uses multiple build tools, you can chain commands:

```
BUILD_COMMAND = mvn clean compile && npm install && npm run build-frontend
```

### Conditional Execution

Use shell conditionals in your commands:

```
BUILD_COMMAND = if [ -f pom.xml ]; then mvn clean compile; elif [ -f package.json ]; then npm ci && npm run build; fi
```

### Secret Management

For sensitive data (API keys, passwords), use Bitbucket's **Secured Variables**:

1. Go to **Repository Settings** → **Pipelines** → **Repository Variables**
2. Check the **Secured** checkbox when creating the variable
3. Secured variables are masked in logs and cannot be viewed after creation

Example:
```
DEPLOY_PRODUCTION_SCRIPT = echo $DATABASE_PASSWORD | docker login -u myuser --password-stdin registry.example.com && docker push myapp:latest
```

### Parallel Steps

Modify the pipeline to run steps in parallel for faster builds:

```yaml
pipelines:
  default:
    - parallel:
      - step: *build-and-test
      - step: *security-scan
```

### Cache Optimization

The pipeline already includes common caches. To add custom caches:

```yaml
definitions:
  caches:
    composer: ~/.composer/cache  # PHP Composer
    pip: ~/.cache/pip             # Python pip
    cargo: ~/.cargo               # Rust cargo
```

---

## Pipeline Workflows

### Branch-Based Workflows

The pipeline automatically runs different workflows based on branch names:

| Branch Pattern | Workflow | Description |
|----------------|----------|-------------|
| `main`, `master` | Build → Test → Quality → Deploy Staging | Main branch gets full CI/CD |
| `develop` | Build → Test → Quality | Development branch for testing |
| `feature/**` | Build → Test | Feature branches for new work |
| `hotfix/**` | Build → Test → Quality → Deploy Staging | Urgent fixes |
| Other branches | Build → Test | Default workflow |

### Tag-Based Deployments

Create tags to trigger production deployments:

```bash
# For release tags
git tag release-1.0.0
git push origin release-1.0.0

# For version tags
git tag v1.0.0
git push origin v1.0.0
```

Both will trigger: Build → Test → Quality → Security → **Deploy Production** (manual approval required)

### Pull Request Pipeline

Every pull request automatically runs:
- Build and Test
- Code Quality checks

This ensures code quality before merging.

### Custom Manual Pipelines

Run these from the Bitbucket UI (**Pipelines** → **Run Pipeline** → **Custom**):

- **build-only**: Quick build without tests (for debugging)
- **quality-check**: Full quality analysis without deployment
- **deploy-staging-only**: Deploy to staging without rebuilding
- **full-pipeline**: Complete pipeline including production deploy
- **emergency-deploy**: Emergency production deployment (use with caution!)

---

## Troubleshooting

### Pipeline Fails on First Run

**Problem**: Variables not set correctly

**Solution**: Ensure all required variables are set in Repository Settings → Pipelines → Repository Variables

### Cache Not Working

**Problem**: Builds are slow, dependencies download every time

**Solution**:
1. Verify cache definitions in `bitbucket-pipelines.yml`
2. Check that caches are enabled in Repository Settings
3. Clear caches from Bitbucket UI if corrupted

### Deployment Step Skipped

**Problem**: Deployment script doesn't run

**Solution**:
1. Check that `DEPLOY_STAGING_SCRIPT` or `DEPLOY_PRODUCTION_SCRIPT` is set
2. Verify deployment environment is configured in Bitbucket
3. Check branch/tag matches the pipeline configuration

### Artifacts Not Available

**Problem**: Build artifacts missing in deployment step

**Solution**:
1. Verify `ARTIFACT_PATH` variable is correct
2. Check artifacts section in pipeline step definition
3. Ensure artifacts are created in the build step

### Permission Denied Errors

**Problem**: Pipeline can't access servers or services

**Solution**:
1. Add SSH keys in Repository Settings → Pipelines → SSH Keys
2. Set AWS credentials as secured variables
3. Configure kubectl/docker authentication in deployment scripts

---

## Best Practices

### 1. Use Secured Variables for Secrets

Always mark sensitive data as **Secured** in Bitbucket variables.

### 2. Test in Feature Branches First

Develop and test pipeline changes in feature branches before merging to main.

### 3. Use Manual Triggers for Production

Keep production deployments as manual triggers to prevent accidental deployments.

### 4. Monitor Build Times

Regularly review pipeline execution times and optimize slow steps.

### 5. Version Your Pipeline

Commit pipeline changes with clear messages describing what changed.

### 6. Document Custom Variables

Add comments in your repository documenting any custom variables used.

### 7. Use Caching Effectively

Enable caching for dependencies to speed up builds, but clear caches if you encounter strange issues.

---

## Migration Checklist

Use this checklist when migrating this pipeline to a new project:

- [ ] Copy `bitbucket-pipelines.yml` to project root
- [ ] Update Docker `image` to match project language/framework
- [ ] Set `BUILD_COMMAND` in Repository Variables
- [ ] Set `TEST_COMMAND` in Repository Variables
- [ ] Set `PACKAGE_COMMAND` in Repository Variables
- [ ] Set `QUALITY_COMMAND` in Repository Variables (optional)
- [ ] Set `ARTIFACT_PATH` in Repository Variables
- [ ] Configure `DEPLOY_STAGING_SCRIPT` (if needed)
- [ ] Configure `DEPLOY_PRODUCTION_SCRIPT` (if needed)
- [ ] Set up deployment environments in Bitbucket
- [ ] Add any required secured variables (API keys, passwords)
- [ ] Configure SSH keys if needed for deployment
- [ ] Test pipeline with a feature branch
- [ ] Adjust branch workflows if needed
- [ ] Update project README with pipeline info
- [ ] Train team on using custom pipelines

---

## Support and Contribution

For issues or improvements to this reusable pipeline:

1. Review the [Bitbucket Pipelines Documentation](https://support.atlassian.com/bitbucket-cloud/docs/get-started-with-bitbucket-pipelines/)
2. Check the troubleshooting section above
3. Consult your team's DevOps/CI-CD experts

---

## Example Projects Using This Pipeline

Here are examples of how this pipeline is used across different project types:

### Java Spring Boot (Current Project)
- **Image**: `maven:3.8.6-openjdk-17`
- **Variables**: Default Maven commands
- **Use Case**: REST API with staging/production deployments

### React Web Application
- **Image**: `node:18`
- **Variables**: npm build commands
- **Use Case**: Frontend deployment to S3/CloudFront

### Python API
- **Image**: `python:3.11`
- **Variables**: pip, pytest, flake8
- **Use Case**: Flask/Django API deployment

---

## Quick Reference

### Most Common Commands by Language

```bash
# Java Maven
BUILD_COMMAND=mvn clean compile
TEST_COMMAND=mvn test
PACKAGE_COMMAND=mvn package -DskipTests

# Node.js
BUILD_COMMAND=npm ci && npm run build
TEST_COMMAND=npm test
PACKAGE_COMMAND=npm run build

# Python
BUILD_COMMAND=pip install -r requirements.txt
TEST_COMMAND=pytest
PACKAGE_COMMAND=python setup.py sdist bdist_wheel

# Go
BUILD_COMMAND=go build ./...
TEST_COMMAND=go test ./...
PACKAGE_COMMAND=go build -o app
```

---

**Last Updated**: 2025-10-20

**Version**: 1.0.0
