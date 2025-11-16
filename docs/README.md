# Documentation Index

Complete documentation for the nayaksuraj/test-repo CI/CD pipeline templates and Helm charts.

## 📚 Table of Contents

### Pipeline Documentation

- **[Pipeline Templates](PIPELINE-TEMPLATES.md)** - Complete guide to using language-specific and universal pipeline templates
- **[Pipeline Reusability](PIPELINE-REUSABILITY.md)** - Best practices for reusable pipelines, adoption strategies, and ROI metrics
- **[Reusable Pipelines Overview](REUSABLE-PIPELINES.md)** - High-level overview of the reusable pipeline architecture

### Deployment & Operations

- **[Deployment Environments](DEPLOYMENT-ENVIRONMENTS.md)** - Configuration guide for dev, staging, and production environments
- **[Helm Registry Setup](HELM-REGISTRY-SETUP.md)** - Complete guide to setting up Helm chart registries (OCI, ChartMuseum, Harbor)
- **[Rollback Procedures](ROLLBACK-PROCEDURES.md)** - Step-by-step rollback procedures for all environments

### Helm Charts

- **[Helm Chart Documentation](../helm-chart/README.md)** - Complete documentation for the generic Helm chart (v2.0.0)

### Examples

- **[Python Example](../examples/python/)** - Python-specific pipeline example
- **[Java Maven Example](../examples/java-maven/)** - Java Maven project example
- **[Java Gradle Example](../examples/java-gradle/)** - Java Gradle project example
- **[Node.js Example](../examples/nodejs/)** - Node.js application example
- **[Go Example](../examples/golang/)** - Golang application example
- **[.NET Example](../examples/dotnet/)** - .NET Core application example
- **[Rust Example](../examples/rust/)** - Rust application example
- **[Ruby Example](../examples/ruby/)** - Ruby application example
- **[PHP Example](../examples/php/)** - PHP application example

## 🚀 Quick Start

### For New Projects

1. **Choose your template** from [Pipeline Templates](PIPELINE-TEMPLATES.md)
2. **Copy to your repository**:
   ```bash
   cp pipeline-templates/python-template.yml bitbucket-pipelines.yml
   ```
3. **Configure variables** - See [Deployment Environments](DEPLOYMENT-ENVIRONMENTS.md)
4. **Set up Helm registry** - See [Helm Registry Setup](HELM-REGISTRY-SETUP.md)
5. **Commit and push** - Pipeline runs automatically

### For Existing Projects

1. **Review** [Pipeline Reusability](PIPELINE-REUSABILITY.md) guide
2. **Choose adoption strategy** (Direct Copy, Central Repo, or Hybrid)
3. **Migrate gradually** following the adoption roadmap
4. **Monitor and iterate**

## 📖 Documentation Structure

```
docs/
├── README.md                      # This file - documentation index
├── PIPELINE-TEMPLATES.md          # Pipeline template usage guide
├── PIPELINE-REUSABILITY.md        # Reusability best practices
├── REUSABLE-PIPELINES.md          # Pipeline architecture overview
├── DEPLOYMENT-ENVIRONMENTS.md     # Environment configuration
├── HELM-REGISTRY-SETUP.md         # Helm registry setup guide
└── ROLLBACK-PROCEDURES.md         # Rollback procedures

pipeline-templates/                # Template files
├── universal-template.yml         # Universal language-agnostic template
├── python-template.yml            # Python-specific template
├── java-maven-template.yml        # Java Maven template
├── java-gradle-template.yml       # Java Gradle template
├── nodejs-template.yml            # Node.js template
├── golang-template.yml            # Go template
├── dotnet-template.yml            # .NET template
├── rust-template.yml              # Rust template
├── ruby-template.yml              # Ruby template
└── php-template.yml               # PHP template

helm-chart/                        # Generic Helm chart (v2.0.0)
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-staging.yaml
├── values-prod.yaml
├── templates/                     # 22 Kubernetes resource templates
└── README.md                      # Helm chart documentation

examples/                          # Language-specific examples
└── {language}/
    ├── bitbucket-pipelines.yml    # Example pipeline
    ├── Dockerfile                 # Multi-stage Dockerfile
    ├── .pre-commit-config.yaml    # Pre-commit configuration
    └── src/                       # Example source code
```

## 🔧 Configuration References

### Required Bitbucket Variables

All templates require these repository variables:

**Docker Registry:**
- `DOCKER_REGISTRY` (e.g., docker.io)
- `DOCKER_REPOSITORY` (e.g., myorg/myapp)
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD` (secured)

**Helm Registry:**
- `HELM_REGISTRY` (e.g., oci://ghcr.io/myorg/charts)
- `HELM_REGISTRY_USERNAME`
- `HELM_REGISTRY_PASSWORD` (secured)

**Kubernetes:**
- `KUBECONFIG_DEV` (base64 encoded, secured)
- `KUBECONFIG_STAGING` (base64 encoded, secured)
- `KUBECONFIG_PRODUCTION` (base64 encoded, secured)

**Optional:**
- `SLACK_WEBHOOK_URL` (secured)
- `SONAR_TOKEN` (secured)

See [Deployment Environments](DEPLOYMENT-ENVIRONMENTS.md) for detailed setup.

## 🎯 Key Features

### Pipeline Templates
- ✅ 9 language-specific templates
- ✅ Universal language-agnostic template
- ✅ Auto-detection of languages and tools
- ✅ Production-ready with security scanning
- ✅ Helm chart packaging and deployment
- ✅ Multi-environment support (dev/staging/prod)

### Helm Chart (v2.0.0)
- ✅ 22 Kubernetes resource templates
- ✅ Generic - works with any containerized app
- ✅ Advanced features: KEDA, Istio, Network Policies, External Secrets, VPA, etc.
- ✅ Production-ready defaults
- ✅ Comprehensive documentation

### Bitbucket Pipes
- 9 organizational pipes for reusability
- Auto-detection eliminates configuration
- Consistent across all templates
- Single source of truth

## 📊 Metrics & Success

Track these KPIs:
- **Template Adoption Rate**: 80% target
- **Time to Setup New Project**: <15 minutes
- **Code Duplication Reduction**: 96%
- **Pipeline Consistency Score**: >90%

See [Pipeline Reusability](PIPELINE-REUSABILITY.md) for detailed metrics.

## 🤝 Contributing

To contribute improvements:
1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request
5. Document your changes

## 📞 Support

- **Issues**: Open a GitHub/Bitbucket issue
- **Questions**: Review documentation or open a discussion
- **Updates**: Check CHANGELOG for version updates

---

**Repository**: https://bitbucket.org/nayaksuraj/test-repo
**Last Updated**: 2025-11-16
**Version**: 2.0.0
