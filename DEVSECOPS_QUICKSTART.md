# DevSecOps Quick Start Guide

## 🚀 Get Started with Shift-Left Security in 15 Minutes

This guide will help you implement the DevSecOps enhancements quickly.

---

## Phase 1: Critical Security (Do This First) - 15 Minutes

### Step 1: Enable Pre-Commit Hooks (5 minutes)

Prevent secrets from being committed:

```bash
# Install pre-commit
pip install pre-commit

# Install the hooks
pre-commit install

# Test it
pre-commit run --all-files
```

**What this does:**
- ✅ Scans for secrets before every commit
- ✅ Checks YAML syntax
- ✅ Validates Dockerfiles
- ✅ Lints shell scripts

### Step 2: Run Secrets Scan (2 minutes)

Check your codebase for existing secrets:

```bash
# Run secrets scanning
./scripts/security-secrets-scan.sh

# If secrets found, remove them and rotate credentials immediately
```

**What to look for:**
- API keys
- Passwords
- Private keys
- AWS credentials
- Database connection strings

### Step 3: Enable Dependency Scanning (5 minutes)

Scan for vulnerable dependencies:

```bash
# Add OWASP Dependency-Check plugin to pom.xml
```

Add to your `pom.xml`:

```xml
<build>
    <plugins>
        <!-- OWASP Dependency-Check Plugin -->
        <plugin>
            <groupId>org.owasp</groupId>
            <artifactId>dependency-check-maven</artifactId>
            <version>9.0.0</version>
            <configuration>
                <failBuildOnCVSS>7</failBuildOnCVSS>
                <suppressionFile>dependency-check-suppressions.xml</suppressionFile>
            </configuration>
            <executions>
                <execution>
                    <goals>
                        <goal>check</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

Then run:

```bash
# Scan dependencies
./scripts/security-sca-scan.sh

# Review security-reports/dependency-check-report.html
```

### Step 4: Enable SBOM Generation (3 minutes)

Add transparency to your supply chain:

Add to your `pom.xml`:

```xml
<build>
    <plugins>
        <!-- CycloneDX SBOM Plugin -->
        <plugin>
            <groupId>org.cyclonedx</groupId>
            <artifactId>cyclonedx-maven-plugin</artifactId>
            <version>2.7.10</version>
            <executions>
                <execution>
                    <phase>package</phase>
                    <goals>
                        <goal>makeAggregateBom</goal>
                    </goals>
                </execution>
            </executions>
            <configuration>
                <outputFormat>all</outputFormat>
                <outputName>bom</outputName>
            </configuration>
        </plugin>
    </plugins>
</build>
```

Then run:

```bash
# Generate SBOM
./scripts/security-sbom-generate.sh

# View SBOM: security-reports/sbom/sbom-cyclonedx.json
```

---

## Phase 2: Pipeline Integration (Next 30 Minutes)

### Option A: Use Enhanced Pipeline (Recommended)

Replace your `bitbucket-pipelines.yml` with the enhanced version:

```bash
# Backup current pipeline
cp bitbucket-pipelines.yml bitbucket-pipelines.yml.backup

# Use enhanced DevSecOps pipeline
cp bitbucket-pipelines-devsecops.yml bitbucket-pipelines.yml

# Commit and push
git add bitbucket-pipelines.yml
git commit -m "Enable DevSecOps pipeline with shift-left security"
git push
```

### Option B: Add Security Steps Gradually

Add security steps one at a time to your existing pipeline:

```yaml
# Add to your pipeline BEFORE build step
- step:
    name: 🔒 Secrets Scanning
    script:
      - chmod +x scripts/security-secrets-scan.sh
      - export FAIL_ON_SECRETS=true
      - ./scripts/security-secrets-scan.sh
```

---

## Phase 3: Configure Security Gates (1 Hour)

### 1. Configure SonarQube (if not using SonarCloud)

```bash
# Set up SonarQube repository variables:
# SONAR_HOST_URL=https://sonarcloud.io (or your server)
# SONAR_TOKEN=<your-token>
# SONAR_ORGANIZATION=<your-org>
# SONAR_ENABLED=true
```

### 2. Configure Security Thresholds

Edit pipeline variables in Bitbucket:

| Variable | Value | Purpose |
|----------|-------|---------|
| `FAIL_ON_SECRETS` | `true` | Block on secrets |
| `CVSS_THRESHOLD` | `7.0` | Block on CVSS >= 7 |
| `FAIL_ON_CVSS` | `true` | Enforce dependency security |
| `TRIVY_EXIT_CODE` | `1` | Block on container vulnerabilities |
| `FAIL_ON_LOW_COVERAGE` | `false` | Start with warnings |

### 3. Create Suppression Files (Optional)

For false positives:

**dependency-check-suppressions.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
    <!-- Example: Suppress a specific CVE -->
    <suppress>
        <notes>False positive - not applicable</notes>
        <cve>CVE-2023-XXXXX</cve>
    </suppress>
</suppressions>
```

---

## Testing Your Security Setup

### Test Locally (Before Pushing)

```bash
# 1. Test secrets scanning
./scripts/security-secrets-scan.sh

# 2. Test dependency scanning
./scripts/security-sca-scan.sh

# 3. Test Dockerfile security
./scripts/security-dockerfile-scan.sh

# 4. Test IaC security
./scripts/security-iac-scan.sh

# 5. Generate SBOM
./scripts/security-sbom-generate.sh

# 6. Run full pipeline simulation
PIPELINE_TYPE=develop ./simulate-pipeline.sh
```

### Test in CI/CD

```bash
# Trigger a pipeline run
git commit --allow-empty -m "test: trigger security pipeline"
git push
```

---

## Security Checklist

