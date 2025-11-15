#!/bin/bash
# =============================================================================
# Lint Pipe - Pre-commit, Linting, Formatting, and Type Checking
# =============================================================================
# Multi-language linting and static analysis pipe
# =============================================================================

set -e
set -o pipefail

# =============================================================================
# Color Output
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Debug Mode
# =============================================================================
if [[ "${DEBUG}" == "true" ]]; then
    info "Debug mode enabled"
    set -x
fi

# =============================================================================
# Configuration
# =============================================================================
WORKING_DIR="${WORKING_DIR:-.}"
LANGUAGE="${LANGUAGE:-auto}"
PRE_COMMIT_ENABLED="${PRE_COMMIT_ENABLED:-true}"
PRE_COMMIT_CONFIG="${PRE_COMMIT_CONFIG:-.pre-commit-config.yaml}"
LOCKFILE_CHECK="${LOCKFILE_CHECK:-true}"
LINT_ENABLED="${LINT_ENABLED:-true}"
TYPE_CHECK_ENABLED="${TYPE_CHECK_ENABLED:-true}"
FORMAT_CHECK_ENABLED="${FORMAT_CHECK_ENABLED:-true}"
FAIL_ON_ERROR="${FAIL_ON_ERROR:-true}"

cd "${WORKING_DIR}" || exit 1

info "Lint Pipe v1.0.0"
info "Working Directory: ${WORKING_DIR}"
echo ""

# =============================================================================
# Auto-detect Language
# =============================================================================
detect_language() {
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        echo "python"
    elif [[ -f "package.json" ]]; then
        if grep -q "\"typescript\"" package.json 2>/dev/null; then
            echo "typescript"
        else
            echo "javascript"
        fi
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        echo "java"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "Gemfile" ]]; then
        echo "ruby"
    else
        echo "unknown"
    fi
}

if [[ "${LANGUAGE}" == "auto" ]]; then
    DETECTED_LANG=$(detect_language)
    info "Auto-detected language: ${DETECTED_LANG}"
    LANGUAGE="${DETECTED_LANG}"
else
    info "Using specified language: ${LANGUAGE}"
fi

# =============================================================================
# Install Pre-commit (if enabled)
# =============================================================================
if [[ "${PRE_COMMIT_ENABLED}" == "true" ]] && [[ -f "${PRE_COMMIT_CONFIG}" ]]; then
    info "Installing pre-commit..."
    pip install --quiet pre-commit || warning "Failed to install pre-commit"
fi

# =============================================================================
# Python Setup
# =============================================================================
setup_python() {
    info "Setting up Python environment..."

    # Install poetry if pyproject.toml exists
    if [[ -f "pyproject.toml" ]]; then
        info "Installing Poetry..."
        pip install --quiet --upgrade pip poetry

        # Configure poetry
        poetry config virtualenvs.in-project true

        # Install dependencies
        info "Installing dependencies with Poetry..."
        poetry install --no-interaction --quiet || warning "Poetry install failed"
    elif [[ -f "requirements.txt" ]]; then
        info "Installing dependencies from requirements.txt..."
        pip install --quiet -r requirements.txt
    fi
}

# =============================================================================
# Node.js Setup
# =============================================================================
setup_nodejs() {
    info "Setting up Node.js environment..."

    if [[ -f "package.json" ]]; then
        if [[ -f "package-lock.json" ]]; then
            info "Installing dependencies with npm..."
            npm ci --quiet || npm install --quiet
        elif [[ -f "yarn.lock" ]]; then
            info "Installing dependencies with yarn..."
            yarn install --frozen-lockfile --silent || yarn install --silent
        else
            info "Installing dependencies with npm..."
            npm install --quiet
        fi
    fi
}

# =============================================================================
# Setup Language Environment
# =============================================================================
case "${LANGUAGE}" in
    python)
        setup_python
        ;;
    javascript|typescript)
        setup_nodejs
        ;;
    go)
        info "Go modules detected"
        go mod download || warning "Failed to download Go modules"
        ;;
    *)
        info "No specific setup needed for ${LANGUAGE}"
        ;;
esac

echo ""

