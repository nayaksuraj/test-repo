# Generic Helm Chart for Kubernetes Applications

A production-ready, reusable Helm chart for deploying containerized applications to Kubernetes. Supports Spring Boot, Node.js, Python, Go, and any containerized application.

## Features

- ✅ **Framework Agnostic**: Works with any containerized application
- ✅ **Production Ready**: Includes health checks, resource limits, security contexts
- ✅ **Auto-scaling**: Horizontal Pod Autoscaler (HPA) support
- ✅ **High Availability**: Pod Disruption Budget, rolling updates
- ✅ **Security**: Non-root user, read-only filesystem options, security contexts
- ✅ **Monitoring**: Prometheus ServiceMonitor integration
- ✅ **Ingress**: NGINX ingress with TLS support
- ✅ **ConfigMaps & Secrets**: Easy configuration management
- ✅ **Multi-Environment**: Separate values files for dev, staging, production

## Quick Start

### Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.0+
- kubectl configured to access your cluster

### Basic Installation

```bash
# Install with default values (requires image.repository override)
helm install myapp ./helm-chart \
  --set image.repository=docker.io/myorg/myapp \
  --set image.tag=1.0.0
```

### Install with Environment-Specific Values

```bash
# Development
helm install myapp ./helm-chart \
  -f helm-chart/values-dev.yaml \
  --set image.repository=registry.company.com/myapp

# Staging
helm install myapp ./helm-chart \
  -f helm-chart/values-stage.yaml \
  --set image.repository=registry.company.com/myapp \
  --set image.tag=1.2.0

# Production
helm install myapp ./helm-chart \
  -f helm-chart/values-prod.yaml \
  --set image.repository=registry.company.com/myapp \
  --set image.tag=1.2.0
```

### Upgrade Release

```bash
helm upgrade myapp ./helm-chart \
  -f helm-chart/values-prod.yaml \
  --set image.tag=1.3.0
```

### Uninstall

```bash
helm uninstall myapp
```

## Configuration

### Required Values

| Parameter | Description | Example |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `docker.io/myorg/myapp` |
| `image.tag` | Image tag (defaults to Chart.appVersion) | `1.0.0` |

### Common Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container target port | `8080` |
| `resources.limits.cpu` | CPU limit | `1000m` |
| `resources.limits.memory` | Memory limit | `1Gi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `512Mi` |

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com
```

### Auto-scaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

### Health Checks

The chart includes configurable liveness, readiness, and startup probes:

```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness  # Change for your app
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /actuator/health/readiness  # Change for your app
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

startupProbe:
  httpGet:
    path: /actuator/health/liveness  # Change for your app
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

### Environment Variables

```yaml
env:
  - name: SPRING_PROFILES_ACTIVE
    value: "production"
  - name: JAVA_OPTS
    value: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# From ConfigMap
envFrom:
  - configMapRef:
      name: app-config

# From Secret
envFromSecret:
  - secretRef:
      name: app-secrets
```

### ConfigMaps

```yaml
configMap:
  enabled: true
  data:
    application.yaml: |
      server:
        port: 8080
      logging:
        level:
          root: INFO
```

### Secrets

```yaml
secret:
  enabled: true
  data:
    DATABASE_PASSWORD: "cGFzc3dvcmQ="  # base64 encoded
    API_KEY: "YXBpLWtleS1oZXJl"  # base64 encoded
```

## Security Best Practices

The chart implements security best practices by default:

```yaml
# Pod Security Context
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001

# Container Security Context
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false
  capabilities:
    drop:
      - ALL
```

## Monitoring

### Prometheus Integration

Enable ServiceMonitor for Prometheus Operator:

```yaml
serviceMonitor:
  enabled: true
  interval: 30s
  path: /actuator/prometheus  # Or /metrics for other frameworks
  labels:
    prometheus: kube-prometheus
```

### Pod Annotations

```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/actuator/prometheus"
```

## Examples

### Spring Boot Application

```bash
helm install myspringapp ./helm-chart \
  --set image.repository=myregistry/springapp \
  --set image.tag=1.0.0 \
  --set service.targetPort=8080 \
  --set livenessProbe.httpGet.path=/actuator/health/liveness \
  --set readinessProbe.httpGet.path=/actuator/health/readiness
```

### Node.js Application

```bash
helm install mynodeapp ./helm-chart \
  --set image.repository=myregistry/nodeapp \
  --set image.tag=2.0.0 \
  --set service.targetPort=3000 \
  --set livenessProbe.httpGet.path=/health \
  --set readinessProbe.httpGet.path=/ready
```

### Python Flask/FastAPI Application

```bash
helm install mypythonapp ./helm-chart \
  --set image.repository=myregistry/pythonapp \
  --set image.tag=3.0.0 \
  --set service.targetPort=5000 \
  --set livenessProbe.httpGet.path=/health \
  --set readinessProbe.httpGet.path=/health
```

## Values Files Structure

```
helm-chart/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── values-dev.yaml         # Development overrides
├── values-stage.yaml       # Staging overrides
├── values-prod.yaml        # Production overrides
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── configmap.yaml
    ├── secret.yaml
    ├── serviceaccount.yaml
    ├── hpa.yaml
    ├── pdb.yaml
    ├── servicemonitor.yaml
    ├── _helpers.tpl        # Template helpers
    └── NOTES.txt           # Post-install notes
```

## Customization

### Override Chart Name

```bash
helm install myapp ./helm-chart \
  --set nameOverride=custom-name \
  --set image.repository=myregistry/app
```

### Override Full Name

```bash
helm install myapp ./helm-chart \
  --set fullnameOverride=my-custom-app-name \
  --set image.repository=myregistry/app
```

### Add Extra Labels

```yaml
extraLabels:
  team: platform
  cost-center: engineering
  environment: production
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=app
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=app --tail=100 -f
```

### Describe Deployment

```bash
kubectl describe deployment myapp
```

### Check HPA Status

```bash
kubectl get hpa myapp
```

### Debug Template Rendering

```bash
helm template myapp ./helm-chart \
  --set image.repository=test/app \
  --debug
```

## Testing

### Lint the Chart

```bash
helm lint ./helm-chart
```

### Dry Run

```bash
helm install myapp ./helm-chart \
  --set image.repository=test/app \
  --dry-run --debug
```

### Template Validation

```bash
helm template myapp ./helm-chart \
  --set image.repository=test/app \
  --validate
```

## CI/CD Integration

See the parent repository's `scripts/helm-package.sh` for automated Helm chart packaging and publishing in CI/CD pipelines.

## Contributing

This is a reference implementation. Feel free to customize for your needs.

## License

This chart is provided as-is for demonstration and educational purposes.

## Support

For issues or questions:
- Open an issue in the repository
- Review the Helm documentation: https://helm.sh/docs/
