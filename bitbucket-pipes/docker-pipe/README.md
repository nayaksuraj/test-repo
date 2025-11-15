# Docker Pipe

Enterprise-grade Bitbucket Pipe for building, scanning, and pushing Docker images with integrated Trivy security scanning.

## Features

- **Multi-stage Build Support**: Build complex Docker images with multi-stage builds
- **Security Scanning**: Integrated Trivy vulnerability scanning
- **Multi-tag Support**: Automatically tag images with commit SHA and latest
- **Build Arguments**: Pass custom build arguments to Docker build
- **Cloud-agnostic**: Works with any Docker registry (Docker Hub, GitHub Container Registry, AWS ECR, Azure ACR, Google GCR, private registries)
- **Flexible Authentication**: Support for username/password and token-based authentication
- **Debug Mode**: Enhanced logging for troubleshooting
- **Production-ready**: Error handling, rollback support, and colored output

## Usage

### Basic Usage

```yaml
pipelines:
  default:
    - step:
        name: Build and Push Docker Image
        services:
          - docker
        script:
          - pipe: docker://nayaksuraj/docker-pipe:1.0.0
            variables:
              DOCKER_REGISTRY: "docker.io"
              DOCKER_REPOSITORY: "mycompany/myapp"
              DOCKER_USERNAME: $DOCKER_USERNAME
              DOCKER_PASSWORD: $DOCKER_PASSWORD
```

### Advanced Usage with Security Scanning

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build, Scan, and Push Docker Image
          services:
            - docker
          script:
            - pipe: docker://nayaksuraj/docker-pipe:1.0.0
              variables:
                DOCKER_REGISTRY: "ghcr.io"
                DOCKER_REPOSITORY: "mycompany/myapp"
                DOCKER_USERNAME: $GITHUB_USERNAME
                DOCKER_PASSWORD: $GITHUB_TOKEN
                IMAGE_TAG: "v1.0.0"
                DOCKERFILE_PATH: "./docker/Dockerfile"
                BUILD_ARGS: "VERSION=1.0.0,ENV=production"
                SCAN_IMAGE: "true"
                TRIVY_SEVERITY: "CRITICAL,HIGH"
                TRIVY_EXIT_CODE: "1"  # Fail build if vulnerabilities found
                DEBUG: "true"
```

### Multi-stage Build Example

```yaml
pipelines:
  custom:
    production-release:
      - step:
          name: Build Production Image
          services:
            - docker
          script:
            - pipe: docker://nayaksuraj/docker-pipe:1.0.0
              variables:
                DOCKER_REGISTRY: "your-registry.example.com"
                DOCKER_REPOSITORY: "production/api"
                DOCKER_USERNAME: $REGISTRY_USER
                DOCKER_PASSWORD: $REGISTRY_PASSWORD
                DOCKERFILE_PATH: "./Dockerfile.production"
                BUILD_ARGS: "NODE_ENV=production,API_VERSION=2.0.0"
                SCAN_IMAGE: "true"
                TRIVY_SEVERITY: "CRITICAL,HIGH,MEDIUM"
                TRIVY_EXIT_CODE: "1"
```

## Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DOCKER_REGISTRY` | Docker registry URL | `docker.io`, `ghcr.io`, `your-registry.com` |
| `DOCKER_REPOSITORY` | Repository name | `mycompany/myapp` |

### Optional Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `DOCKER_USERNAME` | Registry username | - | `myuser` |
| `DOCKER_PASSWORD` | Registry password/token | - | `$DOCKER_PASSWORD` |
| `IMAGE_TAG` | Image tag | git commit SHA | `v1.0.0`, `latest` |
| `DOCKERFILE_PATH` | Path to Dockerfile | `./Dockerfile` | `./docker/Dockerfile.prod` |
| `BUILD_ARGS` | Build arguments (comma-separated) | - | `VERSION=1.0.0,ENV=prod` |
| `SCAN_IMAGE` | Enable vulnerability scanning | `true` | `true`, `false` |
| `TRIVY_SEVERITY` | Severity levels to scan | `CRITICAL,HIGH,MEDIUM` | `CRITICAL,HIGH` |
| `TRIVY_EXIT_CODE` | Exit code on vulnerabilities | `0` | `0` (continue), `1` (fail) |
| `PUSH_IMAGE` | Push image to registry | `true` | `true`, `false` |
| `WORKING_DIR` | Working directory | `.` | `./app` |
| `DEBUG` | Enable debug output | `false` | `true`, `false` |

## Registry Examples

### Docker Hub