# =============================================================================
# Lockfile Integrity Check
# =============================================================================
if [[ "${LOCKFILE_CHECK}" == "true" ]]; then
    info "Checking lockfile integrity..."
    LOCKFILE_ERROR=0

    case "${LANGUAGE}" in
        python)
            if [[ -f "poetry.lock" ]]; then
                info "Checking poetry.lock..."
                poetry check || LOCKFILE_ERROR=1
                poetry lock --check || LOCKFILE_ERROR=1
                if [[ ${LOCKFILE_ERROR} -eq 0 ]]; then
                    success "Poetry lockfile is valid"
                else
                    error "Poetry lockfile is out of sync with pyproject.toml"
                    if [[ "${FAIL_ON_ERROR}" == "true" ]]; then
                        exit 1
                    fi
                fi
            fi
            ;;
        javascript|typescript)
            if [[ -f "package-lock.json" ]]; then
                info "Checking package-lock.json..."
                npm ci --dry-run || LOCKFILE_ERROR=1
                if [[ ${LOCKFILE_ERROR} -eq 0 ]]; then
                    success "npm lockfile is valid"
                else
                    warning "package-lock.json may be out of sync"
                fi
            fi
            ;;
        go)
            if [[ -f "go.sum" ]]; then
                info "Verifying go.sum..."
                go mod verify || LOCKFILE_ERROR=1
                if [[ ${LOCKFILE_ERROR} -eq 0 ]]; then
                    success "Go modules verified"
                else
                    error "go.sum verification failed"
                    if [[ "${FAIL_ON_ERROR}" == "true" ]]; then
                        exit 1
                    fi
                fi
            fi
            ;;
    esac
    echo ""
fi

# =============================================================================
# Pre-commit Hooks
# =============================================================================
if [[ "${PRE_COMMIT_ENABLED}" == "true" ]] && [[ -f "${PRE_COMMIT_CONFIG}" ]]; then
    info "Running pre-commit hooks..."

    if command -v pre-commit &> /dev/null; then
        # Install hooks
        pre-commit install --install-hooks || true

        # Run all hooks
        if pre-commit run --all-files; then
            success "Pre-commit hooks passed"
        else
            error "Pre-commit hooks failed"
            if [[ "${FAIL_ON_ERROR}" == "true" ]]; then
                exit 1
            fi
        fi
    else
        warning "pre-commit not available, skipping hooks"
    fi
    echo ""
fi

# =============================================================================
# Linting
# =============================================================================
if [[ "${LINT_ENABLED}" == "true" ]]; then
    info "Running linting checks..."
    LINT_ERROR=0

    if [[ -n "${LINT_COMMAND}" ]]; then
        info "Using custom lint command: ${LINT_COMMAND}"
        eval "${LINT_COMMAND}" || LINT_ERROR=1
    else
        case "${LANGUAGE}" in
            python)
                # Ruff linting
                if command -v ruff &> /dev/null || poetry run ruff --version &> /dev/null; then
                    info "Running ruff..."
                    if [[ -f "pyproject.toml" ]]; then
                        poetry run ruff check . --select=F,E,W,I,N,UP,B,A,C,S,T,SIM,RUF || LINT_ERROR=1
                    else
                        ruff check . || LINT_ERROR=1
                    fi
                fi

                # Pylint (if available)
                if command -v pylint &> /dev/null || poetry run pylint --version &> /dev/null; then
                    info "Running pylint..."
                    poetry run pylint src || true  # Don't fail on pylint
                fi
                ;;

            javascript)
                if [[ -f "package.json" ]] && grep -q "eslint" package.json; then
                    info "Running eslint..."
                    npm run lint || LINT_ERROR=1
                fi
                ;;

            typescript)
                if [[ -f "package.json" ]] && grep -q "eslint" package.json; then
                    info "Running eslint..."
                    npm run lint || LINT_ERROR=1
                fi
                ;;

            go)
                if command -v golangci-lint &> /dev/null; then
                    info "Running golangci-lint..."
                    golangci-lint run || LINT_ERROR=1
                else
                    info "Running go vet..."
                    go vet ./... || LINT_ERROR=1
                fi
                ;;

            java)
                info "Java linting typically handled by build tools"
                ;;

            *)
                warning "No default linter configured for ${LANGUAGE}"
                ;;
        esac
    fi

    if [[ ${LINT_ERROR} -eq 0 ]]; then
        success "Linting checks passed"
    else
        error "Linting checks failed"
        if [[ "${FAIL_ON_ERROR}" == "true" ]]; then
            exit 1
        fi
    fi
    echo ""
