# Build Scripts

This folder contains scripts used by the Bitbucket Pipeline for CI/CD automation. By using scripts instead of hardcoded commands, you have full control over your build, test, and deployment processes regardless of programming language or framework.

## Overview

The pipeline calls these scripts at different stages:

| Script | Purpose | Called By |
|--------|---------|-----------|
| `build.sh` | Build your application | Build and Test step |
| `test.sh` | Run tests | Build and Test step |
| `package.sh` | Package application for deployment | Build and Test step |
| `deploy-staging.sh` | Deploy to staging environment | Staging deployment step |
| `deploy-production.sh` | Deploy to production environment | Production deployment step |
| `quality.sh` | (Optional) Code quality checks | Code Quality step |

## Getting Started

### 1. Choose Your Language

Each script contains commented examples for multiple programming languages and frameworks:

- **Java**: Maven, Gradle
- **Node.js**: npm, Yarn
- **Python**: pip, setup.py
- **Go**: go build
- **.NET**: dotnet
- **Rust**: cargo
- **PHP**: composer
- **Ruby**: bundler

### 2. Customize Scripts

Edit the scripts to match your project:

1. Open the script (e.g., `build.sh`)
2. Find the section for your language
3. Uncomment that section
4. Customize as needed
5. Comment out or remove sections you don't need

### 3. Test Locally

Before pushing, test your scripts locally:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Test build
./scripts/build.sh

# Test tests
./scripts/test.sh

# Test packaging
./scripts/package.sh
```

## Script Details

### build.sh

**Purpose**: Compile your code and prepare it for testing.

**When it runs**: First step in the pipeline

**Auto-detection**: Currently configured to auto-detect Maven projects (pom.xml)

**Example for Java/Maven**:
```bash
if [ -f "pom.xml" ]; then
    echo "Detected Maven project"
    mvn clean compile
    exit 0
fi
```

**Example for Node.js**:
```bash
if [ -f "package.json" ]; then
    echo "Detected Node.js project"
    npm install
    npm run build
    exit 0
fi
```

### test.sh

**Purpose**: Run your test suite.

**When it runs**: After build completes

**Current configuration**: Auto-detects Maven projects

**Example for Python/pytest**:
```bash
if [ -f "requirements.txt" ]; then
    echo "Running Python tests"
    pip install -r requirements.txt
    pytest
    exit 0
fi
```

### package.sh

**Purpose**: Create deployment artifacts (JARs, Docker images, etc.).

**When it runs**: After tests pass

**Current configuration**: Packages Maven projects

**Example for Docker**:
```bash
if [ -f "Dockerfile" ]; then
    docker build -t myapp:${BITBUCKET_COMMIT} .
    exit 0
fi
```

### deploy-staging.sh

**Purpose**: Deploy to your staging/QA environment.

**When it runs**: After packaging (on main/master branches)

**Common deployment methods included**:
- SSH/SCP deployment
- Docker deployment
- Kubernetes deployment
- AWS S3/CloudFront
- Heroku
- Google Cloud Run
- Azure Web Apps

**Example for Docker**:
```bash
docker push myregistry/myapp:staging
ssh user@staging-server "docker pull myregistry/myapp:staging && docker restart myapp"
```

### deploy-production.sh

**Purpose**: Deploy to production environment.

**When it runs**: Manual trigger or on version tags

**Security note**: This requires manual approval in the pipeline

**Example with health checks**:
```bash
# Deploy
scp target/*.jar user@prod:/app/

# Restart service
ssh user@prod "systemctl restart myapp"

# Health check
sleep 10
curl -f https://myapp.com/health || exit 1
```

### quality.sh (Optional)

**Purpose**: Run code quality and linting tools.

**When it runs**: After tests in the quality step

**To use**: Create this file and add your quality checks

**Examples**:
```bash
# SonarQube
mvn sonar:sonar -Dsonar.host.url=$SONAR_URL -Dsonar.login=$SONAR_TOKEN

# ESLint for JavaScript
npm run lint

# Checkstyle for Java
mvn checkstyle:check
```

## Available Environment Variables

These Bitbucket-provided variables are available in your scripts:

- `$BITBUCKET_REPO_SLUG`: Repository name
- `$BITBUCKET_BRANCH`: Current branch
- `$BITBUCKET_COMMIT`: Commit hash
- `$BITBUCKET_TAG`: Git tag (if triggered by tag)
- `$BITBUCKET_BUILD_NUMBER`: Build number

You can also set custom variables in Repository Settings > Repository Variables.

## Best Practices

### 1. Exit on Error
Always use `set -e` at the top of your scripts to fail fast:
```bash
#!/bin/bash
set -e  # Exit immediately if any command fails
```

### 2. Auto-Detection
Use file detection to automatically identify your project type:
```bash
if [ -f "pom.xml" ]; then
    # Maven build
elif [ -f "package.json" ]; then
    # Node.js build
fi
```

### 3. Clear Output
Add echo statements to make logs easier to read:
```bash
echo "=== Building application ==="
mvn clean package
echo "=== Build complete ==="
```

### 4. Health Checks
Always verify deployments succeeded:
```bash
# Deploy
./deploy-app.sh

# Verify
curl -f https://myapp.com/health || exit 1
```

### 5. Secrets Management
Use Bitbucket Repository Variables for sensitive data:
- Never hardcode passwords or API keys
- Set secrets in: Repository Settings > Repository Variables
- Mark them as "Secured" so they're not visible in logs
- Reference them as: `$MY_SECRET_VAR`

## Multi-Language Projects

If your project uses multiple languages:

```bash
# Example: Frontend + Backend

# Build frontend
if [ -f "frontend/package.json" ]; then
    cd frontend
    npm install
    npm run build
    cd ..
fi

# Build backend
if [ -f "backend/pom.xml" ]; then
    cd backend
    mvn clean package
    cd ..
fi
```

## Troubleshooting

### Script not executing?
Make sure it's executable:
```bash
chmod +x scripts/*.sh
```

### Wrong language detected?
Reorder the detection logic or be more specific in your conditions.

### Deployment fails?
- Check Repository Variables are set correctly
- Verify SSH keys are configured in Bitbucket
- Test the script locally (if possible)
- Check Bitbucket Pipeline logs for error messages

## Example: Quick Start for New Project

1. **Copy this pipeline to your new project**
2. **Identify your language** (e.g., Node.js)
3. **Edit build.sh**:
   - Uncomment the Node.js section
   - Remove or comment Maven section
4. **Edit test.sh**:
   - Uncomment the Node.js section
5. **Edit package.sh**:
   - Uncomment the Node.js section
6. **Test locally**:
   ```bash
   ./scripts/build.sh
   ./scripts/test.sh
   ./scripts/package.sh
   ```
7. **Commit and push** - Pipeline will use your scripts!

## Need Help?

- Check the main [PIPELINE_REUSE_GUIDE.md](../PIPELINE_REUSE_GUIDE.md)
- View [bitbucket-pipelines.yml](../bitbucket-pipelines.yml) configuration
- Bitbucket Pipelines documentation: https://support.atlassian.com/bitbucket-cloud/docs/get-started-with-bitbucket-pipelines/
