# Pipeline Reusability - Complete Guide

## 🎯 The Problem

**Before**: Each project has a 500+ line `bitbucket-pipelines.yml` with duplicated logic:
- Copy-paste pipeline from another project
- Hard to maintain (changes must be replicated to all projects)
- Inconsistent practices across projects
- No single source of truth

**After**: Reusable templates with minimal project configuration:
- Single source of truth in `pipeline-templates/`
- Projects use <10 lines of configuration
- Updates propagate to all projects automatically
- Consistent, battle-tested patterns

## 📊 Reusability Comparison

### Approach 1: Copy-Paste (Old Way) ❌

```
my-app-1/
└── bitbucket-pipelines.yml  (500 lines, duplicated)

my-app-2/
└── bitbucket-pipelines.yml  (500 lines, duplicated)

my-app-3/
└── bitbucket-pipelines.yml  (500 lines, duplicated)
```

**Problems**:
- 3 projects = 1,500 lines of duplicated code
- Bug fix requires updating 3 files
- Inconsistencies creep in over time
- No governance or standards

### Approach 2: Reusable Template (New Way) ✅

```
pipeline-templates/
└── python-reusable-template.yml  (500 lines, DRY)

my-app-1/
└── bitbucket-pipelines.yml  (10 lines: "copy template + variables")

my-app-2/
└── bitbucket-pipelines.yml  (10 lines: "copy template + variables")

my-app-3/
└── bitbucket-pipelines.yml  (10 lines: "copy template + variables")
```

**Benefits**:
- 3 projects = 530 lines total (97% reduction in duplication)
- Bug fix updates 1 file, projects copy latest
- Consistent patterns enforced
- Governance through template

## 🛠️ Implementation Strategies

### Strategy 1: Direct Copy (Simplest)

**How it works**: Copy template file to project as `bitbucket-pipelines.yml`

```bash
# In your project
cp pipeline-templates/python-reusable-template.yml bitbucket-pipelines.yml

# Configure variables in Bitbucket UI
# Commit and push
```

**Pros**:
- ✅ Simple - just copy a file
- ✅ Works immediately
- ✅ No external dependencies
- ✅ Easy to customize if needed

**Cons**:
- ⚠️ Updates require re-copying file
- ⚠️ Can diverge from template over time

**Best for**: Teams starting with reusability, single-tenant projects

### Strategy 2: Central Template Repository (Enterprise)

**How it works**: Store templates in central repo, projects reference them

```yaml
# bitbucket-pipelines.yml in your project
!include git@bitbucket.org:yourorg/pipeline-templates.git/python-reusable-template.yml

# Override only what you need
pipelines:
  custom:
    deploy-to-qa:
      - step:
          name: Deploy to QA
          script:
            - ./deploy-qa.sh
```

**Pros**:
- ✅ Single source of truth
- ✅ Updates propagate automatically
- ✅ Governance and compliance
- ✅ Version control

**Cons**:
- ⚠️ Requires central repo setup
- ⚠️ Network dependency
- ⚠️ More complex

**Best for**: Large organizations, multi-team environments

### Strategy 3: Hybrid (Recommended)

**How it works**: Copy template but maintain sync mechanism

```bash
# Initial setup
cp pipeline-templates/python-reusable-template.yml bitbucket-pipelines.yml

# Check for updates monthly
diff bitbucket-pipelines.yml pipeline-templates/python-reusable-template.yml

# Merge updates as needed
```

**Pros**:
- ✅ Balance of simplicity and maintainability
- ✅ No external dependencies
- ✅ Can track template versions
- ✅ Easy to customize

**Cons**:
- ⚠️ Manual update check needed

**Best for**: Most teams and organizations

## 📦 What's Reusable?

### Fully Reusable (No Customization Needed)

These are identical across all projects:

1. **Pre-checks Step** ✅
   - Lockfile verification
   - Pre-commit hooks
   - Quick lint

2. **Matrix Test Steps** ✅
   - Python 3.9, 3.10, 3.11, 3.12
   - JUnit XML output
   - Coverage reports

3. **Quality Scan** ✅
   - SonarQube integration
   - Coverage thresholds

4. **Security Scan** ✅
   - Secrets, SCA, SAST
   - SBOM generation

5. **Docker Build & Sign** ✅
   - Multi-stage build
   - Trivy scan
   - Cosign signing

