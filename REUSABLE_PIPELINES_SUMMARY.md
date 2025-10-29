# Reusable Bitbucket Pipelines - Quick Reference

## 🎯 What Was Created

You now have **3 different approaches** to create reusable pipeline components, similar to GitHub Composite Actions:

### 1. **Bitbucket Pipes** (Recommended for Production) 🏆
   - Docker-based reusable components
   - Official Bitbucket pattern
   - Clean, versioned syntax

### 2. **DevSecOps Toolbox** (Fastest Execution) ⚡
   - All-in-one Docker image with pre-installed tools
   - No tool installation time
   - Perfect for multiple applications

### 3. **Script Cloning** (Easiest to Start) 🚀
   - Git clone shared scripts
   - No Docker registry needed
   - Good for prototyping

---

## 📁 Files Created

### Documentation
- `REUSABLE_PIPELINES_GUIDE.md` - Complete guide to all approaches
- `PIPELINE_LIBRARY_SETUP.md` - Step-by-step setup instructions
- `REUSABLE_PIPELINES_SUMMARY.md` - This file (quick reference)

### Example Pipelines
- `bitbucket-pipelines-using-pipes.yml` - Using Bitbucket Pipes
- `bitbucket-pipelines-using-toolbox.yml` - Using Docker Toolbox

### Reusable Components (in `.pipeline-library/`)
```
.pipeline-library/
├── pipes/
│   └── secrets-scan/          # Example Bitbucket Pipe
│       ├── pipe.yml
│       ├── Dockerfile
│       ├── pipe.sh
│       ├── common.sh
│       └── README.md
├── docker/
│   └── devsecops-toolbox/     # All-in-one security tools image
│       ├── Dockerfile
│       ├── build-and-push.sh
│       └── README.md
└── README.md
```

---

## 🚀 Quick Start

### Choose Your Approach

#### Option 1: Bitbucket Pipes (Production)

**Setup:**
```bash
# 1. Create separate repository
git clone https://bitbucket.org/yourorg/bitbucket-pipeline-library.git

# 2. Copy .pipeline-library to new repo
cp -r .pipeline-library/* /path/to/bitbucket-pipeline-library/

# 3. Build and push pipe
cd bitbucket-pipeline-library/pipes/secrets-scan
docker build -t yourorg/secrets-scan-pipe:1.0.0 .
docker push yourorg/secrets-scan-pipe:1.0.0
```

**Usage in your app:**
```yaml
# bitbucket-pipelines.yml
pipelines:
  default:
    - pipe: docker://yourorg/secrets-scan-pipe:1.0.0
      variables:
        FAIL_ON_SECRETS: true
```

---

#### Option 2: DevSecOps Toolbox (Fastest)

**Setup:**
```bash
# Build toolbox
cd .pipeline-library/docker/devsecops-toolbox
docker build -t yourorg/devsecops-toolbox:1.0.0 .
docker push yourorg/devsecops-toolbox:1.0.0
```

**Usage in your app:**
```yaml
# bitbucket-pipelines.yml
image: yourorg/devsecops-toolbox:1.0.0

pipelines:
  default:
    - step:
        script:
          # Download shared scripts
          - git clone https://bitbucket.org/yourorg/bitbucket-pipeline-library.git /tmp/lib
          - cp -r /tmp/lib/scripts/* ./scripts/

          # All tools pre-installed!
          - ./scripts/security/security-secrets-scan.sh
          - ./scripts/security/security-sca-scan.sh
```

---

#### Option 3: Script Cloning (Easiest)

**Setup:**
```bash
# Create pipeline library repository
git clone https://bitbucket.org/yourorg/bitbucket-pipeline-library.git
cd bitbucket-pipeline-library

# Copy security scripts
mkdir -p scripts/security
cp /path/to/test-repo/scripts/security-*.sh scripts/security/

git add .
git commit -m "Add security scripts"
git push
```

**Usage in your app:**
```yaml
# bitbucket-pipelines.yml
pipelines:
  default:
    - step:
        name: Download Scripts
        script:
          - git clone https://bitbucket.org/yourorg/bitbucket-pipeline-library.git /tmp/lib
          - cp -r /tmp/lib/scripts/security ./scripts/
          - chmod +x scripts/security/*.sh
        artifacts:
          - scripts/**

    - step:
        name: Run Security Scans
        script:
          - ./scripts/security/security-secrets-scan.sh
```

---

## 📊 Comparison Table

| Feature | Pipes | Toolbox | Script Clone |
|---------|-------|---------|--------------|
| **Setup Time** | 2-3 hours | 1 hour | 15 minutes |
| **Pipeline Speed** | Fast | Fastest | Slow |
| **Bitbucket Native** | ✅ Yes | ❌ No | ❌ No |
| **Versioning** | Excellent | Good | Branch-based |
| **Tool Install Time** | Included | None | Every run |
| **Maintenance** | Easy | Easy | Manual |
| **Registry Required** | Yes | Yes | No |
| **Best For** | Production | Multiple apps | Quick start |
| **Recommended** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

---

## 🎬 Implementation Path

### Path A: Quick Start (Today)

