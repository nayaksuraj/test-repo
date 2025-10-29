# Bitbucket Pipeline Library

This directory contains the structure for creating a reusable pipeline library that can be stored in a separate repository and used across multiple projects.

## 📁 Repository Structure

This should be created as a **separate repository**: `yourorg/bitbucket-pipeline-library`

```
bitbucket-pipeline-library/
├── pipes/                    # Bitbucket Pipes (Docker-based)
├── docker/                   # Docker images with pre-installed tools
├── scripts/                  # Standalone scripts
├── templates/                # YAML templates
└── docs/                     # Documentation
```

## 🚀 Quick Start

### For Consumers (Application Teams)

Choose one of three approaches:

#### Approach 1: Use Bitbucket Pipes (Recommended)
```yaml
# In your bitbucket-pipelines.yml
- pipe: docker://yourorg/secrets-scan-pipe:1.0.0
  variables:
    FAIL_ON_SECRETS: true
```

#### Approach 2: Use Docker Toolbox Image
```yaml
# In your bitbucket-pipelines.yml
image: yourorg/devsecops-toolbox:1.0.0

pipelines:
  default:
    - step:
        name: Security Scan
        script:
          - security-secrets-scan.sh
```

#### Approach 3: Clone Scripts
```yaml
# In your bitbucket-pipelines.yml
- step:
    name: Download Shared Scripts
    script:
      - git clone https://bitbucket.org/yourorg/bitbucket-pipeline-library.git /tmp/pipeline-lib
      - cp -r /tmp/pipeline-lib/scripts/* ./scripts/
```

## 🏗️ For Maintainers

### Creating a New Pipe

1. Create directory: `pipes/your-pipe-name/`
2. Add required files:
   - `pipe.yml` - Pipe metadata
   - `Dockerfile` - Container definition
   - `pipe.sh` - Pipe logic
   - `README.md` - Documentation

3. Build and publish:
```bash
cd pipes/your-pipe-name
docker build -t yourorg/your-pipe-name:1.0.0 .
docker push yourorg/your-pipe-name:1.0.0
```

### Updating the Docker Toolbox

```bash
cd docker/devsecops-toolbox
docker build -t yourorg/devsecops-toolbox:1.0.0 .
docker push yourorg/devsecops-toolbox:1.0.0
```

## 📖 Documentation

- [Reusable Pipelines Guide](../REUSABLE_PIPELINES_GUIDE.md)
- [Pipe Development Guide](./docs/pipe-development.md)
- [Usage Examples](./docs/usage-examples.md)

## 🔧 Maintenance

- Version all components using semantic versioning
- Test pipes before publishing
- Document breaking changes
- Maintain backwards compatibility when possible
