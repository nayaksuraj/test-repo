# Production-Ready Python Pipeline

Battle-tested CI/CD pipeline for Python projects, based on best practices from **Instagram**, **Spotify**, and **Dropbox**.

## Key Features

✅ **Poetry/pip Support** - Modern dependency management
✅ **Multi-Python Versions** - Test against 3.9, 3.10, 3.11, 3.12
✅ **pytest Parallel** - Multi-threaded test execution with `-n auto`
✅ **Type Checking** - mypy strict mode enforcement
✅ **Code Quality** - ruff, pylint, black auto-formatting
✅ **Security Scanning** - Bandit, Safety, secrets detection
✅ **Docker Multi-stage** - Optimized Python images
✅ **Kubernetes Deployment** - Helm charts with rollback

## Pipeline Flow Diagram

```mermaid
graph TB
    Start([Git Commit/Push]) --> Branch{Branch Type?}

    Branch -->|feature/*| F1[poetry install<br/>or pip install]
    F1 --> F2[Ruff + Black<br/>Code Formatting]
    F2 --> F3[pytest<br/>+ Coverage 85%]
    F3 --> FEnd([End])

    Branch -->|develop| D1[poetry install<br/>--no-interaction]
    D1 --> D2{Parallel}
    D2 --> D3[Quality<br/>ruff + pylint + mypy]
    D2 --> D4[Security<br/>Bandit + Safety]
    D3 --> D5[Docker Build<br/>Python Slim]
    D4 --> D5
    D5 --> D6[Push to Registry]
    D6 --> D7[Deploy to Dev]
    D7 --> DEnd([Auto Deployed])

    Branch -->|main| M1[poetry install<br/>+ pytest -n auto]
    M1 --> M2{Parallel}
    M2 --> M3[Quality<br/>mypy --strict]
    M2 --> M4[Security<br/>Full Scan]
    M3 --> M5[Multi-Python Tests<br/>3.9, 3.10, 3.11, 3.12]
    M4 --> M5
    M5 --> M6[Docker Build & Scan<br/>Trivy + Grype]
    M6 --> M7[Helm Package]
    M7 --> M8{Manual Approval}
    M8 -->|Approved| M9[Deploy to Staging]
    M9 --> MEnd([Deployed to Staging])
    M8 -->|Rejected| MReject([Deployment Cancelled])

    Branch -->|v*| T1[poetry build<br/>Create Package]
    T1 --> T2{Parallel}
    T2 --> T3[Quality Gates]
    T2 --> T4[Security Audit]
    T3 --> T5[Production Build<br/>poetry export]
    T4 --> T5
    T5 --> T6[Docker Build<br/>Minimal Image]
    T6 --> T7[Tag Latest + Version]
    T7 --> T8{Manual Approval}
    T8 -->|Approved| T9[Deploy to Production]
    T9 --> T10[Health Check<br/>API Validation]
    T10 --> TEnd([Production Live])
    T8 -->|Rejected| TReject([Release Cancelled])

    style Start fill:#90EE90
    style DEnd fill:#87CEEB
    style MEnd fill:#FFA500
    style TEnd fill:#FF6347
    style FEnd fill:#D3D3D3
    style MReject fill:#FF0000
    style TReject fill:#FF0000

    style D2 fill:#FFE4B5
    style M2 fill:#FFE4B5
    style T2 fill:#FFE4B5
    style M8 fill:#FFD700
    style T8 fill:#FFD700
```

### Pipeline Stages Explained

| Stage | Description | Duration | Failure Impact |
|-------|-------------|----------|----------------|
| **Build & Test** | Poetry install + pytest (85% coverage) | ~2-4 min | ❌ Pipeline stops |
| **Quality Check** | ruff + pylint + mypy --strict | ~2-3 min | ❌ Pipeline stops |
| **Security Scan** | Bandit + Safety + secrets scan | ~2-3 min | ⚠️ Warning (develop), ❌ Fail (main/tags) |
| **Multi-Python Tests** | Test against 4 Python versions | ~8-15 min | ❌ Pipeline stops |
| **Docker Build** | Multi-stage Python slim image | ~3-5 min | ❌ Pipeline stops |
| **Helm Package** | Chart validation and packaging | ~1 min | ❌ Pipeline stops |
| **Deploy to Dev** | Auto-deploy to development | ~2-3 min | ⚠️ Warning only |
| **Deploy to Staging** | Manual approval required | ~3-5 min | ❌ Rollback triggered |
| **Deploy to Production** | Manual approval + health checks | ~10-15 min | ❌ Auto rollback |

### Poetry Cache Benefits

- **First build**: ~6-10 minutes
- **With cache**: ~1-2 minutes (80% faster)
- **Incremental**: ~15-30 seconds

### Testing Optimizations

- **pytest-xdist**: Parallel test execution (`-n auto`)
- **pytest-cov**: Fast coverage collection
- **Coverage threshold**: 85% enforced
- **Test isolation**: Each test runs independently

### Python-Specific Features

- **Virtual environments**: Isolated dependencies
- **Type hints**: Full mypy strict mode
- **Modern linting**: ruff (10-100x faster than flake8)
- **Auto-formatting**: black for consistent style

## Quick Start

```bash
# Copy this pipeline to your project
cp examples/python/bitbucket-pipelines.yml ./

# Install Poetry (recommended)
curl -sSL https://install.python-poetry.org | python3 -

# Configure pyproject.toml
# Configure Bitbucket variables
```

## References

- [Instagram Engineering](https://instagram-engineering.com/)
- [Spotify Engineering](https://engineering.atspotify.com/)
- [Dropbox Tech Blog](https://dropbox.tech/)
- [Python Packaging User Guide](https://packaging.python.org/)

---

**Based on patterns from Instagram, Spotify, and Dropbox** 🚀