### Before Merging to Main

- [ ] Secrets scan passes (no secrets detected)
- [ ] Dependency scan passes (no critical/high CVEs)
- [ ] SAST scan passes (no critical security issues)
- [ ] Unit tests pass (>80% coverage)
- [ ] Integration tests pass
- [ ] SBOM generated
- [ ] Container scan passes
- [ ] Dockerfile security passes
- [ ] IaC security passes

### Before Production Deployment

- [ ] All security scans pass
- [ ] SBOM attached to release
- [ ] Container images signed (optional)
- [ ] Security review completed
- [ ] Change management approved
- [ ] Rollback plan documented

---

## Troubleshooting

### Common Issues

**1. GitLeaks not finding binary**
```bash
# Install manually
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar -xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
```

**2. OWASP Dependency-Check slow first run**
```bash
# Use NVD API key for faster updates
export NVD_API_KEY=<your-key>  # Get from https://nvd.nist.gov/developers/request-an-api-key
```

**3. False Positives**
```bash
# Create suppression file
# See dependency-check-suppressions.xml example above
```

**4. SonarQube connection issues**
```bash
# Verify credentials
curl -u $SONAR_TOKEN: $SONAR_HOST_URL/api/system/status
```

**5. Pre-commit hooks not running**
```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install
pre-commit install --hook-type commit-msg
```

---

## Security Best Practices

### Developer Workflow

```bash
# Daily workflow with security
1. git pull
2. pre-commit run --all-files  # Validate before coding
3. <make changes>
4. git add .
5. git commit -m "..."  # Pre-commit hooks run automatically
6. git push
```

### Handling Security Findings

#### 1. Secrets Detected
```bash
# DO NOT PUSH!
# 1. Remove the secret from code
# 2. Add to .gitignore or use environment variables
# 3. Rotate the compromised credential
# 4. Use git-filter-repo if already committed:
#    git filter-repo --invert-paths --path <file-with-secret>
```

#### 2. Vulnerable Dependency
```bash
# 1. Update to patched version
mvn versions:display-dependency-updates

# 2. If no patch available:
#    - Consider alternative library
#    - Implement compensating controls
#    - Add suppression with security team approval
```

#### 3. SAST Issue
```bash
# 1. Review the issue in SonarQube
# 2. Fix the security vulnerability
# 3. Mark as false positive if not applicable (with justification)
```

---

## Metrics to Track

### Weekly Security Metrics

```bash
# Generate security dashboard
cat << 'EOF' > security-metrics.sh
#!/bin/bash
echo "Security Metrics - Week of $(date +%Y-%m-%d)"
echo "============================================="
echo ""
echo "Secrets Scans:"
find security-reports -name "gitleaks-report.json" -mtime -7 -exec jq '. | length' {} \; | awk '{sum+=$1} END {print "  Total secrets found: " sum}'
echo ""
echo "Dependency Vulnerabilities:"
find security-reports -name "dependency-check-report.json" -mtime -7 -exec jq '[.dependencies[].vulnerabilities[]? | select(.severity=="CRITICAL")] | length' {} \; | awk '{sum+=$1} END {print "  Critical: " sum}'
find security-reports -name "dependency-check-report.json" -mtime -7 -exec jq '[.dependencies[].vulnerabilities[]? | select(.severity=="HIGH")] | length' {} \; | awk '{sum+=$1} END {print "  High: " sum}'
EOF
chmod +x security-metrics.sh
```

### Monthly Security Review

- [ ] Review all suppressed vulnerabilities
- [ ] Update dependencies
- [ ] Review security tool versions
- [ ] Conduct security training
- [ ] Update security policies
- [ ] Review access controls

---

## Next Steps

### After Basic Implementation

1. **Enable Container Signing**
   ```bash
   # Install Cosign
   curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
   sudo mv cosign-linux-amd64 /usr/local/bin/cosign
   sudo chmod +x /usr/local/bin/cosign
   ```

2. **Implement DAST**
   - OWASP ZAP for dynamic testing
   - Run against staging environment
   - Automate API security testing

3. **Add Policy as Code**
   - Open Policy Agent (OPA)
   - Enforce security policies
   - Validate at admission time

4. **Integrate with Security Dashboard**
   - DefectDojo
   - ThreadFix
   - ASPM tools

---

## Resources

### Documentation
- [DEVSECOPS_ASSESSMENT.md](./DEVSECOPS_ASSESSMENT.md) - Full assessment and roadmap
- [PIPELINE_SIMULATOR.md](./PIPELINE_SIMULATOR.md) - Test pipelines locally
- [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md) - CI/CD configuration

### Security Tools
- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)
- [SLSA Framework](https://slsa.dev/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)

### Training
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Secure Code Warrior](https://www.securecodewarrior.com/)
- [GitHub Security Lab](https://securitylab.github.com/)

---

## Support

### Getting Help

1. **Check the logs**: `security-reports/` directory
2. **Review documentation**: This folder's markdown files
3. **Test locally**: Use `simulate-pipeline.sh`
4. **Gradual rollout**: Start with warnings, then enforce

### Contact

- Security Team: security@example.com
- DevOps Team: devops@example.com
- On-call: #security-oncall

---

## Success Criteria

### You've successfully implemented DevSecOps when:

✅ All commits are scanned for secrets
✅ Dependencies are scanned in every build
✅ SBOM is generated for every release
✅ Containers are scanned before deployment
✅ No critical vulnerabilities in production
✅ Security metrics are tracked
✅ Team is trained on secure coding
✅ Security is part of definition of done

---

**Remember: Security is a journey, not a destination. Start small, iterate, and improve continuously!**

**Current Maturity: Level 2 → Target: Level 3 (6 months)**
