# Security Pipe

A comprehensive Bitbucket Pipe for shift-left security scanning. Includes secrets detection, dependency scanning (SCA), SAST, SBOM generation, IaC scanning, Dockerfile security, and container vulnerability scanning.

## Features

- **Secrets Scanning**: Detect hardcoded credentials and API keys with GitLeaks
- **SCA (Software Composition Analysis)**: Scan dependencies for known vulnerabilities
- **SAST (Static Application Security Testing)**: Analyze source code for security issues
- **SBOM Generation**: Create Software Bill of Materials for supply chain security
- **IaC Scanning**: Security analysis for Kubernetes/Helm configurations
- **Dockerfile Scanning**: Best practices and security checks for Dockerfiles
- **Container Scanning**: Vulnerability scanning for container images
- **Multi-language Support**: Java, JavaScript, Python, Go, and more
- **Flexible Severity Thresholds**: Fail builds based on severity levels

## Security Scanning Tools

| Scan Type | Tools Used | Purpose |
|-----------|-----------|---------|
| Secrets | GitLeaks | Detect hardcoded secrets |
| SCA | Grype, OWASP Dependency-Check, npm audit | Find vulnerable dependencies |
| SAST | Bandit (Python), Trivy | Static code analysis |
| SBOM | Syft, CycloneDX | Generate software inventory |
| IaC | Checkov, Trivy | Kubernetes/Helm security |
| Dockerfile | Hadolint, Trivy | Dockerfile best practices |
| Container | Trivy, Grype | Container vulnerability scanning |

## Usage

### Basic Security Scan (Secrets + SCA + SBOM)

```yaml
pipelines:
  default:
    - step:
        name: Security Scan
        script:
          - pipe: nayaksuraj/security-pipe:1.0.0
```

This runs the default scans:
- Secrets scanning: ✓
- SCA (dependencies): ✓
- SBOM generation: ✓
- SAST: ✗ (optional)
- IaC scanning: ✗ (optional)
- Dockerfile scanning: ✗ (optional)
- Container scanning: ✗ (optional)

### Comprehensive Security Scan (All Scans)

```yaml
pipelines:
  default:
    - step:
        name: Full Security Scan
        services:
          - docker
        script:
          - pipe: nayaksuraj/security-pipe:1.0.0
            variables:
              SECRETS_SCAN: 'true'
              SCA_SCAN: 'true'
              SAST_SCAN: 'true'
              SBOM_GENERATE: 'true'
              IAC_SCAN: 'true'
              DOCKERFILE_SCAN: 'true'
              CONTAINER_SCAN: 'true'
              CONTAINER_IMAGE: '$DOCKER_REGISTRY/myapp:$BITBUCKET_BUILD_NUMBER'
              FAIL_ON_CRITICAL: 'true'
```

### Secrets Scanning Only

```yaml
pipelines:
  default:
    - step:
        name: Secrets Scan
        script:
          - pipe: nayaksuraj/security-pipe:1.0.0
            variables:
              SECRETS_SCAN: 'true'
              SCA_SCAN: 'false'
              SBOM_GENERATE: 'false'
```

### Dependency Scanning (SCA)

```yaml
pipelines:
  default:
    - step:
        name: Dependency Security
        script:
          - pipe: nayaksuraj/security-pipe:1.0.0
            variables:
              SCA_SCAN: 'true'
              CVSS_THRESHOLD: '7.0'
              FAIL_ON_HIGH: 'true'
```

### Container Image Scanning

```yaml
pipelines:
  default:
    - step:
        name: Container Security
        services:
          - docker
        script:
          # Build image
          - export IMAGE_NAME="${DOCKER_REGISTRY}/myapp:${BITBUCKET_BUILD_NUMBER}"
          - docker build -t $IMAGE_NAME .

          # Scan image
          - pipe: nayaksuraj/security-pipe:1.0.0
            variables:
              CONTAINER_SCAN: 'true'
              CONTAINER_IMAGE: $IMAGE_NAME
              FAIL_ON_CRITICAL: 'true'
              FAIL_ON_HIGH: 'true'
```

