# Deployment Environments Configuration Guide

This guide explains how to configure Bitbucket Deployment Environments for proper environment management, access control, and deployment tracking.

## 📋 Table of Contents

- [Overview](#overview)
- [Environment Setup](#environment-setup)
- [Deployment Restrictions](#deployment-restrictions)
- [Environment Variables](#environment-variables)
- [Best Practices](#best-practices)

## 🎯 Overview

Bitbucket Deployment Environments provide:
- **Deployment tracking**: View deployment history per environment
- **Access control**: Restrict who can deploy to specific environments
- **Environment-specific variables**: Separate configs for dev/staging/production
- **Deployment gates**: Manual approvals for sensitive environments
- **Integration**: Connect with monitoring tools (Datadog, New Relic, etc.)

## 🏗️ Environment Setup

### Step 1: Create Environments in Bitbucket

1. Go to **Repository Settings** → **Deployments**
2. Click **Add environment**
3. Create three environments:

#### Development Environment
```
Name: development
Type: Test
Category: Development
```
**Configuration:**
- No deployment restrictions
- Auto-deploy from `develop` branch
- No manual approval required

#### Staging Environment
```
Name: staging
Type: Staging
Category: Staging
```
**Configuration:**
- Deployment restrictions: Team leads only
- Manual approval required
- Deploy from `main` branch or release candidates

#### Production Environment
```
Name: production
Type: Production
Category: Production
```
**Configuration:**
- Deployment restrictions: Designated deployers only
- Manual approval required (2 reviewers recommended)
- Deploy from tagged releases only (`v*`)
- Enable deployment lock during incidents

### Step 2: Configure Deployment Permissions

#### Development
```
Permissions: All team members
Approvals required: 0
Deployment lock: Disabled
```

#### Staging
```
Permissions: Developers + Team Leads
Approvals required: 1
Deployment lock: Enabled (manual override)
Who can approve: Team Leads
```

#### Production
```
Permissions: Team Leads + Release Managers
Approvals required: 2
Deployment lock: Enabled (admin override only)
Who can approve: Team Leads + CTO
Emergency hotfix: Designated on-call engineer
```

### Step 3: Environment Variables per Environment

Configure these in **Repository Settings** → **Pipelines** → **Deployments**:

#### Development Variables
```bash
KUBECONFIG_DEV=<base64-encoded-kubeconfig>
DEPLOY_NAMESPACE=development
HELM_VALUES_FILE=values-dev.yaml
REPLICAS=1
RESOURCES_LIMITS_CPU=500m
RESOURCES_LIMITS_MEMORY=512Mi
MONITORING_ENABLED=false
DEBUG_MODE=true
LOG_LEVEL=debug
```

#### Staging Variables
```bash
KUBECONFIG_STAGING=<base64-encoded-kubeconfig>
DEPLOY_NAMESPACE=staging
HELM_VALUES_FILE=values-staging.yaml
REPLICAS=2
RESOURCES_LIMITS_CPU=1000m
RESOURCES_LIMITS_MEMORY=1Gi
MONITORING_ENABLED=true
DEBUG_MODE=false
LOG_LEVEL=info
DATADOG_API_KEY=<staging-api-key>
```

#### Production Variables
```bash
KUBECONFIG_PRODUCTION=<base64-encoded-kubeconfig>
DEPLOY_NAMESPACE=production
HELM_VALUES_FILE=values-production.yaml
REPLICAS=3
RESOURCES_LIMITS_CPU=2000m
RESOURCES_LIMITS_MEMORY=2Gi
MONITORING_ENABLED=true
DEBUG_MODE=false
LOG_LEVEL=warn
DATADOG_API_KEY=<production-api-key>
NEWRELIC_LICENSE_KEY=<production-license>
PAGERDUTY_INTEGRATION_KEY=<integration-key>
ROLLBACK_ON_FAILURE=true
CANARY_ENABLED=true
CANARY_PERCENTAGE=10
```

## 🔒 Deployment Restrictions

### Branch Protection Rules

Configure in **Repository Settings** → **Branch Permissions**:

#### Main Branch
```
Branch: main
Restrictions:
  - Prevent deletion: ✅
  - Require pull request: ✅
  - Require approvals: 2
  - Require passing builds: ✅
  - Prevent force push: ✅
  - Merge strategy: Merge commit or squash
```

#### Develop Branch
```
Branch: develop
Restrictions:
  - Prevent deletion: ✅
  - Require pull request: ✅
  - Require approvals: 1
  - Require passing builds: ✅
  - Prevent force push: ✅
```

### Deployment Gates

Pipeline configuration automatically enforces:

```yaml
# Development - Auto-deploy
- step:
    name: Deploy to Dev
    deployment: development  # No manual trigger

# Staging - Manual approval
- step:
    name: Deploy to Staging
    deployment: staging
    trigger: manual  # Requires manual approval

# Production - Manual approval + restrictions
- step:
    name: Deploy to Production
    deployment: production
    trigger: manual  # Requires manual approval + environment permissions
```

## 🔐 Securing Sensitive Variables

### Mark as Secured

All sensitive variables MUST be marked as "Secured" in Bitbucket:
- `KUBECONFIG_DEV`
- `KUBECONFIG_STAGING`
- `KUBECONFIG_PRODUCTION`
- `DOCKER_PASSWORD`
- `SONAR_TOKEN`
- `SLACK_WEBHOOK_URL`
- `DATADOG_API_KEY`
- `NEWRELIC_LICENSE_KEY`
- `PAGERDUTY_INTEGRATION_KEY`

### Variable Scope

```
Repository-level variables:
  - DOCKER_REGISTRY
  - DOCKER_REPOSITORY
  - DOCKER_USERNAME
  - SONAR_PROJECT_KEY
  - SLACK_WEBHOOK_URL

Environment-specific variables:
  - KUBECONFIG (per environment)
  - API keys (per environment)
  - Resource limits (per environment)
  - Feature flags (per environment)
```

## 📊 Monitoring & Observability

### Integrate with Monitoring Tools

#### Datadog Integration
```yaml
- step:
    name: Deploy to Production
    script:
      - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
      - |
        curl -X POST "https://api.datadoghq.com/api/v1/events" \
          -H "Content-Type: application/json" \
          -H "DD-API-KEY: ${DATADOG_API_KEY}" \
          -d '{
            "title": "Production Deployment",
            "text": "Version ${BITBUCKET_TAG} deployed",
            "tags": ["env:production", "service:myapp"]
          }'
```

#### New Relic Deployment Marker
```yaml
- step:
    name: Record Deployment
    script:
      - |
        curl -X POST "https://api.newrelic.com/v2/applications/${APP_ID}/deployments.json" \
          -H "X-Api-Key:${NEWRELIC_API_KEY}" \
          -H "Content-Type: application/json" \
          -d '{
            "deployment": {
              "revision": "${BITBUCKET_TAG}",
              "user": "${BITBUCKET_REPO_OWNER}"
            }
          }'
```

## ✅ Best Practices

### 1. Environment Parity
- Keep environments as similar as possible
- Use same Docker images across environments
- Only vary configuration via environment variables
- Test in staging exactly as production

### 2. Progressive Deployment
```
Developer → Dev Environment (auto)
  ↓
PR Review → Staging (manual)
  ↓
QA Testing → Staging validation
  ↓
Release Tag → Production (manual + approvals)
  ↓
Canary → 10% traffic
  ↓
Full Rollout → 100% traffic
```

### 3. Rollback Strategy
```yaml
# Always have a rollback plan
custom:
  rollback-production:
    - step:
        deployment: production
        trigger: manual
        script:
          - pipe: docker://nayaksuraj/deploy-pipe:1.0.0
            variables:
              ROLLBACK: "true"
```

### 4. Deployment Windows
```
Production deployments:
  - Preferred: Tuesday-Thursday, 10 AM - 2 PM
  - Avoid: Fridays, weekends, holidays
  - Hotfixes: Anytime with on-call approval
```

### 5. Change Management
- Every production deployment needs:
  - Jira ticket reference
  - Changelog entry
  - Rollback plan documented
  - On-call engineer notified
  - Monitoring dashboard ready

### 6. Deployment Checklist

Before deploying to production:
- [ ] All tests passing in CI
- [ ] Security scan results reviewed
- [ ] Successfully deployed to staging
- [ ] QA sign-off received
- [ ] Performance testing completed
- [ ] Database migrations tested
- [ ] Rollback plan documented
- [ ] On-call engineer notified
- [ ] Stakeholders informed
- [ ] Monitoring alerts configured

## 🚨 Emergency Procedures

### Hotfix Deployment
```bash
# Use custom pipeline for emergency fixes
Pipelines → Run pipeline → Custom: hotfix-deploy

# Requires:
1. Critical bug/security issue
2. On-call engineer approval
3. Fast-tracked testing
4. Immediate rollback readiness
```

### Rollback Procedure
```bash
# Immediate rollback
Pipelines → Run pipeline → Custom: rollback-production

# Or manual:
kubectl rollout undo deployment/myapp -n production
helm rollback myapp -n production
```

### Deployment Lock
```
During incidents:
1. Enable deployment lock on production
2. Block all deployments until resolved
3. Only allow emergency hotfixes
4. Remove lock after incident closure
```

## 📚 Additional Resources

- [Bitbucket Deployments Documentation](https://support.atlassian.com/bitbucket-cloud/docs/set-up-and-monitor-deployments/)
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Helm Rollback Guide](https://helm.sh/docs/helm/helm_rollback/)
- [Canary Deployments Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)

---

**Maintained by**: DevOps Team
**Last Updated**: 2025-11-15
**Review Cycle**: Quarterly
