# Pipeline Library Setup Guide

## 📚 Creating Your Reusable Pipeline Library

This guide walks you through creating a centralized pipeline library similar to GitHub's composite actions, but for Bitbucket Pipelines.

---

## 🎯 Goal

Create a separate repository (`bitbucket-pipeline-library`) that contains:
- **Bitbucket Pipes** (reusable Docker-based steps)
- **Docker Toolbox** (all-in-one security tools image)
- **Shared Scripts** (security scanning scripts)
- **Documentation** (usage examples and guides)

---

## 📋 Step-by-Step Setup

### Step 1: Create the Pipeline Library Repository

```bash
# Create new repository in Bitbucket
# Repository name: bitbucket-pipeline-library
# Organization: yourorg

# Clone the repository
git clone https://bitbucket.org/yourorg/bitbucket-pipeline-library.git
cd bitbucket-pipeline-library
```

### Step 2: Copy the Library Structure

From this repository (test-repo), copy the `.pipeline-library` directory:

```bash
# In your test-repo directory
cd /path/to/test-repo

# Copy the pipeline library structure
cp -r .pipeline-library/* /path/to/bitbucket-pipeline-library/

# Or manually copy:
# - .pipeline-library/pipes/ → pipes/
# - .pipeline-library/docker/ → docker/
# - .pipeline-library/scripts/ → scripts/  (copy from scripts/security-*.sh)
# - .pipeline-library/README.md → README.md
```

### Step 3: Create Directory Structure

Your pipeline library repository should look like this:

```
bitbucket-pipeline-library/
├── pipes/                          # Bitbucket Pipes (Docker-based)
│   ├── secrets-scan/
│   │   ├── pipe.yml
│   │   ├── Dockerfile
│   │   ├── pipe.sh
│   │   ├── common.sh
│   │   └── README.md
│   ├── dependency-scan/
│   ├── sbom-generate/
│   ├── dockerfile-scan/
│   ├── container-scan/
│   └── iac-scan/
├── docker/                         # Docker images
│   └── devsecops-toolbox/
│       ├── Dockerfile
│       ├── build-and-push.sh
│       ├── README.md
│       └── scripts/                # Embedded scripts
├── scripts/                        # Standalone scripts
│   └── security/
│       ├── security-secrets-scan.sh
│       ├── security-sca-scan.sh
│       ├── security-sbom-generate.sh
│       ├── security-dockerfile-scan.sh
│       ├── security-container-scan.sh
│       └── security-iac-scan.sh
├── docs/
│   ├── usage.md
│   └── examples.md
└── README.md
```

### Step 4: Copy Security Scripts

```bash
# In bitbucket-pipeline-library repository
mkdir -p scripts/security

# Copy security scripts from test-repo
cp /path/to/test-repo/scripts/security-*.sh scripts/security/

# Also copy to Docker toolbox
mkdir -p docker/devsecops-toolbox/scripts/security
cp scripts/security/* docker/devsecops-toolbox/scripts/security/
```

### Step 5: Build and Publish Pipes

Each pipe needs to be built and pushed to a Docker registry.

#### 5a. Build Secrets Scan Pipe

```bash
cd pipes/secrets-scan

# Build the Docker image
docker build -t yourorg/secrets-scan-pipe:1.0.0 .

# Tag as latest
docker tag yourorg/secrets-scan-pipe:1.0.0 yourorg/secrets-scan-pipe:latest

# Test locally
docker run --rm -v $(pwd):/workspace yourorg/secrets-scan-pipe:1.0.0

# Push to Docker Hub (or your private registry)
docker push yourorg/secrets-scan-pipe:1.0.0
docker push yourorg/secrets-scan-pipe:latest
```

#### 5b. Build Dependency Scan Pipe

```bash
cd ../dependency-scan

# Create similar structure as secrets-scan
# Copy pipe.yml, Dockerfile, pipe.sh, common.sh
# Modify for dependency scanning

docker build -t yourorg/dependency-scan-pipe:1.0.0 .
docker push yourorg/dependency-scan-pipe:1.0.0
```

#### 5c. Build All Pipes

```bash
# Automated script to build all pipes
cat > build-all-pipes.sh << 'EOF'
#!/bin/bash
set -e

PIPES=("secrets-scan" "dependency-scan" "sbom-generate" "dockerfile-scan" "container-scan" "iac-scan")
VERSION="1.0.0"
REGISTRY="yourorg"

for pipe in "${PIPES[@]}"; do
    echo "Building $pipe..."
    cd pipes/$pipe
    docker build -t ${REGISTRY}/${pipe}-pipe:${VERSION} .
    docker tag ${REGISTRY}/${pipe}-pipe:${VERSION} ${REGISTRY}/${pipe}-pipe:latest
    docker push ${REGISTRY}/${pipe}-pipe:${VERSION}
    docker push ${REGISTRY}/${pipe}-pipe:latest
    cd ../..
done

echo "All pipes built and pushed!"
EOF

chmod +x build-all-pipes.sh
./build-all-pipes.sh
```

