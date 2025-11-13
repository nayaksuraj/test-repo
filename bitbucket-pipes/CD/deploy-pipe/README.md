# Deploy Pipe

Enterprise-grade Bitbucket Pipe for deploying applications to Kubernetes using Helm with full support for dev, stage, and prod environments.

## Features

- **Multi-environment Support**: Deploy to dev, stage, and prod environments with environment-specific configurations
- **Helm Integration**: Full Helm 3 support with rollback capabilities
- **Health Checks**: Automatic verification of deployment health and rollout status
- **Rollback Support**: Automatic rollback on deployment failure with `--atomic` flag
- **Dry-run Mode**: Test deployments without making actual changes
- **Cloud-agnostic**: Works with any Kubernetes cluster (AWS EKS, Azure AKS, Google GKE, on-premise)
- **Secure**: Base64-encoded kubeconfig for secure authentication
- **Comprehensive Logging**: Colored output with deployment status and helpful troubleshooting commands
- **Production-ready**: Error handling, validation, and automatic cleanup on failure

## Usage

### Basic Usage (Development)

```yaml
pipelines:
  branches:
    develop:
      - step:
          name: Deploy to Development
          deployment: dev
          script:
            - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
              variables:
                ENVIRONMENT: "dev"
                NAMESPACE: "myapp-dev"
                KUBECONFIG: $KUBECONFIG_DEV
                RELEASE_NAME: "myapp"
                HELM_CHART_PATH: "./helm-chart"
```

### Advanced Usage (Production)

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
              variables:
                ENVIRONMENT: "prod"
                NAMESPACE: "myapp-prod"
                KUBECONFIG: $KUBECONFIG_PROD
                RELEASE_NAME: "myapp"
                HELM_CHART_PATH: "./helm-chart"
                VALUES_FILE: "./helm-chart/values-prod.yaml"
                IMAGE_TAG: "v1.0.0"
                WAIT_FOR_ROLLOUT: "true"
                ROLLOUT_TIMEOUT: "15m"
                DEBUG: "true"
```

### Multi-environment Pipeline

```yaml
pipelines:
  branches:
    develop:
      - step:
          name: Deploy to Dev
          deployment: dev
          script:
            - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
              variables:
                ENVIRONMENT: "dev"
                NAMESPACE: "myapp-dev"
                KUBECONFIG: $KUBECONFIG_DEV
                RELEASE_NAME: "myapp"
                HELM_CHART_PATH: "./helm-chart"
                IMAGE_TAG: $BITBUCKET_COMMIT

    main:
      - step:
          name: Deploy to Stage
          deployment: staging
          script:
            - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
              variables:
                ENVIRONMENT: "stage"
                NAMESPACE: "myapp-stage"
                KUBECONFIG: $KUBECONFIG_STAGE
                RELEASE_NAME: "myapp"
                HELM_CHART_PATH: "./helm-chart"
                IMAGE_TAG: $BITBUCKET_COMMIT
                WAIT_FOR_ROLLOUT: "true"

      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
              variables:
                ENVIRONMENT: "prod"
                NAMESPACE: "myapp-prod"
                KUBECONFIG: $KUBECONFIG_PROD
                RELEASE_NAME: "myapp"
                HELM_CHART_PATH: "./helm-chart"
                IMAGE_TAG: $BITBUCKET_TAG
                WAIT_FOR_ROLLOUT: "true"
                ROLLOUT_TIMEOUT: "15m"
```

### Dry-run Deployment

```yaml
pipelines:
  pull-requests:
    '**':
      - step:
          name: Test Deployment
          script:
            - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
              variables:
                ENVIRONMENT: "dev"
                NAMESPACE: "myapp-dev"
                KUBECONFIG: $KUBECONFIG_DEV
                RELEASE_NAME: "myapp"
                HELM_CHART_PATH: "./helm-chart"
                DRY_RUN: "true"