```yaml
variables:
  DOCKER_REGISTRY: "docker.io"
  DOCKER_REPOSITORY: "username/app"
  DOCKER_USERNAME: $DOCKER_HUB_USERNAME
  DOCKER_PASSWORD: $DOCKER_HUB_PASSWORD
```

### GitHub Container Registry

```yaml
variables:
  DOCKER_REGISTRY: "ghcr.io"
  DOCKER_REPOSITORY: "organization/app"
  DOCKER_USERNAME: $GITHUB_USERNAME
  DOCKER_PASSWORD: $GITHUB_TOKEN
```

### AWS ECR

```yaml
variables:
  DOCKER_REGISTRY: "123456789012.dkr.ecr.us-east-1.amazonaws.com"
  DOCKER_REPOSITORY: "myapp"
  DOCKER_USERNAME: "AWS"
  DOCKER_PASSWORD: $ECR_PASSWORD  # Generated via aws ecr get-login-password
```

### Azure Container Registry

```yaml
variables:
  DOCKER_REGISTRY: "myregistry.azurecr.io"
  DOCKER_REPOSITORY: "myapp"
  DOCKER_USERNAME: $ACR_USERNAME
  DOCKER_PASSWORD: $ACR_PASSWORD
```

### Google Container Registry

```yaml
variables:
  DOCKER_REGISTRY: "gcr.io"
  DOCKER_REPOSITORY: "my-project/myapp"
  DOCKER_USERNAME: "_json_key"
  DOCKER_PASSWORD: $GCR_JSON_KEY
```

## Security Scanning

The pipe includes integrated Trivy vulnerability scanning:

- **Automatic Scanning**: Images are scanned by default
- **Configurable Severity**: Choose which severity levels to scan for
- **Fail on Vulnerabilities**: Optionally fail the build if vulnerabilities are found
- **Multiple Report Formats**: Text and JSON reports generated
- **Summary Output**: Clear summary of vulnerabilities found

### Security Scanning Examples

**Scan but don't fail:**
```yaml
SCAN_IMAGE: "true"
TRIVY_SEVERITY: "CRITICAL,HIGH,MEDIUM"
TRIVY_EXIT_CODE: "0"
```

**Fail on critical/high vulnerabilities:**
```yaml
SCAN_IMAGE: "true"
TRIVY_SEVERITY: "CRITICAL,HIGH"
TRIVY_EXIT_CODE: "1"
```

**Skip scanning:**
```yaml
SCAN_IMAGE: "false"
```

## Outputs

The pipe generates the following outputs:

### Console Output
- Colored, easy-to-read build progress
- Vulnerability scan results
- Image tags and registry information

### Files Generated
- `build-info/docker-image.txt` - Image metadata
- `security-reports/trivy-report.txt` - Vulnerability scan (text)
- `security-reports/trivy-report.json` - Vulnerability scan (JSON)

### Environment Variables
The following information is saved to `build-info/docker-image.txt`:
```
DOCKER_IMAGE=registry/repo:tag
DOCKER_IMAGE_LATEST=registry/repo:latest
DOCKER_REGISTRY=registry
DOCKER_REPOSITORY=repo
IMAGE_TAG=tag
GIT_COMMIT=abc1234
GIT_BRANCH=main
BUILD_DATE=2024-01-01T12:00:00Z
```

## Best Practices

1. **Use Secure Variables**: Store credentials in Bitbucket repository variables (secured)
2. **Enable Scanning**: Always enable vulnerability scanning for production images
3. **Fail on Vulnerabilities**: Set `TRIVY_EXIT_CODE=1` for production builds
4. **Tag Releases**: Use semantic versioning for release tags
5. **Multi-stage Builds**: Use multi-stage Dockerfiles to minimize image size
6. **Build Arguments**: Pass version information via build args
7. **Test Before Push**: Build and scan locally before pushing to CI/CD

## Troubleshooting

### Debug Mode
Enable debug mode for detailed logging:
```yaml
DEBUG: "true"
```

### Authentication Issues
- Verify credentials are correctly set in repository variables
- Check registry URL format
- For AWS ECR, ensure token is not expired
- For GCR, verify JSON key format

### Build Failures
- Verify Dockerfile path is correct
- Check build arguments are properly formatted
- Ensure Docker service is enabled in pipeline

### Scan Failures
- Review vulnerability report in `security-reports/`
- Consider updating base images
- Add exceptions for false positives if needed

## Support

For issues, questions, or contributions:
- Repository: https://github.com/nayaksuraj/test-repo
- Documentation: See repository wiki
- Issues: GitHub Issues

## License

MIT License - See repository for details
