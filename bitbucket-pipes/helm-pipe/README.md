# Helm Pipe

Enterprise-grade Bitbucket Pipe for linting, packaging, and pushing Helm charts to OCI or traditional Helm registries.

## Features

- **Chart Linting**: Validate Helm charts for best practices
- **Template Validation**: Test chart templates with multiple value files
- **Dependency Management**: Automatically update chart dependencies
- **Multi-environment Support**: Validate charts with dev/stage/prod values
- **OCI Registry Support**: Push to OCI-compliant registries (GitHub, AWS ECR, Azure ACR, Google Artifact Registry)
- **Traditional Registry Support**: Push to ChartMuseum and similar repositories
- **Version Management**: Automatically use or override chart versions
- **Cloud-agnostic**: Works with any Helm registry
- **Debug Mode**: Enhanced logging for troubleshooting
- **Production-ready**: Error handling and colored output

## Usage

### Basic Usage

```yaml
pipelines:
  default:
    - step:
        name: Package and Push Helm Chart
        script:
          - pipe: docker://nayaksuraj/helm-pipe:1.0.0
            variables:
              HELM_CHART_PATH: "./helm-chart"
              HELM_REGISTRY: "oci://ghcr.io/myorg/charts"
              HELM_REGISTRY_USERNAME: $GITHUB_USERNAME
              HELM_REGISTRY_PASSWORD: $GITHUB_TOKEN
```

### Advanced Usage with Version Override

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Release Helm Chart
          script:
            - pipe: docker://nayaksuraj/helm-pipe:1.0.0
              variables:
                HELM_CHART_PATH: "./helm-chart"
                CHART_VERSION: "1.0.0"
                HELM_REGISTRY: "oci://ghcr.io/myorg/charts"
                HELM_REGISTRY_USERNAME: $GITHUB_USERNAME
                HELM_REGISTRY_PASSWORD: $GITHUB_TOKEN
                LINT_CHART: "true"
                PACKAGE_CHART: "true"
                PUSH_CHART: "true"
                DEBUG: "true"
```

### Lint and Package Only (No Push)

```yaml
pipelines:
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
                PUSH_CHART: "false"
```

## Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `HELM_CHART_PATH` | Path to Helm chart directory | `./helm-chart` |

### Optional Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `CHART_VERSION` | Chart version (overrides Chart.yaml) | Chart.yaml version | `1.0.0` |
| `HELM_REGISTRY` | Helm registry URL | - | `oci://ghcr.io/org/charts` |
| `HELM_REGISTRY_USERNAME` | Registry username | - | `myuser` |
| `HELM_REGISTRY_PASSWORD` | Registry password/token | - | `$GITHUB_TOKEN` |
| `LINT_CHART` | Run helm lint | `true` | `true`, `false` |
| `PACKAGE_CHART` | Package the chart | `true` | `true`, `false` |
| `PUSH_CHART` | Push to registry | `true` | `true`, `false` |
| `WORKING_DIR` | Working directory | `.` | `./charts` |
| `DEBUG` | Enable debug output | `false` | `true`, `false` |

## Registry Examples

### GitHub Container Registry (OCI)

```yaml
variables:
  HELM_REGISTRY: "oci://ghcr.io/myorg/charts"
  HELM_REGISTRY_USERNAME: $GITHUB_USERNAME
  HELM_REGISTRY_PASSWORD: $GITHUB_TOKEN
```

### AWS Elastic Container Registry (OCI)

```yaml
variables:
  HELM_REGISTRY: "oci://123456789012.dkr.ecr.us-east-1.amazonaws.com/charts"
  HELM_REGISTRY_USERNAME: "AWS"
  HELM_REGISTRY_PASSWORD: $ECR_PASSWORD
```

### Azure Container Registry (OCI)

```yaml
variables:
  HELM_REGISTRY: "oci://myregistry.azurecr.io/helm"
  HELM_REGISTRY_USERNAME: $ACR_USERNAME
  HELM_REGISTRY_PASSWORD: $ACR_PASSWORD
```

### Google Artifact Registry (OCI)

```yaml
variables:
  HELM_REGISTRY: "oci://us-central1-docker.pkg.dev/my-project/charts"
  HELM_REGISTRY_USERNAME: "_json_key"
  HELM_REGISTRY_PASSWORD: $GAR_JSON_KEY
```

### Harbor (OCI)

```yaml
variables:
  HELM_REGISTRY: "oci://harbor.example.com/charts"
  HELM_REGISTRY_USERNAME: $HARBOR_USERNAME
  HELM_REGISTRY_PASSWORD: $HARBOR_PASSWORD
```

### ChartMuseum (Traditional)

```yaml
variables:
  HELM_REGISTRY: "https://charts.example.com"
  HELM_REGISTRY_USERNAME: $CHARTMUSEUM_USER
  HELM_REGISTRY_PASSWORD: $CHARTMUSEUM_PASSWORD
```

## Chart Structure

Your Helm chart should follow the standard structure:

```
helm-chart/
├── Chart.yaml              # Required: Chart metadata
├── values.yaml             # Required: Default values
├── values-dev.yaml         # Optional: Dev environment values
├── values-stage.yaml       # Optional: Stage environment values
├── values-prod.yaml        # Optional: Production environment values
├── templates/              # Required: Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── _helpers.tpl
├── charts/                 # Optional: Chart dependencies
└── README.md              # Optional: Chart documentation
```

## Multi-environment Validation

The pipe automatically validates your chart with all environment-specific value files:

- `values.yaml` (default) - Always validated
- `values-dev.yaml` - Validated if present
- `values-stage.yaml` / `values-staging.yaml` - Validated if present
- `values-prod.yaml` / `values-production.yaml` - Validated if present

This ensures your chart works correctly across all environments before pushing.

## Dependency Management

If your `Chart.yaml` includes dependencies:

```yaml
dependencies:
  - name: postgresql
    version: "12.1.0"
    repository: "https://charts.bitnami.com/bitnami"
```

The pipe will automatically run `helm dependency update` to fetch and package dependencies.

## Version Management

### Automatic Versioning

By default, the pipe uses the version specified in `Chart.yaml`:

```yaml
# Chart.yaml
version: 1.0.0
```

### Version Override

Override the chart version via the `CHART_VERSION` variable:

```yaml
variables:
  CHART_VERSION: "1.2.3"
```

This is useful for CI/CD pipelines that calculate versions dynamically.

## Outputs

The pipe generates the following outputs:

### Console Output
- Colored, easy-to-read progress
- Lint results
- Template validation results
- Chart package information

### Files Generated
- `helm-packages/<chart>-<version>.tgz` - Packaged Helm chart
- `helm-packages/index.yaml` - Helm repository index
- `build-info/helm-chart.txt` - Chart metadata

### Chart Metadata
The following information is saved to `build-info/helm-chart.txt`:
```
HELM_CHART_PATH=./helm-chart
HELM_CHART_NAME=myapp
HELM_CHART_VERSION=1.0.0
HELM_APP_VERSION=1.0.0
HELM_CHART_PACKAGE=helm-packages/myapp-1.0.0.tgz
HELM_REGISTRY=oci://ghcr.io/org/charts
GIT_COMMIT=abc1234
GIT_BRANCH=main
BUILD_DATE=2024-01-01T12:00:00Z
```

## Best Practices

1. **Use Secure Variables**: Store credentials in Bitbucket repository variables (secured)
2. **Lint Always**: Always enable chart linting for validation
3. **Version Control**: Use semantic versioning for chart releases
4. **Multi-environment**: Create environment-specific values files
5. **Test Templates**: Ensure all templates validate before pushing
6. **Document Charts**: Include comprehensive README.md in your charts
7. **Dependencies**: Pin dependency versions in Chart.yaml
8. **OCI Registries**: Prefer OCI registries for better integration

## Common Workflows

### Development Workflow

```yaml
pipelines:
  pull-requests:
    '**':
      - step:
          name: Validate Chart
          script:
            - pipe: docker://nayaksuraj/helm-pipe:1.0.0
              variables:
                HELM_CHART_PATH: "./helm-chart"
                LINT_CHART: "true"
                PACKAGE_CHART: "true"
                PUSH_CHART: "false"
```

### Release Workflow

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Release Chart
          script:
            - export CHART_VERSION=$(cat VERSION)
            - pipe: docker://nayaksuraj/helm-pipe:1.0.0
              variables:
                HELM_CHART_PATH: "./helm-chart"
                CHART_VERSION: $CHART_VERSION
                HELM_REGISTRY: "oci://ghcr.io/myorg/charts"
                HELM_REGISTRY_USERNAME: $GITHUB_USERNAME
                HELM_REGISTRY_PASSWORD: $GITHUB_TOKEN
```

### Multi-chart Repository

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Release API Chart
          script:
            - pipe: docker://nayaksuraj/helm-pipe:1.0.0
              variables:
                HELM_CHART_PATH: "./charts/api"
                HELM_REGISTRY: "oci://ghcr.io/myorg/charts"
      - step:
          name: Release Web Chart
          script:
            - pipe: docker://nayaksuraj/helm-pipe:1.0.0
              variables:
                HELM_CHART_PATH: "./charts/web"
                HELM_REGISTRY: "oci://ghcr.io/myorg/charts"
```

## Troubleshooting

### Debug Mode
Enable debug mode for detailed logging:
```yaml
DEBUG: "true"
```

### Lint Failures
- Review lint output for specific issues
- Check YAML syntax in templates
- Verify all required values are defined
- Ensure proper indentation

### Template Validation Failures
- Check template syntax with `helm template --debug`
- Verify all referenced values exist in values.yaml
- Test with `helm install --dry-run`

### Push Failures
- Verify registry URL format (must include `oci://` for OCI registries)
- Check credentials are correctly set
- Ensure chart version doesn't already exist
- For AWS ECR, verify token is not expired

### Version Conflicts
- Chart version already exists in registry
- Use `CHART_VERSION` to override
- Implement version bumping in your CI/CD

## Support

For issues, questions, or contributions:
- Repository: https://github.com/nayaksuraj/test-repo
- Documentation: See repository wiki
- Issues: GitHub Issues

## License

MIT License - See repository for details