```

## Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `ENVIRONMENT` | Target environment | `dev`, `stage`, `prod` |
| `NAMESPACE` | Kubernetes namespace | `myapp-dev` |
| `KUBECONFIG` | Base64-encoded kubeconfig | `$KUBECONFIG_DEV` |
| `RELEASE_NAME` | Helm release name | `myapp` |
| `HELM_CHART_PATH` | Path to Helm chart | `./helm-chart` |

### Optional Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `VALUES_FILE` | Path to values file | `values-{ENVIRONMENT}.yaml` | `./helm-chart/values-prod.yaml` |
| `IMAGE_TAG` | Docker image tag | auto-detect from build-info | `v1.0.0` |
| `WAIT_FOR_ROLLOUT` | Wait for deployment completion | `true` | `true`, `false` |
| `ROLLOUT_TIMEOUT` | Timeout for rollout | `10m` | `5m`, `15m`, `30m` |
| `DRY_RUN` | Dry-run mode (no changes) | `false` | `true`, `false` |
| `DEBUG` | Enable debug output | `false` | `true`, `false` |

## Setting up Kubeconfig

The pipe requires a base64-encoded kubeconfig file. Here's how to prepare it:

### Step 1: Get your kubeconfig

For different cloud providers:

**AWS EKS:**
```bash
aws eks update-kubeconfig --name my-cluster --region us-east-1
cat ~/.kube/config
```

**Azure AKS:**
```bash
az aks get-credentials --resource-group my-rg --name my-cluster
cat ~/.kube/config
```

**Google GKE:**
```bash
gcloud container clusters get-credentials my-cluster --region us-central1
cat ~/.kube/config
```

### Step 2: Encode the kubeconfig

```bash
cat ~/.kube/config | base64 -w 0
```

### Step 3: Add to Bitbucket Repository Variables

1. Go to Repository Settings > Repository variables
2. Add a new variable:
   - Name: `KUBECONFIG_DEV` (or `KUBECONFIG_STAGE`, `KUBECONFIG_PROD`)
   - Value: Paste the base64-encoded string
   - Check "Secured" to encrypt the value

## Environment-specific Values

The pipe automatically uses environment-specific values files:

```
helm-chart/
├── values.yaml           # Default values
├── values-dev.yaml       # Development overrides
├── values-stage.yaml     # Staging overrides
└── values-prod.yaml      # Production overrides
```

**Example: values-dev.yaml**
```yaml
replicaCount: 1
resources:
  limits:
    cpu: 500m
    memory: 512Mi
ingress:
  enabled: true
  host: myapp-dev.example.com
```

**Example: values-prod.yaml**
```yaml
replicaCount: 3
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
ingress:
  enabled: true
  host: myapp.example.com
  tls:
    enabled: true
```

## Deployment Flow

1. **Setup**: Decode and configure kubeconfig
2. **Validation**: Verify Kubernetes connectivity
3. **Namespace**: Create or verify namespace exists
4. **Chart Validation**: Lint and validate Helm chart
5. **Deploy**: Execute Helm upgrade with appropriate flags
6. **Wait**: Optionally wait for rollout completion
7. **Verify**: Check deployment, pod, and service status
8. **Report**: Display helpful commands and status

## Rollback Strategy

The pipe uses Helm's `--atomic` flag when `WAIT_FOR_ROLLOUT=true`, which:

1. Automatically rolls back on failure
2. Ensures all-or-nothing deployments
3. Prevents partial deployments

**Manual Rollback:**
```bash
# List release history
helm history myapp -n myapp-prod

# Rollback to previous version
helm rollback myapp -n myapp-prod

# Rollback to specific revision
helm rollback myapp 3 -n myapp-prod
```

## Outputs

### Console Output
- Colored deployment progress with clear sections
- Kubernetes resource status (deployments, pods, services, ingress)
- Helm release status
- Helpful troubleshooting commands

### Files Generated
- `build-info/deployment.txt` - Deployment metadata

### Deployment Metadata
```
ENVIRONMENT=prod
NAMESPACE=myapp-prod
RELEASE_NAME=myapp
HELM_CHART_PATH=./helm-chart
VALUES_FILE=./helm-chart/values-prod.yaml
IMAGE_TAG=v1.0.0
GIT_COMMIT=abc1234
GIT_BRANCH=main
DEPLOYMENT_DATE=2024-01-01T12:00:00Z
CLUSTER=arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
DRY_RUN=false
```

## Cloud Provider Examples

### AWS EKS

```yaml
- pipe: docker://nayaksuraj/deploy-pipe:1.0.0
  variables:
    ENVIRONMENT: "prod"
    NAMESPACE: "myapp-prod"
    KUBECONFIG: $KUBECONFIG_EKS
    RELEASE_NAME: "myapp"
    HELM_CHART_PATH: "./helm-chart"
```

### Azure AKS

```yaml
- pipe: docker://nayaksuraj/deploy-pipe:1.0.0
  variables:
    ENVIRONMENT: "prod"
    NAMESPACE: "myapp-prod"
    KUBECONFIG: $KUBECONFIG_AKS
    RELEASE_NAME: "myapp"
    HELM_CHART_PATH: "./helm-chart"
```

### Google GKE

```yaml
- pipe: docker://nayaksuraj/deploy-pipe:1.0.0
  variables:
    ENVIRONMENT: "prod"
    NAMESPACE: "myapp-prod"
    KUBECONFIG: $KUBECONFIG_GKE
    RELEASE_NAME: "myapp"
    HELM_CHART_PATH: "./helm-chart"
```

### On-premise Kubernetes

```yaml
- pipe: docker://nayaksuraj/deploy-pipe:1.0.0
  variables:
    ENVIRONMENT: "prod"
    NAMESPACE: "myapp-prod"
    KUBECONFIG: $KUBECONFIG_ONPREM
    RELEASE_NAME: "myapp"
    HELM_CHART_PATH: "./helm-chart"
