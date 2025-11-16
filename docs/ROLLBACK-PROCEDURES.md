# Rollback Procedures

Comprehensive guide for rolling back deployments across all environments when issues are detected.

## 🎯 Quick Reference

| Severity | Action | Timeline | Approvals |
|----------|--------|----------|-----------|
| **P0 - Critical** | Immediate rollback | < 5 minutes | On-call approval |
| **P1 - High** | Rollback after verification | < 15 minutes | Team lead approval |
| **P2 - Medium** | Planned rollback | < 1 hour | Standard process |
| **P3 - Low** | Fix forward or rollback | < 4 hours | Standard process |

## 🚨 Emergency Rollback (P0/P1)

### Method 1: Bitbucket Pipeline (Recommended)

#### Step 1: Trigger Rollback Pipeline
```bash
# Navigate to: Pipelines → Run pipeline → Custom
# Select: rollback-production
# Click: Run
```

#### Step 2: Monitor Rollback
```bash
# Watch pipeline execution
# Verify health checks
# Confirm application recovery
```

#### Step 3: Verify
```bash
# Check application metrics
curl -f https://api.example.com/health

# Check Kubernetes deployment
kubectl get pods -n production
kubectl rollout status deployment/myapp -n production

# Verify version
kubectl describe deployment myapp -n production | grep Image
```

### Method 2: Manual Kubernetes Rollback

#### Helm Rollback
```bash
# List releases
helm list -n production

# Check history
helm history myapp -n production

# Rollback to previous version
helm rollback myapp -n production

# Or rollback to specific revision
helm rollback myapp 5 -n production

# Wait for rollout
kubectl rollout status deployment/myapp -n production
```

#### Kubectl Rollback
```bash
# Check rollout history
kubectl rollout history deployment/myapp -n production

# Rollback to previous revision
kubectl rollout undo deployment/myapp -n production

# Or rollback to specific revision
kubectl rollout undo deployment/myapp -n production --to-revision=3

# Verify
kubectl rollout status deployment/myapp -n production
kubectl get pods -n production -w
```

### Method 3: Manual Re-deploy Previous Version

```bash
# If automated rollback fails, manually deploy last known good version
helm upgrade myapp ./helm-chart \
  -n production \
  -f values-production.yaml \
  --set image.tag=v1.2.3 \  # Last known good version
  --wait \
  --timeout 10m
```

## 📋 Rollback Decision Matrix

### When to Rollback

| Scenario | Rollback? | Method |
|----------|-----------|--------|
| 5xx errors > 5% | ✅ Yes - Immediate | Automated pipeline |
| Response time > 2x baseline | ✅ Yes - Immediate | Automated pipeline |
| CPU/Memory > 90% | ✅ Yes - After diagnosis | Manual |
| Failed health checks | ✅ Yes - Immediate | Automated pipeline |
| Security vulnerability discovered | ✅ Yes - Immediate | Manual + hotfix |
| Database migration failed | ⚠️ Depends | Manual + restore |
| Minor UI bug | ❌ No - Fix forward | Next release |
| Non-critical feature broken | ❌ No - Fix forward | Hotfix |

### When NOT to Rollback

- Database schema changes that are **irreversible**
- When rollback would cause **data loss**
- When the issue is **infrastructure-related** (not application)
- When **fix forward** is faster and safer

## 🔄 Rollback Procedures by Environment

### Development Environment

```yaml
# Automated via pipeline
Pipelines → Custom → rollback-dev

# Or manual
helm rollback myapp -n development
```

**No approvals required** - Developers can rollback freely

### Staging Environment

```yaml
# Via pipeline (recommended)
Pipelines → Custom → rollback-staging

# Manual command
helm rollback myapp -n staging
```

**Approvals required**: Team lead notification

### Production Environment

```yaml
# Via pipeline (RECOMMENDED)
Pipelines → Custom → rollback-production

# This triggers:
1. Helm rollback to previous release
2. Health check verification
3. Slack notification
4. Incident logging
```

**Approvals required**:
- P0/P1: On-call engineer approval
- P2/P3: Team lead + 1 reviewer

## 📊 Post-Rollback Checklist

### Immediate Actions (< 5 minutes)

- [ ] Verify application is responding
- [ ] Check error rates returned to baseline
- [ ] Confirm database connections stable
- [ ] Verify monitoring dashboards green
- [ ] Update status page

### Short-term Actions (< 30 minutes)

- [ ] Notify stakeholders via Slack
- [ ] Create incident report
- [ ] Document root cause (preliminary)
- [ ] Tag faulty release in Git
- [ ] Block faulty version from deployment
- [ ] Update runbook if needed

### Follow-up Actions (< 24 hours)

- [ ] Complete post-mortem
- [ ] Identify prevention measures
- [ ] Create Jira tickets for fixes
- [ ] Update deployment checklist
- [ ] Share learnings with team
- [ ] Update monitoring/alerts if gaps found

## 🔍 Verification Steps

### Application Health

```bash
# 1. Health endpoint
curl -f https://api.example.com/health
# Expected: 200 OK

# 2. Metrics endpoint
curl https://api.example.com/metrics
# Check: error rate, response time, throughput

# 3. Smoke tests
./scripts/smoke-test.sh production
```