### Step 6: Build and Publish DevSecOps Toolbox

```bash
cd docker/devsecops-toolbox

# Build the toolbox image
docker build -t yourorg/devsecops-toolbox:1.0.0 .

# Or use the build script
chmod +x build-and-push.sh
./build-and-push.sh push
```

### Step 7: Test the Components

#### Test a Pipe Locally

```bash
# Test secrets scan pipe
cd /path/to/test-repo
docker run --rm -v $(pwd):/workspace \
    -e FAIL_ON_SECRETS=true \
    -e SCAN_PATH="." \
    yourorg/secrets-scan-pipe:1.0.0
```

#### Test Toolbox Image

```bash
# Test toolbox image
docker run --rm -it yourorg/devsecops-toolbox:1.0.0 bash

# Inside container, verify tools are installed
gitleaks version
trivy --version
hadolint --version
checkov --version
```

### Step 8: Commit and Push Pipeline Library

```bash
cd /path/to/bitbucket-pipeline-library

git add .
git commit -m "Initial commit: DevSecOps pipeline library

- Bitbucket Pipes for security scanning
- DevSecOps toolbox Docker image
- Shared security scripts
- Documentation and examples"

git push origin main
```

---

## 🔄 Using the Pipeline Library in Your Applications

### Method 1: Using Bitbucket Pipes (Recommended)

In your application repository's `bitbucket-pipelines.yml`:

```yaml
image: maven:3.8.6-openjdk-17

pipelines:
  default:
    # Use your custom pipe
    - pipe: docker://yourorg/secrets-scan-pipe:1.0.0
      variables:
        FAIL_ON_SECRETS: true

    - pipe: docker://yourorg/dependency-scan-pipe:1.0.0
      variables:
        CVSS_THRESHOLD: 7.0
        FAIL_ON_CVSS: true

    - step:
        name: Build
        script:
          - mvn clean package
```

See: [bitbucket-pipelines-using-pipes.yml](./bitbucket-pipelines-using-pipes.yml)

### Method 2: Using DevSecOps Toolbox Image

```yaml
image: yourorg/devsecops-toolbox:1.0.0

definitions:
  scripts:
    - &download-scripts |
      git clone --depth 1 https://bitbucket.org/yourorg/bitbucket-pipeline-library.git /tmp/lib
      cp -r /tmp/lib/scripts/* ./scripts/

pipelines:
  default:
    - step:
        name: Security Scans
        script:
          - *download-scripts
          - ./scripts/security/security-secrets-scan.sh
          - ./scripts/security/security-sca-scan.sh
```

See: [bitbucket-pipelines-using-toolbox.yml](./bitbucket-pipelines-using-toolbox.yml)

### Method 3: Direct Script Download

```yaml
image: maven:3.8.6-openjdk-17

pipelines:
  default:
    - step:
        name: Download Security Scripts
        script:
          - apt-get update && apt-get install -y git
          - git clone --depth 1 https://bitbucket.org/yourorg/bitbucket-pipeline-library.git /tmp/lib
          - cp -r /tmp/lib/scripts/security ./scripts/
          - chmod +x scripts/*.sh
        artifacts:
          - scripts/**

    - step:
        name: Run Security Scans
        script:
          - ./scripts/security-secrets-scan.sh
```

---

## 📊 Comparison of Methods

| Feature | Pipes | Toolbox Image | Script Download |
|---------|-------|---------------|-----------------|
| **Setup Complexity** | High (build & publish) | Medium (build image) | Low (git clone) |
| **Pipeline Speed** | Fast | Fastest | Slowest |
| **Maintenance** | Easy (version tags) | Easy (one image) | Manual |
| **Bitbucket Native** | ✅ Yes | ❌ No | ❌ No |
| **Version Control** | ✅ Excellent | ✅ Good | ⚠️ Branch-based |
| **Best For** | Production | Multiple apps | Quick prototypes |

---

## 🔧 Maintenance

### Updating a Pipe

```bash
# Update pipe code
cd pipes/secrets-scan
# Make changes to pipe.sh or Dockerfile

# Bump version
VERSION=1.1.0

# Rebuild and push
docker build -t yourorg/secrets-scan-pipe:${VERSION} .
docker push yourorg/secrets-scan-pipe:${VERSION}

# Update pipe.yml
sed -i "s/{{version}}/${VERSION}/g" pipe.yml
```