```

## Best Practices

1. **Use Secured Variables**: Always mark KUBECONFIG as secured in Bitbucket
2. **Environment Separation**: Use separate clusters or namespaces for each environment
3. **Manual Triggers**: Require manual approval for production deployments
4. **Health Checks**: Always enable `WAIT_FOR_ROLLOUT` for production
5. **Resource Limits**: Define appropriate resource limits in values files
6. **Rolling Updates**: Configure rolling update strategy in Helm charts
7. **Dry-run First**: Test deployments with dry-run before actual deployment
8. **Version Pinning**: Use specific image tags for production deployments
9. **Monitoring**: Set up monitoring and alerting for deployments
10. **Backup**: Always test rollback procedures

## Complete CI/CD Pipeline Example

```yaml
pipelines:
  default:
    - step:
        name: Build and Test
        script:
          - npm install
          - npm test
          - npm run build

    - step:
        name: Build Docker Image
        services:
          - docker
        script:
          - pipe: docker://nayaksuraj/docker-pipe:1.0.0
            variables:
              DOCKER_REGISTRY: "ghcr.io"
              DOCKER_REPOSITORY: "myorg/myapp"
              DOCKER_USERNAME: $GITHUB_USERNAME
              DOCKER_PASSWORD: $GITHUB_TOKEN
              IMAGE_TAG: $BITBUCKET_COMMIT

    - step:
        name: Deploy to Dev
        deployment: dev
        script:
          - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
            variables:
              ENVIRONMENT: "dev"
              NAMESPACE: "myapp-dev"
              KUBECONFIG: $KUBECONFIG_DEV
              RELEASE_NAME: "myapp"
              HELM_CHART_PATH: "./helm-chart"
              IMAGE_TAG: $BITBUCKET_COMMIT

  branches:
    main:
      - step:
          name: Build and Test
          script:
            - npm install
            - npm test
            - npm run build

      - step:
          name: Build Docker Image
          services:
            - docker
          script:
            - pipe: docker://nayaksuraj/docker-pipe:1.0.0
              variables:
                DOCKER_REGISTRY: "ghcr.io"
                DOCKER_REPOSITORY: "myorg/myapp"
                DOCKER_USERNAME: $GITHUB_USERNAME
                DOCKER_PASSWORD: $GITHUB_TOKEN
                IMAGE_TAG: $BITBUCKET_COMMIT
                SCAN_IMAGE: "true"
                TRIVY_EXIT_CODE: "1"

      - step:
          name: Deploy to Stage
          deployment: staging
          script:
            - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
              variables:
                ENVIRONMENT: "stage"
                NAMESPACE: "myapp-stage"
                KUBECONFIG: $KUBECONFIG_STAGE
                RELEASE_NAME: "myapp"
                HELM_CHART_PATH: "./helm-chart"
                IMAGE_TAG: $BITBUCKET_COMMIT
                WAIT_FOR_ROLLOUT: "true"

      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
              variables:
                ENVIRONMENT: "prod"
                NAMESPACE: "myapp-prod"
                KUBECONFIG: $KUBECONFIG_PROD
                RELEASE_NAME: "myapp"
                HELM_CHART_PATH: "./helm-chart"
                IMAGE_TAG: $BITBUCKET_COMMIT
                WAIT_FOR_ROLLOUT: "true"
                ROLLOUT_TIMEOUT: "15m"
```

## Troubleshooting

### Debug Mode
Enable debug mode for detailed logging:
```yaml
DEBUG: "true"
```

### Connection Issues
- Verify kubeconfig is correctly base64-encoded
- Check network connectivity to Kubernetes cluster
- Verify credentials haven't expired
- Ensure cluster is accessible from Bitbucket Pipelines

### Deployment Failures
- Check pod logs: `kubectl logs -n namespace -l app.kubernetes.io/instance=release-name`
- Check events: `kubectl get events -n namespace --sort-by='.lastTimestamp'`
- Verify image is accessible
- Check resource quotas and limits
- Review Helm release history: `helm history release-name -n namespace`

### Rollback Deployment
```bash
# View history
helm history myapp -n myapp-prod

# Rollback to previous
helm rollback myapp -n myapp-prod

# Rollback to specific revision
helm rollback myapp 3 -n myapp-prod
```

### Common Issues

**Issue: "Cannot connect to Kubernetes cluster"**
- Solution: Verify KUBECONFIG is correctly encoded and not expired

**Issue: "Deployment timeout"**
- Solution: Increase `ROLLOUT_TIMEOUT` or check pod logs for startup issues

**Issue: "Values file not found"**
- Solution: Ensure values file exists or set `VALUES_FILE` explicitly

**Issue: "Image pull errors"**
- Solution: Verify image exists and registry credentials are configured

## Support

For issues, questions, or contributions:
- Repository: https://github.com/nayaksuraj/test-repo
- Documentation: See repository wiki
- Issues: GitHub Issues

## License

MIT License - See repository for details
