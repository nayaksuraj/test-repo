# Production-Ready Go Pipeline

Battle-tested CI/CD pipeline for Go projects, based on best practices from **Google**, **Uber**, and **HashiCorp**.

## Key Features

✅ **Go Modules** - Modern dependency management
✅ **Race Detection** - Concurrent bug detection with `-race`
✅ **Benchmarks** - Performance regression testing
✅ **Code Quality** - golangci-lint with strict rules
✅ **Security Scanning** - gosec, govulncheck, secrets detection
✅ **Cross-Compilation** - Build for multiple OS/arch combinations
✅ **Minimal Docker Images** - Scratch/distroless (<10MB)
✅ **Kubernetes Deployment** - Helm charts with rollback

## Pipeline Flow Diagram

```mermaid
graph TB
    Start([Git Commit/Push]) --> Branch{Branch Type?}

    Branch -->|feature/*| F1[go mod download<br/>+ verify]
    F1 --> F2[gofmt + goimports<br/>Code Formatting]
    F2 --> F3[go test -race<br/>+ Coverage]
    F3 --> FEnd([End])

    Branch -->|develop| D1[go mod download<br/>Cache Dependencies]
    D1 --> D2{Parallel}
    D2 --> D3[Quality<br/>golangci-lint run]
    D2 --> D4[Security<br/>gosec + govulncheck]
    D3 --> D5[Docker Build<br/>Distroless Image]
    D4 --> D5
    D5 --> D6[Image Size: <10MB]
    D6 --> D7[Deploy to Dev]
    D7 --> DEnd([Auto Deployed])

    Branch -->|main| M1[go test -race<br/>-covermode=atomic]
    M1 --> M2{Parallel}
    M2 --> M3[Quality<br/>golangci-lint strict]
    M2 --> M4[Security<br/>Full Scan + SBOM]
    M3 --> M5[Benchmarks<br/>go test -bench]
    M4 --> M5
    M5 --> M6[Cross-Compile<br/>6 targets]
    M6 --> M7[Docker Build & Scan]
    M7 --> M8{Manual Approval}
    M8 -->|Approved| M9[Deploy to Staging]
    M9 --> MEnd([Deployed to Staging])
    M8 -->|Rejected| MReject([Deployment Cancelled])

    Branch -->|v*| T1[go build<br/>-ldflags version]
    T1 --> T2{Parallel}
    T2 --> T3[Quality Gates]
    T2 --> T4[Security Audit]
    T3 --> T5[Release Build<br/>Cross-platform]
    T4 --> T5
    T5 --> T6[Docker Multi-arch<br/>amd64 + arm64]
    T6 --> T7[Tag Latest + Version]
    T7 --> T8{Manual Approval}
    T8 -->|Approved| T9[Deploy to Production]
    T9 --> T10[Health Check<br/>Readiness Probes]
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
| **Build & Test** | go test with race detector + coverage | ~2-4 min | ❌ Pipeline stops |
| **Quality Check** | golangci-lint (40+ linters enabled) | ~2-3 min | ❌ Pipeline stops |
| **Security Scan** | gosec + govulncheck + secrets | ~2-3 min | ⚠️ Warning (develop), ❌ Fail (main/tags) |
| **Benchmarks** | go test -bench with comparison | ~3-5 min | ⚠️ Warning on regression |
| **Cross-Compilation** | 6 OS/arch combinations | ~4-6 min | ❌ Pipeline stops |
| **Docker Build** | Scratch/distroless image (<10MB) | ~2-4 min | ❌ Pipeline stops |
| **Deploy to Dev** | Auto-deploy to development | ~2-3 min | ⚠️ Warning only |
| **Deploy to Staging** | Manual approval required | ~3-5 min | ❌ Rollback triggered |
| **Deploy to Production** | Manual approval + health checks | ~10-15 min | ❌ Auto rollback |

### Go Module Cache Benefits

- **First build**: ~5-8 minutes
- **With cache**: ~1-2 minutes (75% faster)
- **Incremental**: ~10-20 seconds

### Cross-Compilation Targets

The pipeline builds for these platforms:

```bash
# Linux
GOOS=linux GOARCH=amd64
GOOS=linux GOARCH=arm64

# macOS
GOOS=darwin GOARCH=amd64
GOOS=darwin GOARCH=arm64

# Windows
GOOS=windows GOARCH=amd64
GOOS=windows GOARCH=arm64
```

### Binary Size Optimization

- **Standard build**: ~10-20MB
- **With ldflags**: ~8-15MB
- **Stripped**: ~6-12MB
- **UPX compressed**: ~2-5MB
- **Scratch container**: **<10MB total**

### Go-Specific Features

- **Race detector**: Finds concurrent bugs
- **Benchmarks**: Tracks performance regressions
- **Coverage**: Atomic mode for accurate reporting
- **Version injection**: Build version into binary
- **Static binaries**: No runtime dependencies

## Quick Start

```bash
# Copy this pipeline to your project
cp examples/golang/bitbucket-pipelines.yml ./

# Initialize Go modules
go mod init github.com/yourorg/yourapp
go mod tidy

# Configure Bitbucket variables
# - DOCKER_USERNAME, DOCKER_PASSWORD
# - KUBECONFIG (for Kubernetes)
```

## Example go.mod

```go
module github.com/yourorg/yourapp

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/stretchr/testify v1.8.4
)
```

## Example .golangci.yml

```yaml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - typecheck
    - unused
    - gofmt
    - goimports
    - misspell
    - gocritic
    - gosec

linters-settings:
  errcheck:
    check-type-assertions: true
  gocritic:
    enabled-tags:
      - diagnostic
      - experimental
      - opinionated
      - performance
      - style
```

## References

- [Google Go Style Guide](https://google.github.io/styleguide/go/)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
- [HashiCorp Engineering](https://www.hashicorp.com/blog/products/terraform)
- [Effective Go](https://go.dev/doc/effective_go)

---

**Based on patterns from Google, Uber, and HashiCorp** 🚀