### Infrastructure Health

```bash
# 1. Pod status
kubectl get pods -n production
# All pods should be Running

# 2. Recent events
kubectl get events -n production --sort-by='.lastTimestamp' | tail -20
# Check for errors

# 3. Resource usage
kubectl top pods -n production
kubectl top nodes

# 4. Service endpoints
kubectl get endpoints -n production
```

### Monitoring Checks

```bash
# Datadog
- Check dashboard: Error Rate, Response Time, Throughput
- Verify alerts are resolved
- Confirm no new anomalies

# New Relic
- Check APM dashboard
- Verify transaction traces
- Confirm error rate < baseline

# Logs
kubectl logs -n production deployment/myapp --tail=100
# Look for startup errors
```

## 🔧 Troubleshooting Failed Rollbacks

### Scenario 1: Rollback Stuck

```bash
# Check rollout status
kubectl rollout status deployment/myapp -n production

# If stuck, force restart
kubectl rollout restart deployment/myapp -n production

# Check for resource constraints
kubectl describe nodes
kubectl describe pods -n production
```

### Scenario 2: Database Migration Issues

```bash
# Check if migrations can rollback
./manage.py migrate --list

# Manual rollback if needed
./manage.py migrate app_name 0042_previous_migration

# Restore from backup (last resort)
./scripts/restore-db.sh production backup-2024-11-15
```

### Scenario 3: PersistentVolumeClaim Issues

```bash
# Check PVC status
kubectl get pvc -n production

# Check events
kubectl describe pvc data-pvc -n production

# May need to manually update PVC
kubectl edit pvc data-pvc -n production
```

### Scenario 4: Ingress/Load Balancer Issues

```bash
# Check ingress
kubectl get ingress -n production
kubectl describe ingress myapp -n production

# Check service
kubectl get svc -n production
kubectl describe svc myapp -n production

# May need to recreate ingress
kubectl delete ingress myapp -n production
helm upgrade --force myapp ./helm-chart -n production
```

## 📞 Escalation Path

### Level 1: Development Team (0-15 minutes)
- Initial rollback attempt
- Basic troubleshooting
- Stakeholder notification

### Level 2: DevOps Team (15-30 minutes)
- Infrastructure investigation
- Advanced rollback procedures
- Database rollback if needed

### Level 3: Engineering Leadership (30-60 minutes)
- Decision on extended downtime
- Communication to executives
- Resource allocation for incident

### Level 4: Executive Team (> 60 minutes)
- Public communication
- Customer notifications
- Business continuity decisions

## 📝 Rollback Templates

### Slack Notification Template

```markdown
🚨 **PRODUCTION ROLLBACK INITIATED**

**Environment**: Production
**Service**: myapp
**From Version**: v1.3.0
**To Version**: v1.2.5
**Triggered By**: @john.doe
**Reason**: High error rate (12% 5xx errors)
**Status**: In Progress
**ETA**: 5 minutes

**Actions Taken**:
- Triggered automated rollback pipeline
- Monitoring dashboards: [Link]
- Incident ticket: INCIDENT-123

**Next Steps**:
- Verify health checks
- Monitor error rates
- Update stakeholders
```

### Post-Mortem Template

```markdown
# Post-Mortem: Production Rollback - 2024-11-15

## Incident Summary
**Date**: 2024-11-15
**Duration**: 12 minutes
**Impact**: 12% error rate, ~1000 affected requests
**Severity**: P1

## Timeline
- 14:23 - Deployment of v1.3.0 completed
- 14:25 - Error rate spike detected (12%)
- 14:26 - On-call engineer notified
- 14:27 - Rollback initiated
- 14:32 - Rollback completed
- 14:35 - Metrics returned to baseline

## Root Cause
Database connection pool exhaustion due to missing connection limit in v1.3.0

## What Went Well
- Automated monitoring detected issue quickly
- Rollback pipeline worked perfectly
- Team responded within SLA

## What Could Be Improved
- Pre-deployment load testing missed this scenario
- Connection pool config should be in staging parity
- Need better load testing in staging

## Action Items
- [ ] Add connection pool load tests (Owner: @jane, Due: 2024-11-20)
- [ ] Update staging to match production config (Owner: @bob, Due: 2024-11-18)
- [ ] Add connection pool monitoring (Owner: @alice, Due: 2024-11-22)
```

## 🎓 Training & Drills

### Quarterly Rollback Drill

```markdown
Schedule: First Tuesday of each quarter
Participants: All engineers
Duration: 30 minutes

Exercise:
1. Deploy test version to staging
2. Introduce controlled failure
3. Detect issue via monitoring
4. Execute rollback procedure
5. Verify recovery
6. Document learnings

Success Criteria:
- Rollback completed < 10 minutes
- No manual intervention needed
- All team members know procedure
```

## 📚 Additional Resources

- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Helm Rollback Documentation](https://helm.sh/docs/helm/helm_rollback/)
- [Incident Response Best Practices](https://response.pagerduty.com/)
- [Post-Mortem Templates](https://github.com/dastergon/postmortem-templates)

---

**Maintained by**: DevOps Team
**Last Updated**: 2025-11-15
**Review Cycle**: Quarterly
**On-Call**: See PagerDuty schedule
