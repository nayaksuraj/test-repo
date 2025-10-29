# Secrets Scanner Pipe

Bitbucket Pipe for scanning code for secrets and credentials using GitLeaks.

## Description

This pipe scans your codebase for hardcoded secrets, API keys, passwords, and other sensitive credentials. It helps prevent credential leaks by catching them before they reach production.

## Features

- 🔍 Detects over 140 types of secrets
- 🚫 Blocks pipeline on detection (configurable)
- 📊 Multiple report formats (JSON, SARIF, CSV)
- ⚡ Fast scanning with GitLeaks
- 🔒 Part of shift-left security strategy

## Usage

### Basic Usage

```yaml
- pipe: docker://yourorg/secrets-scan-pipe:1.0.0
```

### With Custom Configuration

```yaml
- pipe: docker://yourorg/secrets-scan-pipe:1.0.0
  variables:
    FAIL_ON_SECRETS: true
    SCAN_PATH: "./src"
    REPORT_FORMAT: "sarif"
    DEBUG: false
```

### In a Complete Pipeline

```yaml
image: maven:3.8.6-openjdk-17

pipelines:
  default:
    # Secrets scan should be FIRST (fail fast)
    - pipe: docker://yourorg/secrets-scan-pipe:1.0.0
      variables:
        FAIL_ON_SECRETS: true

    - step:
        name: Build
        script:
          - mvn clean package
```

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `FAIL_ON_SECRETS` | No | `true` | Fail the pipeline if secrets are detected |
| `SCAN_PATH` | No | `.` | Path to scan for secrets |
| `GITLEAKS_VERSION` | No | `8.18.0` | Version of GitLeaks to use |
| `REPORT_FORMAT` | No | `json` | Report format (`json`, `sarif`, `csv`) |
| `DEBUG` | No | `false` | Enable debug logging |

## Artifacts

The pipe generates the following artifacts in `security-reports/`:

- `gitleaks-report.json` - JSON format (always generated)
- `gitleaks-report.sarif` - SARIF format (if `REPORT_FORMAT=sarif`)
- `gitleaks-report.csv` - CSV format (if `REPORT_FORMAT=csv`)

## Examples

### Scan specific directory

```yaml
- pipe: docker://yourorg/secrets-scan-pipe:1.0.0
  variables:
    SCAN_PATH: "./src/main/java"
```

### Warning mode (don't block)

```yaml
- pipe: docker://yourorg/secrets-scan-pipe:1.0.0
  variables:
    FAIL_ON_SECRETS: false
```

### Generate SARIF report for GitHub

```yaml
- pipe: docker://yourorg/secrets-scan-pipe:1.0.0
  variables:
    REPORT_FORMAT: "sarif"
```

## What Secrets are Detected?

GitLeaks detects over 140 types of secrets including:

- AWS Access Keys
- GitHub Personal Access Tokens
- Google API Keys
- Slack Tokens
- Private SSH Keys
- Database Passwords
- JWT Tokens
- And many more...

## Remediation

If secrets are found:

1. **Remove the secret** from your code
2. **Use environment variables** or secret management tools (Vault, AWS Secrets Manager)
3. **Rotate the compromised credential** immediately
4. **Add to .gitignore** to prevent future commits
5. **Clean git history** if already committed (use `git-filter-repo`)

## Support

- Repository: https://bitbucket.org/yourorg/bitbucket-pipeline-library
- Issues: Create an issue in the repository
- Documentation: See [Reusable Pipelines Guide](../../../REUSABLE_PIPELINES_GUIDE.md)

## License

MIT

## Changelog

### 1.0.0 (2025-10-29)
- Initial release
- GitLeaks 8.18.0 integration
- Support for JSON, SARIF, CSV formats
- Configurable failure behavior
