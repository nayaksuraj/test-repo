# Lint and Type Check Pipe

Language-agnostic pipe for running pre-commit hooks, linting, formatting checks, and static type checking across multiple programming languages.

## Features

- ✅ **Multi-language support**: Python, JavaScript, TypeScript, Go, Java, Rust, Ruby
- ✅ **Auto-detection**: Automatically detects project language
- ✅ **Pre-commit hooks**: Runs .pre-commit-config.yaml hooks
- ✅ **Lockfile validation**: Checks poetry.lock, package-lock.json, go.sum integrity
- ✅ **Linting**: Ruff, ESLint, golangci-lint, and more
- ✅ **Format checking**: Black, Prettier, gofmt
- ✅ **Type checking**: mypy, TypeScript, Go
- ✅ **On-demand installation**: Installs tools as needed
- ✅ **Customizable**: Override any check with custom commands

## Quick Start

### Basic Usage (Auto-detect)

```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    PRE_COMMIT_ENABLED: "true"
    LINT_ENABLED: "true"
    TYPE_CHECK_ENABLED: "true"
```

### Python Project

```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    LANGUAGE: "python"
    LOCKFILE_CHECK: "true"
    PRE_COMMIT_ENABLED: "true"
    LINT_ENABLED: "true"
    FORMAT_CHECK_ENABLED: "true"
    TYPE_CHECK_ENABLED: "true"
```

### JavaScript/TypeScript Project

```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    LANGUAGE: "typescript"
    LOCKFILE_CHECK: "true"
    LINT_ENABLED: "true"
    TYPE_CHECK_ENABLED: "true"
```

### Go Project

```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    LANGUAGE: "go"
    LOCKFILE_CHECK: "true"  # Verifies go.sum
    LINT_ENABLED: "true"     # Runs golangci-lint or go vet
    FORMAT_CHECK_ENABLED: "true"  # Checks gofmt
```

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LANGUAGE` | No | "auto" | Language (python, javascript, typescript, go, java, auto) |
| `PRE_COMMIT_ENABLED` | No | "true" | Run pre-commit hooks |
| `PRE_COMMIT_CONFIG` | No | ".pre-commit-config.yaml" | Path to pre-commit config |
| `LOCKFILE_CHECK` | No | "true" | Check lockfile integrity |
| `LINT_ENABLED` | No | "true" | Run linting checks |
| `LINT_COMMAND` | No | - | Custom lint command (overrides auto-detection) |
| `TYPE_CHECK_ENABLED` | No | "true" | Run type checking |
| `TYPE_CHECK_COMMAND` | No | - | Custom type check command |
| `FORMAT_CHECK_ENABLED` | No | "true" | Check code formatting |
| `FORMAT_CHECK_COMMAND` | No | - | Custom format check command |
| `FAIL_ON_ERROR` | No | "true" | Fail pipeline if errors found |
| `WORKING_DIR` | No | "." | Working directory |
| `DEBUG` | No | "false" | Enable debug output |

## Language-Specific Features

### Python

**Lockfile Check**:
- `poetry check` - Validates pyproject.toml
- `poetry lock --check` - Ensures lock is in sync

**Linting**:
- Ruff (primary): Fast Python linter
- Pylint (optional): Additional linting

**Format Checking**:
- Black: Code formatting
- isort: Import sorting

**Type Checking**:
- mypy: Static type checking with configurable strictness

**Example**:
```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    LANGUAGE: "python"
    TYPE_CHECK_COMMAND: "poetry run mypy src --strict --disallow-untyped-defs"
    LINT_COMMAND: "poetry run ruff check . --select=F,E,W,I,N,UP,B,A,C,S"
```

### JavaScript/TypeScript

**Lockfile Check**:
- `npm ci --dry-run` - Validates package-lock.json

**Linting**:
- ESLint (if configured in package.json)

**Format Checking**:
- Prettier (if configured)

**Type Checking**:
- `tsc --noEmit` for TypeScript projects

**Example**:
```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    LANGUAGE: "typescript"
    LINT_COMMAND: "npm run lint"
    FORMAT_CHECK_COMMAND: "npm run format:check"
```

### Go

**Lockfile Check**:
- `go mod verify` - Verifies go.sum

**Linting**:
- golangci-lint (if available)
- `go vet` (fallback)

**Format Checking**:
- `gofmt -l` - Lists unformatted files

**Type Checking**:
- `go build ./...` - Go's built-in type checking

**Example**:
```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    LANGUAGE: "go"
    LINT_COMMAND: "golangci-lint run --timeout 5m"
```

## Pre-commit Hooks Integration

If your project has a `.pre-commit-config.yaml` file, the pipe will automatically:

1. Install pre-commit
2. Install hooks
3. Run all hooks on all files

**Example .pre-commit-config.yaml**:
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/psf/black
    rev: 23.12.0
    hooks:
      - id: black

  - repo: https://github.com/charliermarsh/ruff-pre-commit
    rev: v0.1.8
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
```

## Custom Commands

Override any check with custom commands:

```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    LINT_COMMAND: "make lint"
    TYPE_CHECK_COMMAND: "make typecheck"
    FORMAT_CHECK_COMMAND: "make format-check"
```

## Integration Examples

### Python Project with Poetry