1. Use **Script Cloning** approach
2. Create pipeline library repo
3. Copy security scripts
4. Update your `bitbucket-pipelines.yml`

**Time:** 30 minutes

### Path B: Recommended (This Week)

1. Create pipeline library repo
2. Build **DevSecOps Toolbox** image
3. Copy scripts to library
4. Update all app pipelines to use toolbox

**Time:** 2-3 hours

### Path C: Production-Ready (Next Sprint)

1. Complete Path B first
2. Create **Bitbucket Pipes** for each security scan
3. Build and publish pipes
4. Migrate apps to use pipes
5. Version and document

**Time:** 1 week

---

## 📚 What to Read Next

### Getting Started
1. Read: [PIPELINE_LIBRARY_SETUP.md](./PIPELINE_LIBRARY_SETUP.md)
2. Choose your approach
3. Follow setup steps
4. Test with one application
5. Roll out to all apps

### Advanced Topics
- [REUSABLE_PIPELINES_GUIDE.md](./REUSABLE_PIPELINES_GUIDE.md) - Complete guide
- `.pipeline-library/pipes/secrets-scan/README.md` - Pipe development
- `.pipeline-library/docker/devsecops-toolbox/README.md` - Toolbox details

### Examples
- [bitbucket-pipelines-using-pipes.yml](./bitbucket-pipelines-using-pipes.yml)
- [bitbucket-pipelines-using-toolbox.yml](./bitbucket-pipelines-using-toolbox.yml)

---

## 🔑 Key Benefits

### Before (Current State)
- ❌ Scripts duplicated across repositories
- ❌ Inconsistent security tool versions
- ❌ Hard to update (need to update every repo)
- ❌ No central maintenance
- ❌ Tools installed every pipeline run

### After (With Reusable Pipelines)
- ✅ Single source of truth
- ✅ Consistent tool versions
- ✅ Update once, apply everywhere
- ✅ Central maintenance
- ✅ Pre-installed tools (faster pipelines)
- ✅ Versioned components
- ✅ Easy to test before rollout

---

## 💡 Best Practices

1. **Version Everything**
   ```yaml
   # Good
   - pipe: docker://yourorg/secrets-scan-pipe:1.0.0

   # Avoid (use specific version)
   - pipe: docker://yourorg/secrets-scan-pipe:latest
   ```

2. **Test Before Publishing**
   ```bash
   # Always test locally first
   docker run --rm -v $(pwd):/workspace yourorg/secrets-scan-pipe:1.0.0
   ```

3. **Document Changes**
   ```bash
   # Maintain CHANGELOG.md
   # Tag releases
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push --tags
   ```

4. **Use Semantic Versioning**
   - `1.0.0` - Major version (breaking changes)
   - `1.1.0` - Minor version (new features)
   - `1.0.1` - Patch version (bug fixes)

---

## 🎯 Success Metrics

After implementing reusable pipelines, you should see:

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Pipeline setup time | 4 hours | 30 min | 87% faster |
| Tool installation time | 2-3 min | 0 min | 100% faster |
| Maintenance effort | High | Low | 70% reduction |
| Consistency | Variable | Uniform | 100% consistent |
| Version control | None | Full | ✅ New capability |

---

## 🔄 Migration Strategy

### Week 1: Setup
- [ ] Create pipeline library repository
- [ ] Build DevSecOps toolbox image
- [ ] Test with one non-critical app

### Week 2: Pilot
- [ ] Migrate 2-3 applications
- [ ] Gather feedback
- [ ] Fix issues

### Week 3-4: Rollout
- [ ] Create Bitbucket Pipes
- [ ] Migrate all applications
- [ ] Document for team

### Ongoing
- [ ] Monitor and maintain
- [ ] Update versions quarterly
- [ ] Add new components as needed

---

## 📞 Need Help?

### Common Questions

**Q: Which approach should I use?**
A: Start with Toolbox (fastest), migrate to Pipes (production-ready)

**Q: Do I need a private Docker registry?**
A: No, Docker Hub free tier works. Private registry recommended for enterprises.

**Q: Can I mix approaches?**
A: Yes! Use Pipes for security, Toolbox for complex builds, Scripts for simple tasks.

**Q: How do I update all applications?**
A: With Pipes/Toolbox: just change version number. With Scripts: automatic on next run.

### Getting Support

1. Check documentation in `.pipeline-library/`
2. Review example pipelines
3. Test locally with Docker
4. Ask your DevOps team

---

## 🎉 You're Ready!

You now have everything needed to create reusable pipeline components:

✅ Complete documentation
✅ Example Bitbucket Pipes
✅ DevSecOps Toolbox image
✅ Example pipelines
✅ Setup guide
✅ Migration strategy

**Choose your approach and get started today!** 🚀

---

**Quick Links:**
- [Complete Setup Guide](./PIPELINE_LIBRARY_SETUP.md)
- [Detailed Documentation](./REUSABLE_PIPELINES_GUIDE.md)
- [Pipe Example](./bitbucket-pipelines-using-pipes.yml)
- [Toolbox Example](./bitbucket-pipelines-using-toolbox.yml)
