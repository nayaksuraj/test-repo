#!/bin/bash
# Common helper functions for Bitbucket Pipes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

fail() {
    error "$1"
    exit 1
}

debug() {
    if [ "${DEBUG}" = "true" ]; then
        echo -e "${BLUE}DEBUG:${NC} $1"
    fi
}

# Run command with logging
run() {
    debug "Running: $*"
    if [ "${DEBUG}" = "true" ]; then
        "$@"
    else
        "$@" 2>&1
    fi
}

# Validate required variable
require_var() {
    local var_name="$1"
    local var_value="${!var_name}"

    if [ -z "$var_value" ]; then
        fail "Required variable ${var_name} is not set"
    fi
}

# Export pipe metadata
export_metadata() {
    local key="$1"
    local value="$2"

    echo "${key}=${value}" >> "${BITBUCKET_PIPE_SHARED_STORAGE_DIR}/pipe.metadata" 2>/dev/null || true
}