6. **Helm Package** ✅
   - Lint, package, push

7. **Deploy Steps** ✅
   - Dev, Staging, Production
   - Canary rollout

8. **Notification** ✅
   - Slack webhooks

### 🔌 Organizational Pipes - Eliminating Nested Duplication

The templates themselves use **organizational Bitbucket Pipes** to avoid duplicating tool installation and complex logic:

| Template Step | Uses Pipe | Eliminates |
|---------------|-----------|------------|
| Quality Scan | `quality-pipe:1.0.0` | SonarQube scanner installation/configuration |
| Security Scan | `security-pipe:1.0.0` | Installation of secrets scanner, SCA tools, SAST tools |
| Docker Build | `docker-pipe:1.0.0` | Docker build logic, Trivy installation/scan, registry push |
| Helm Package | `helm-pipe:1.0.0` | Helm lint/package/push logic |
| Deploy | `deploy-pipe:1.0.0` | Kubernetes deployment scripts |

**Two Levels of Reusability**:
1. **Projects reuse templates** (96% reduction in YAML duplication)
2. **Templates reuse pipes** (eliminates tool installation duplication within templates)

**Result**: Templates are DRY, projects are DRY, and the entire pipeline ecosystem is maintainable and consistent.

### Requires Customization (Project-Specific)

These vary by project:

1. **Bitbucket Variables** (Required)
   - `DOCKER_REGISTRY`, `DOCKER_REPOSITORY`
   - `HELM_REGISTRY`
   - `KUBECONFIG_DEV`, `KUBECONFIG_STAGING`, `KUBECONFIG_PRODUCTION`

2. **Helm Values Files** (Required)
   - `helm-values-dev.yaml`
   - `helm-values-staging.yaml`
   - `helm-values-production.yaml`

3. **Project Configuration** (Required)
   - `pyproject.toml` (Python)
   - `pom.xml` (Java Maven)
   - `package.json` (Node.js)
   - etc.

4. **Pre-commit Config** (Recommended)
   - `.pre-commit-config.yaml`

5. **Dockerfile** (Usually Reusable, Sometimes Custom)
   - Most projects use standard multi-stage
   - Some need custom build steps

## 🎨 Customization Levels

### Level 1: Zero Customization (Copy Template As-Is)

```yaml
# bitbucket-pipelines.yml
# Just copy python-reusable-template.yml

# Configure these via Bitbucket UI:
# DOCKER_REGISTRY, DOCKER_REPOSITORY, etc.
```

**Time to setup**: 5 minutes
**Suitable for**: 80% of projects

### Level 2: Variable Overrides

```yaml
# bitbucket-pipelines.yml
# Copy template, then override variables

pipelines:
  branches:
    main:
      - step:
          name: Override Coverage
          script:
            - export COVERAGE_THRESHOLD=90  # Override from 85
            - # Rest uses template defaults
```

**Time to setup**: 10 minutes
**Suitable for**: Projects with specific quality requirements

### Level 3: Step Customization

```yaml
# bitbucket-pipelines.yml
# Copy template, add custom steps

pipelines:
  branches:
    main:
      - step: *pre-checks
      - step: *unit-test

      # Custom step
      - step:
          name: Custom Integration Test
          script:
            - ./custom-integration-test.sh

      - step: *docker-build-sign
```

**Time to setup**: 20 minutes
**Suitable for**: Projects with unique requirements

### Level 4: Full Customization

```yaml
# bitbucket-pipelines.yml
# Use template as starting point, heavily customize

# Import reusable steps
definitions:
  steps:
    # ... from template ...

pipelines:
  # Completely custom pipeline flow
  branches:
    main:
      - step: Custom Flow
```

**Time to setup**: 1-2 hours
**Suitable for**: Complex projects with unique workflows

## 📈 Adoption Roadmap

### Phase 1: Create Templates (Week 1)
- ✅ Create reusable templates for each language
- ✅ Document usage
- ✅ Test in pilot project

### Phase 2: Pilot Projects (Week 2-3)
- Identify 2-3 pilot projects per language
- Migrate to reusable templates
- Gather feedback
- Refine templates

### Phase 3: Rollout (Week 4-8)
- Migrate 20% of projects
- Update documentation
- Provide training
- Monitor adoption

### Phase 4: Governance (Week 9+)
- Establish template update process
- Create review board for changes
- Track compliance metrics
- Continuous improvement