```yaml
definitions:
  steps:
    lint-check: &lint-check
      pipe: docker://nayaksuraj/lint-pipe:1.0.0
      variables:
        LANGUAGE: "python"
        PRE_COMMIT_ENABLED: "true"
        LOCKFILE_CHECK: "true"
        LINT_ENABLED: "true"
        FORMAT_CHECK_ENABLED: "true"
        TYPE_CHECK_ENABLED: "true"

pipelines:
  pull-requests:
    '**':
      - step: *lint-check

  branches:
    main:
      - step:
          <<: *lint-check
          variables:
            TYPE_CHECK_COMMAND: "poetry run mypy src --strict --disallow-untyped-defs"
            FAIL_ON_ERROR: "true"
```

### TypeScript Project

```yaml
pipelines:
  default:
    - pipe: docker://nayaksuraj/lint-pipe:1.0.0
      variables:
        LANGUAGE: "typescript"
        LINT_ENABLED: "true"
        TYPE_CHECK_ENABLED: "true"
        FORMAT_CHECK_ENABLED: "true"
```

### Multi-Language Monorepo

```yaml
pipelines:
  default:
    - parallel:
        - step:
            name: Lint Python
            script:
              - pipe: docker://nayaksuraj/lint-pipe:1.0.0
                variables:
                  LANGUAGE: "python"
                  WORKING_DIR: "./backend"

        - step:
            name: Lint TypeScript
            script:
              - pipe: docker://nayaksuraj/lint-pipe:1.0.0
                variables:
                  LANGUAGE: "typescript"
                  WORKING_DIR: "./frontend"

        - step:
            name: Lint Go
            script:
              - pipe: docker://nayaksuraj/lint-pipe:1.0.0
                variables:
                  LANGUAGE: "go"
                  WORKING_DIR: "./services"
```

## Replacing Manual Lint Steps

**Before (Manual)**:
```yaml
pre-checks:
  step:
    script:
      - pip install --upgrade pip poetry pre-commit
      - poetry check && poetry lock --check
      - pre-commit run --all-files
      - poetry install --no-interaction
      - poetry run ruff check .

type-check:
  step:
    script:
      - pip install --upgrade pip poetry
      - poetry install --no-interaction
      - poetry run mypy src --strict
```

**After (Using lint-pipe)**:
```yaml
lint-check:
  pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    LANGUAGE: "python"
    PRE_COMMIT_ENABLED: "true"
    LOCKFILE_CHECK: "true"
    LINT_ENABLED: "true"
    TYPE_CHECK_ENABLED: "true"
```

## Error Handling

By default, the pipe fails if any check fails. To continue on errors:

```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    FAIL_ON_ERROR: "false"  # Warnings only
```

## Selective Checks

Run only specific checks:

```yaml
# Only lockfile check
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    PRE_COMMIT_ENABLED: "false"
    LINT_ENABLED: "false"
    TYPE_CHECK_ENABLED: "false"
    FORMAT_CHECK_ENABLED: "false"
    LOCKFILE_CHECK: "true"

# Only type checking
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    PRE_COMMIT_ENABLED: "false"
    LINT_ENABLED: "false"
    FORMAT_CHECK_ENABLED: "false"
    LOCKFILE_CHECK: "false"
    TYPE_CHECK_ENABLED: "true"
```

## Debugging

Enable debug mode to see detailed execution:

```yaml
- pipe: docker://nayaksuraj/lint-pipe:1.0.0
  variables:
    DEBUG: "true"
```

## Performance Tips

1. **Cache dependencies**: Use Bitbucket caches for faster runs
   ```yaml
   caches: [poetry, pip, node, npm]
   ```

2. **Run checks in parallel**: Separate different checks
   ```yaml
   parallel:
     - pipe: lint-pipe (linting only)
     - pipe: lint-pipe (type checking only)
   ```

3. **Skip pre-commit in CI**: If using in development
   ```yaml
   PRE_COMMIT_ENABLED: "false"  # Already run locally
   ```

## Supported Languages

| Language | Lockfile | Linting | Format Check | Type Check |
|----------|----------|---------|--------------|------------|
| Python | ✅ poetry.lock | ✅ Ruff, Pylint | ✅ Black, isort | ✅ mypy |
| JavaScript | ✅ package-lock.json | ✅ ESLint | ✅ Prettier | ⚠️ N/A |
| TypeScript | ✅ package-lock.json | ✅ ESLint | ✅ Prettier | ✅ tsc |
| Go | ✅ go.sum | ✅ golangci-lint, go vet | ✅ gofmt | ✅ go build |
| Java | ⚠️ N/A | ⚠️ Build tools | ⚠️ Build tools | ⚠️ javac |
| Rust | ⚠️ Cargo.lock | ⚠️ clippy | ⚠️ rustfmt | ⚠️ cargo check |

Legend: ✅ Fully supported | ⚠️ Partial/planned support

## Building the Pipe

```bash
cd bitbucket-pipes/lint-pipe
docker build -t nayaksuraj/lint-pipe:1.0.0 .
docker push nayaksuraj/lint-pipe:1.0.0
```

## License

MIT License - See repository root for details.

## Support

For issues, feature requests, or contributions:
- Repository: https://github.com/nayaksuraj/test-repo
- Issues: https://github.com/nayaksuraj/test-repo/issues