### Updating Toolbox Image

```bash
cd docker/devsecops-toolbox

# Update tool versions in Dockerfile
# ARG GITLEAKS_VERSION=8.19.0

VERSION=1.1.0
docker build -t yourorg/devsecops-toolbox:${VERSION} .
docker push yourorg/devsecops-toolbox:${VERSION}
```

### Updating Scripts

```bash
# Update script
vim scripts/security/security-secrets-scan.sh

# Commit and push
git add scripts/security/security-secrets-scan.sh
git commit -m "Update secrets scan script: fix issue #123"
git push

# Applications using script download will get updates automatically
# Applications using pipes/toolbox need to rebuild/update version
```

---

## 🔐 Private Registry Setup (Optional)

If you want to use a private Docker registry:

### AWS ECR

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    123456789.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t 123456789.dkr.ecr.us-east-1.amazonaws.com/secrets-scan-pipe:1.0.0 .
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/secrets-scan-pipe:1.0.0

# Use in pipeline
- pipe: docker://123456789.dkr.ecr.us-east-1.amazonaws.com/secrets-scan-pipe:1.0.0
```

### Azure Container Registry

```bash
# Login to ACR
az acr login --name myregistry

# Build and push
docker build -t myregistry.azurecr.io/secrets-scan-pipe:1.0.0 .
docker push myregistry.azurecr.io/secrets-scan-pipe:1.0.0
```

### Self-Hosted Registry

```bash
# Login
docker login myregistry.company.com

# Build and push
docker build -t myregistry.company.com/secrets-scan-pipe:1.0.0 .
docker push myregistry.company.com/secrets-scan-pipe:1.0.0
```

---

## 📝 Migration Checklist

- [ ] Create `bitbucket-pipeline-library` repository
- [ ] Copy `.pipeline-library` structure
- [ ] Copy security scripts
- [ ] Build and test secrets-scan pipe
- [ ] Build and test dependency-scan pipe
- [ ] Build and test other pipes (SBOM, Dockerfile, Container, IaC)
- [ ] Build and test DevSecOps toolbox image
- [ ] Push all images to Docker registry
- [ ] Update application pipelines to use pipes/toolbox
- [ ] Test in staging environment
- [ ] Roll out to production
- [ ] Document for team
- [ ] Set up automated builds (optional)

---

## 🚀 Quick Start (TL;DR)

```bash
# 1. Create repository
git clone https://bitbucket.org/yourorg/bitbucket-pipeline-library.git
cd bitbucket-pipeline-library

# 2. Copy structure from test-repo
cp -r /path/to/test-repo/.pipeline-library/* .

# 3. Build and push (replace 'yourorg')
cd docker/devsecops-toolbox
docker build -t yourorg/devsecops-toolbox:1.0.0 .
docker push yourorg/devsecops-toolbox:1.0.0

cd ../../pipes/secrets-scan
docker build -t yourorg/secrets-scan-pipe:1.0.0 .
docker push yourorg/secrets-scan-pipe:1.0.0

# 4. Use in your app
# See bitbucket-pipelines-using-pipes.yml or
#     bitbucket-pipelines-using-toolbox.yml
```

---

## 📖 Next Steps

1. **Read**: [REUSABLE_PIPELINES_GUIDE.md](./REUSABLE_PIPELINES_GUIDE.md) - Detailed guide
2. **Examples**:
   - [bitbucket-pipelines-using-pipes.yml](./bitbucket-pipelines-using-pipes.yml)
   - [bitbucket-pipelines-using-toolbox.yml](./bitbucket-pipelines-using-toolbox.yml)
3. **Implement**: Start with Method 2 (Toolbox) - easiest to get started
4. **Migrate**: Move to Method 1 (Pipes) for production use
5. **Maintain**: Version and document all changes

---

## 🆘 Troubleshooting

### Pipe not found

```
Error: Pipe not found: docker://yourorg/secrets-scan-pipe:1.0.0
```

**Solution**: Ensure the image is pushed to Docker Hub or your registry is accessible.

### Authentication failed

```
Error: authentication required
```

**Solution**: Configure Docker credentials in Bitbucket repository variables:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_PASSWORD`

### Tools not found in toolbox

```
Error: gitleaks: command not found
```

**Solution**: Rebuild the toolbox image and verify tools are installed.

---

## 📞 Support

- Repository: https://bitbucket.org/yourorg/bitbucket-pipeline-library
- Issues: Create issue in pipeline library repo
- Documentation: See `docs/` folder

---

**Happy Pipeline Building! 🚀**