## 🔢 Metrics & KPIs

Track these to measure reusability success:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Template Adoption Rate** | 80% | Projects using templates / Total projects |
| **Lines of Duplicated Code** | <500 | Sum of all pipeline YAMLs |
| **Time to Setup New Project** | <15 min | Average time from repo create to first deploy |
| **Template Update Propagation** | <1 week | Time from template update to project adoption |
| **Pipeline Consistency Score** | >90% | Projects following standards / Total |
| **Maintenance Time Reduction** | 75% | Time spent on pipeline updates before/after |

## 🎯 Real-World Example

### Before Reusability

**Company with 50 Python microservices**:
- Each has ~500 line `bitbucket-pipelines.yml`
- Total: 25,000 lines of duplicated YAML
- Security vulnerability fix requires updating 50 files
- Takes 2 weeks to propagate changes
- 20% of projects lag behind (still vulnerable)

### After Reusability

**Same company with templates**:
- 1 template with 500 lines
- 50 projects with ~10 lines each = 500 lines
- Total: 1,000 lines (96% reduction)
- Security fix updates 1 template
- Projects update by copying new template
- Takes 2 days to propagate (10x faster)
- 95% compliance within 1 week

**ROI Calculation**:
- Time saved per update: 40 hours → 4 hours (90% reduction)
- Updates per year: 12
- Annual time savings: 432 hours
- Cost savings (at $100/hr): $43,200/year
- Plus: faster security response, better compliance

## 🔒 Security Benefits of Reusability

### Vulnerability Management

**Without Templates**:
- Trivy version outdated in 30 projects
- SBOM not generated in 15 projects
- Image signing missing in 40 projects

**With Templates**:
- Update template once
- All projects get latest security features
- Compliance guaranteed

### Example: Log4j Response

**Without Templates**:
- Manual update of 50 pipelines
- 2 weeks to complete
- 10 projects missed initially

**With Templates**:
- Update 1 template
- Teams notified to update
- 2 days to 90% coverage
- 100% coverage in 5 days

## 📚 Best Practices

### 1. Version Your Templates

```yaml
# python-reusable-template.yml
# Template Version: 2.1.0
# Last Updated: 2025-11-15
# Changelog: Added SBOM attachment, improved security scanning
```

### 2. Communicate Changes

```markdown
# Template Changelog

## v2.1.0 (2025-11-15)
### Added
- SBOM attachment with Cosign
- Canary deployment strategy

### Changed
- Updated Trivy to v0.48.0
- Increased coverage threshold to 85%

### Migration Guide
- No breaking changes
- Copy new template to get improvements
```

### 3. Provide Migration Paths

```bash
# scripts/update-to-template-v2.sh
#!/bin/bash

# Backup current pipeline
cp bitbucket-pipelines.yml bitbucket-pipelines.yml.backup

# Copy new template
cp pipeline-templates/python-reusable-template.yml bitbucket-pipelines.yml

# Remind about variables
echo "✅ Template updated"
echo "⚠️  Remember to configure Bitbucket variables"
echo "📖 See MIGRATION.md for details"
```

### 4. Document Everything

- Template README
- Usage examples (minimal, customized)
- Migration guides
- Troubleshooting
- FAQ

## 🤝 Governance

### Template Change Process

1. **Propose Change**: Open GitHub/Bitbucket issue
2. **Review**: DevOps team reviews impact
3. **Test**: Test in pilot projects
4. **Approve**: Require 2 approvals
5. **Release**: Version bump, changelog
6. **Communicate**: Notify teams
7. **Monitor**: Track adoption

### Template Ownership

- **Maintainers**: DevOps team
- **Contributors**: Any developer
- **Reviewers**: Senior engineers
- **Approvers**: DevOps lead

## 📞 FAQ

**Q: What if my project needs something different?**
A: Start with template, add custom steps. Document why.

**Q: How do I get updates?**
A: Re-copy template file or use central repo with auto-updates.

**Q: Can I modify the template?**
A: Yes, but consider contributing back to central template.

**Q: What if the template breaks my build?**
A: Test in feature branch first. Keep backup. Report issues.

**Q: How often should I update?**
A: Check monthly for security updates, quarterly for features.

---

**Status**: Production-Ready ✅
**Adoption Target**: 80% by Q2 2025
**Maintained By**: DevOps Team
