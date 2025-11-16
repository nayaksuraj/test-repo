# Generic Helm Chart for Kubernetes Applications

A production-ready, reusable Helm chart for deploying containerized applications to Kubernetes. Supports Spring Boot, Node.js, Python, Go, and any containerized application.

## Features

### Core Features
- ✅ **Framework Agnostic**: Works with any containerized application
- ✅ **Production Ready**: Includes health checks, resource limits, security contexts
- ✅ **Auto-scaling**: HPA and KEDA support
- ✅ **High Availability**: Pod Disruption Budget, rolling updates, topology spread
- ✅ **Security**: Network policies, non-root user, security contexts
- ✅ **Monitoring**: Prometheus ServiceMonitor, PrometheusRules
- ✅ **Ingress**: NGINX ingress with TLS support
- ✅ **ConfigMaps & Secrets**: Easy configuration management + External Secrets
- ✅ **Multi-Environment**: Separate values files for dev, staging, production

### Advanced Features (v2.0+)
- ✅ **Network Policies**: Control pod-to-pod communication
- ✅ **Init Containers**: Pre-flight checks and setup
- ✅ **Sidecar Containers**: Multi-container pods
- ✅ **Lifecycle Hooks**: Graceful shutdown and startup
- ✅ **Topology Spread Constraints**: Better pod distribution
- ✅ **External Secrets**: AWS Secrets Manager, Vault, etc.
- ✅ **KEDA**: Event-driven autoscaling
- ✅ **Certificate Management**: Automated TLS with cert-manager
- ✅ **Helm Tests**: Automated deployment validation
- ✅ **Persistent Storage**: PVC support
- ✅ **VPA**: Vertical Pod Autoscaler
- ✅ **Istio**: Service mesh integration
- ✅ **CronJobs**: Scheduled task execution
- ✅ **Headless Service**: StatefulSet support

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

## Advanced Features

### Network Policies

Control pod-to-pod communication for enhanced security:

```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: backend
      ports:
      - protocol: TCP
        port: 8080
  egress:
    - to:
      - namespaceSelector: {}
      ports:
      - protocol: TCP
        port: 5432  # PostgreSQL
```

### Init Containers

Run setup tasks before main container starts:

```yaml
initContainers:
  - name: wait-for-db
    image: busybox:1.36
    command: ['sh', '-c', 'until nc -z postgres 5432; do echo waiting; sleep 2; done']
  - name: migration
    image: myapp:latest
    command: ['npm', 'run', 'migrate']
```

### Sidecar Containers

Add log shippers, proxies, or other supporting containers:

```yaml
sidecars:
  - name: log-shipper
    image: fluent/fluent-bit:2.0
    volumeMounts:
    - name: logs
      mountPath: /var/log
```

### Lifecycle Hooks

Graceful shutdown and startup hooks:

```yaml
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "sleep 15"]  # Drain connections
  postStart:
    httpGet:
      path: /warmup
      port: 8080
```

### External Secrets

Integrate with AWS Secrets Manager, Vault, etc:

```yaml
externalSecret:
  enabled: true
  secretStore: aws-secrets
  secretStoreKind: ClusterSecretStore
  data:
    - secretKey: DATABASE_PASSWORD
      remoteKey: prod/db/password
    - secretKey: API_KEY
      remoteKey: prod/api/key
```

### KEDA Event-Driven Autoscaling

Scale based on metrics, queues, or custom events:

```yaml
keda:
  enabled: true
  minReplicas: 2
  maxReplicas: 50
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus:9090
        query: sum(rate(http_requests_total[2m]))
        threshold: '100'
```

### Certificate Management

Automated TLS certificates with cert-manager:

```yaml
certificate:
  enabled: true
  issuerRef: letsencrypt-prod
  dnsNames:
    - app.example.com
    - www.app.example.com
```

### Helm Tests

Validate deployments automatically:

```bash
helm test myapp
```

```yaml
tests:
  enabled: true
  healthCheck:
    enabled: true
    path: /health
```

### Persistent Storage

Add persistent volumes for stateful apps:

```yaml
persistence:
  enabled: true
  size: 20Gi
  storageClass: fast-ssd
  accessModes:
    - ReadWriteOnce
```

### Prometheus Alerting Rules

Custom alerts for your application:

```yaml
prometheusRules:
  enabled: true
  rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status="500"}[5m]) > 0.05
      for: 10m
      labels:
        severity: critical
      annotations:
        summary: High error rate detected
```

### Vertical Pod Autoscaler

Automatically adjust resource requests:

```yaml
vpa:
  enabled: true
  updateMode: Auto
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2000m
        memory: 2Gi
```

### Istio Service Mesh

Advanced traffic management:

```yaml
istio:
  enabled: true
  hosts:
    - app.example.com
  gateways:
    - istio-system/default-gateway
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
```

### CronJobs

Run scheduled tasks:

```yaml
cronJob:
  enabled: true
  schedule: "0 2 * * *"  # 2 AM daily
  command:
    - /bin/sh
    - -c
    - npm run backup
```

### Topology Spread Constraints

Better pod distribution across zones:

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: app
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