fi

# =============================================================================
# Format Checking
# =============================================================================
if [[ "${FORMAT_CHECK_ENABLED}" == "true" ]]; then
    info "Checking code formatting..."
    FORMAT_ERROR=0

    if [[ -n "${FORMAT_CHECK_COMMAND}" ]]; then
        info "Using custom format check command: ${FORMAT_CHECK_COMMAND}"
        eval "${FORMAT_CHECK_COMMAND}" || FORMAT_ERROR=1
    else
        case "${LANGUAGE}" in
            python)
                # Black formatting check
                if command -v black &> /dev/null || poetry run black --version &> /dev/null; then
                    info "Running black --check..."
                    if [[ -f "pyproject.toml" ]]; then
                        poetry run black --check . || FORMAT_ERROR=1
                    else
                        black --check . || FORMAT_ERROR=1
                    fi
                fi

                # isort import sorting
                if command -v isort &> /dev/null || poetry run isort --version &> /dev/null; then
                    info "Running isort --check..."
                    if [[ -f "pyproject.toml" ]]; then
                        poetry run isort --check . || FORMAT_ERROR=1
                    else
                        isort --check . || FORMAT_ERROR=1
                    fi
                fi
                ;;

            javascript|typescript)
                if [[ -f "package.json" ]] && grep -q "prettier" package.json; then
                    info "Running prettier --check..."
                    npm run format:check || npx prettier --check . || FORMAT_ERROR=1
                fi
                ;;

            go)
                info "Running gofmt..."
                UNFORMATTED=$(gofmt -l .)
                if [[ -n "${UNFORMATTED}" ]]; then
                    error "Unformatted files found:"
                    echo "${UNFORMATTED}"
                    FORMAT_ERROR=1
                fi
                ;;
        esac
    fi

    if [[ ${FORMAT_ERROR} -eq 0 ]]; then
        success "Format checks passed"
    else
        error "Format checks failed - code needs formatting"
        if [[ "${FAIL_ON_ERROR}" == "true" ]]; then
            exit 1
        fi
    fi
    echo ""
fi

# =============================================================================
# Type Checking
# =============================================================================
if [[ "${TYPE_CHECK_ENABLED}" == "true" ]]; then
    info "Running type checking..."
    TYPE_ERROR=0

    if [[ -n "${TYPE_CHECK_COMMAND}" ]]; then
        info "Using custom type check command: ${TYPE_CHECK_COMMAND}"
        eval "${TYPE_CHECK_COMMAND}" || TYPE_ERROR=1
    else
        case "${LANGUAGE}" in
            python)
                if command -v mypy &> /dev/null || poetry run mypy --version &> /dev/null; then
                    info "Running mypy..."
                    if [[ -f "pyproject.toml" ]]; then
                        poetry run mypy src ${MYPY_FLAGS:---strict} || TYPE_ERROR=1
                    else
                        mypy . || TYPE_ERROR=1
                    fi
                else
                    warning "mypy not installed, skipping type checking"
                fi
                ;;

            typescript)
                if [[ -f "tsconfig.json" ]]; then
                    info "Running tsc --noEmit..."
                    npx tsc --noEmit || TYPE_ERROR=1
                fi
                ;;

            go)
                info "Go has built-in type checking during compilation"
                go build ./... || TYPE_ERROR=1
                ;;

            *)
                warning "No default type checker configured for ${LANGUAGE}"
                ;;
        esac
    fi

    if [[ ${TYPE_ERROR} -eq 0 ]]; then
        success "Type checking passed"
    else
        error "Type checking failed"
        if [[ "${FAIL_ON_ERROR}" == "true" ]]; then
            exit 1
        fi
    fi
    echo ""
fi

# =============================================================================
# Summary
# =============================================================================
info "Lint Pipe Summary:"
echo "  Language: ${LANGUAGE}"
echo "  Pre-commit: ${PRE_COMMIT_ENABLED}"
echo "  Lockfile check: ${LOCKFILE_CHECK}"
echo "  Linting: ${LINT_ENABLED}"
echo "  Format check: ${FORMAT_CHECK_ENABLED}"
echo "  Type check: ${TYPE_CHECK_ENABLED}"
echo ""

success "Lint pipe completed successfully!"