### IaC Security Scanning (Kubernetes/Helm)

```yaml
pipelines:
  default:
    - step:
        name: IaC Security
        script:
          - pipe: nayaksuraj/security-pipe:1.0.0
            variables:
              IAC_SCAN: 'true'
              HELM_CHART_PATH: './helm-chart'
              FAIL_ON_HIGH: 'true'
```

### Dockerfile Security Scanning

```yaml
pipelines:
  default:
    - step:
        name: Dockerfile Security
        script:
          - pipe: nayaksuraj/security-pipe:1.0.0
            variables:
              DOCKERFILE_SCAN: 'true'
              DOCKERFILE_PATH: './Dockerfile'
```

### SBOM Generation

```yaml
pipelines:
  default:
    - step:
        name: Generate SBOM
        script:
          - pipe: nayaksuraj/security-pipe:1.0.0
            variables:
              SBOM_GENERATE: 'true'
              SECRETS_SCAN: 'false'
              SCA_SCAN: 'false'
        artifacts:
          - security-reports/sbom/**
```

### Production Pipeline (Strict Security)

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Security Gate (Strict)
          services:
            - docker
          script:
            - pipe: nayaksuraj/security-pipe:1.0.0
              variables:
                SECRETS_SCAN: 'true'
                SCA_SCAN: 'true'
                SAST_SCAN: 'true'
                SBOM_GENERATE: 'true'
                IAC_SCAN: 'true'
                DOCKERFILE_SCAN: 'true'
                CONTAINER_SCAN: 'true'
                CONTAINER_IMAGE: '$DOCKER_REGISTRY/myapp:$BITBUCKET_BUILD_NUMBER'
                FAIL_ON_CRITICAL: 'true'
                FAIL_ON_HIGH: 'true'
                CVSS_THRESHOLD: '7.0'
          artifacts:
            - security-reports/**
```

### Development Pipeline (Warnings Only)

```yaml
pipelines:
  branches:
    develop:
      - step:
          name: Security Scan (Non-blocking)
          script:
            - pipe: nayaksuraj/security-pipe:1.0.0
              variables:
                SECRETS_SCAN: 'true'
                SCA_SCAN: 'true'
                SBOM_GENERATE: 'true'
                FAIL_ON_CRITICAL: 'false'
                FAIL_ON_HIGH: 'false'
          artifacts:
            - security-reports/**
```

## Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `SECRETS_SCAN` | Enable secrets scanning with GitLeaks | No | true |
| `SCA_SCAN` | Enable Software Composition Analysis | No | true |
| `SAST_SCAN` | Enable Static Application Security Testing | No | false |
| `SBOM_GENERATE` | Generate Software Bill of Materials | No | true |
| `IAC_SCAN` | Enable Infrastructure as Code scanning | No | false |
| `DOCKERFILE_SCAN` | Enable Dockerfile security scanning | No | false |
| `CONTAINER_SCAN` | Enable container image vulnerability scanning | No | false |
| `CONTAINER_IMAGE` | Container image to scan | Conditional | - |
| `FAIL_ON_HIGH` | Fail pipeline on HIGH severity issues | No | false |
| `FAIL_ON_CRITICAL` | Fail pipeline on CRITICAL severity issues | No | true |
| `CVSS_THRESHOLD` | CVSS threshold for SCA scanning (0-10) | No | 7.0 |
| `HELM_CHART_PATH` | Path to Helm chart for IaC scanning | No | ./helm-chart |
| `DOCKERFILE_PATH` | Path to Dockerfile for scanning | No | ./Dockerfile |
| `WORKING_DIR` | Working directory where scans should be executed | No | . |
| `REPORTS_DIR` | Directory to store security reports | No | security-reports |
| `DEBUG` | Enable debug mode for verbose output | No | false |

## Security Reports

All security reports are stored in the `security-reports/` directory:

```
security-reports/
├── security-summary.txt          # Overall summary
├── gitleaks-report.json          # Secrets scan results
├── sca-grype.json                # Dependency vulnerabilities
├── npm-audit.json                # NPM vulnerabilities
├── bandit-report.json            # Python SAST results
├── sbom/
│   ├── sbom-cyclonedx.json      # SBOM in CycloneDX format
│   └── sbom-spdx.json           # SBOM in SPDX format
├── iac/
│   ├── checkov.log              # IaC scan results
│   └── results_json.json        # Detailed IaC findings
├── hadolint-report.json          # Dockerfile scan results
├── trivy-container.json          # Container vulnerabilities
└── grype-container.json          # Container vulnerabilities
```

### Accessing Reports

Save reports as artifacts:

```yaml
- step:
    script:
      - pipe: nayaksuraj/security-pipe:1.0.0
    artifacts:
      - security-reports/**
```

## Scan Details

### Secrets Scanning

Detects:
- API keys and tokens
- Passwords and credentials
- Private keys
- AWS secrets
- Database connection strings
- OAuth tokens

**Tools**: GitLeaks

**Example**:
```yaml
variables:
  SECRETS_SCAN: 'true'
```

### SCA (Dependency Scanning)

Detects vulnerabilities in:
- Maven dependencies (Java)
- Gradle dependencies (Java)
- NPM packages (JavaScript)
- Python packages
- Go modules

**Tools**: Grype, OWASP Dependency-Check, npm audit

**Example**:
```yaml
variables:
  SCA_SCAN: 'true'
  CVSS_THRESHOLD: '7.0'
```

### SAST (Static Analysis)

Analyzes source code for:
- SQL injection vulnerabilities
- XSS vulnerabilities
- Insecure cryptography
- Hardcoded secrets
- Security misconfigurations

**Tools**: Bandit (Python), Trivy

**Example**:
```yaml
variables:
  SAST_SCAN: 'true'
```

### SBOM Generation

Creates Software Bill of Materials:
- Component inventory
- Dependency tree
- License information
- Package URLs (PURL)
- CPE identifiers

**Formats**: CycloneDX, SPDX

**Tools**: Syft, CycloneDX Maven/Gradle plugins

**Example**:
```yaml
variables:
  SBOM_GENERATE: 'true'
```

### IaC Scanning

Scans Kubernetes/Helm configurations for:
- Pod security standards violations
- Privilege escalation risks
- Network policy issues
- Resource limit violations
- CIS Kubernetes Benchmarks

**Tools**: Checkov, Trivy

**Example**:
```yaml
variables:
  IAC_SCAN: 'true'
  HELM_CHART_PATH: './helm-chart'
```

### Dockerfile Scanning

Checks Dockerfiles for:
- Non-root user configuration
- Healthcheck presence
- Base image tags (avoid :latest)
- Minimal base images
- COPY vs ADD usage
- CIS Docker Benchmarks

**Tools**: Hadolint, Trivy

**Example**:
```yaml
variables:
  DOCKERFILE_SCAN: 'true'
  DOCKERFILE_PATH: './Dockerfile'
```

### Container Scanning

Scans container images for:
- OS vulnerabilities
- Application vulnerabilities
- Malware
- Secrets in layers
- Configuration issues

**Tools**: Trivy, Grype

**Example**:
```yaml
variables:
  CONTAINER_SCAN: 'true'
  CONTAINER_IMAGE: 'myapp:latest'
```

## Severity Levels

The pipe tracks issues by severity:

- **CRITICAL**: Immediate action required, should always fail builds
- **HIGH**: Address as soon as possible
- **MEDIUM**: Should be fixed before release
- **LOW**: Nice to fix, low priority

Configure failure behavior:

```yaml
variables:
  FAIL_ON_CRITICAL: 'true'   # Fail on critical (recommended)
  FAIL_ON_HIGH: 'true'       # Fail on high (strict)
```

## Integration Examples

### Complete CI/CD Pipeline

```yaml
pipelines:
  default:
    - parallel:
      # Security scans
      - step:
          name: Security Scan
          script:
            - pipe: nayaksuraj/security-pipe:1.0.0
              variables:
                SECRETS_SCAN: 'true'
                SCA_SCAN: 'true'
                SBOM_GENERATE: 'true'

      # Tests
      - step:
          name: Tests
          script:
            - pipe: nayaksuraj/test-pipe:1.0.0

      # Quality
      - step:
          name: Code Quality
          script:
            - pipe: nayaksuraj/quality-pipe:1.0.0

    # Build and scan container
    - step:
        name: Build & Scan Container
        services:
          - docker
        script:
          - export IMAGE_NAME="myapp:${BITBUCKET_BUILD_NUMBER}"
          - docker build -t $IMAGE_NAME .
          - pipe: nayaksuraj/security-pipe:1.0.0
            variables:
              CONTAINER_SCAN: 'true'
              DOCKERFILE_SCAN: 'true'
              IAC_SCAN: 'true'
              CONTAINER_IMAGE: $IMAGE_NAME
```

### Pull Request Security Check

```yaml
pipelines:
  pull-requests:
    '**':
      - step:
          name: PR Security Scan
          script:
            - pipe: nayaksuraj/security-pipe:1.0.0
              variables:
                SECRETS_SCAN: 'true'
                SCA_SCAN: 'true'
                FAIL_ON_CRITICAL: 'true'
                FAIL_ON_HIGH: 'false'
```

### Scheduled Security Scan

```yaml
pipelines:
  custom:
    security-audit:
      - step:
          name: Weekly Security Audit
          script:
            - pipe: nayaksuraj/security-pipe:1.0.0
              variables:
                SECRETS_SCAN: 'true'
                SCA_SCAN: 'true'
                SAST_SCAN: 'true'
                SBOM_GENERATE: 'true'
          artifacts:
            - security-reports/**
```

## Best Practices

1. **Always scan for secrets** - Enable on every commit
2. **Run SCA regularly** - Dependencies change frequently
3. **Generate SBOMs** - Required for supply chain security
4. **Scan containers before deployment** - Catch vulnerabilities early
5. **Use strict gates for production** - Fail on critical/high issues
6. **Archive security reports** - Track security posture over time
7. **Integrate with security tools** - Feed reports to SIEM/SOAR
8. **Regular security audits** - Schedule comprehensive scans

## Troubleshooting

### Secrets Detected in History

**Issue**: GitLeaks finds secrets in git history

**Solution**:
1. Remove secrets from history: `git filter-repo --path <file> --invert-paths`
2. Rotate all compromised credentials
3. Add patterns to `.gitignore`

### High False Positives

**Issue**: Too many false positive vulnerabilities

**Solution**:
1. Review findings manually
2. Create suppression files
3. Adjust `CVSS_THRESHOLD`
4. Update dependencies

### Container Scan Fails

**Issue**: Container image not found

**Solution**:
Ensure Docker service is enabled and image is built:

```yaml
- step:
    services:
      - docker
    script:
      - docker build -t myapp:latest .
      - pipe: nayaksuraj/security-pipe:1.0.0
        variables:
          CONTAINER_IMAGE: 'myapp:latest'
```

### IaC Scan Errors

**Issue**: Helm chart not found

**Solution**:
Verify path and ensure chart exists:

```yaml
variables:
  IAC_SCAN: 'true'
  HELM_CHART_PATH: './path/to/helm-chart'
```

## Compliance & Standards

This pipe helps achieve compliance with:

- **OWASP Top 10**: Vulnerability detection
- **CIS Benchmarks**: Docker and Kubernetes security
- **NIST SSDF**: Secure software development
- **SLSA**: Supply chain security (SBOM)
- **PCI DSS**: Secrets and vulnerability management
- **GDPR**: Data protection through security scanning

## Support

For issues or questions:
- Repository: https://github.com/nayaksuraj/test-repo
- Bitbucket Pipes Documentation: https://support.atlassian.com/bitbucket-cloud/docs/pipes/

## License

MIT License
