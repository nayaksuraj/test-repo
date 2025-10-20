#!/bin/bash

# ==============================================================================
# BITBUCKET PIPELINE SIMULATOR
# ==============================================================================
# This script simulates the Bitbucket pipeline execution locally
# It mimics the pipeline stages and runs them in the same order as Bitbucket
# ==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Pipeline configuration
SIMULATE_MODE=${SIMULATE_MODE:-true}  # Set to false to run actual commands
SKIP_DOCKER=${SKIP_DOCKER:-false}     # Skip Docker-related steps
SKIP_DEPLOY=${SKIP_DEPLOY:-true}      # Skip deployment steps by default
PIPELINE_TYPE=${PIPELINE_TYPE:-default}  # default, feature, develop, main, release, hotfix, tag, pr

# Track pipeline execution
TOTAL_STEPS=0
COMPLETED_STEPS=0
FAILED_STEPS=0
START_TIME=$(date +%s)

# ==============================================================================
# Helper Functions
# ==============================================================================

print_header() {
    echo -e "\n${BOLD}${BLUE}=========================================================================${NC}"
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BOLD}${BLUE}=========================================================================${NC}\n"
}

print_step() {
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
    echo -e "\n${BOLD}${PURPLE}[$TOTAL_STEPS] STEP: $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_substep() {
    echo -e "${YELLOW}  ▸ $1${NC}"
}

print_success() {
    COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_error() {
    FAILED_STEPS=$((FAILED_STEPS + 1))
    echo -e "${RED}  ✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}  ℹ $1${NC}"
}

run_command() {
    local cmd="$1"
    local description="$2"

    print_substep "$description"

    if [ "$SIMULATE_MODE" = "true" ]; then
        print_info "SIMULATING: $cmd"
        sleep 0.5  # Simulate execution time
        print_success "Simulated successfully"
        return 0
    else
        if eval "$cmd"; then
            print_success "$description completed"
            return 0
        else
            print_error "$description failed"
            return 1
        fi
    fi
}

execute_step() {
    local step_name="$1"
    local script_path="$2"
    local env_vars="$3"

    print_step "$step_name"

    # Check if script exists
    if [ ! -f "$script_path" ]; then
        print_error "Script not found: $script_path"
        return 1
    fi

    print_substep "Making script executable"
    chmod +x "$script_path"

    if [ "$SIMULATE_MODE" = "true" ]; then
        print_info "SIMULATING: $script_path"
        print_info "Environment: $env_vars"
        sleep 1  # Simulate execution time
        print_success "Step completed (simulated)"
        return 0
    else
        print_substep "Executing: $script_path"
        if [ -n "$env_vars" ]; then
            if eval "$env_vars $script_path"; then
                print_success "Step completed successfully"
                return 0
            else
                print_error "Step failed"
                return 1
            fi
        else
            if "$script_path"; then
                print_success "Step completed successfully"
                return 0
            else
                print_error "Step failed"
                return 1
            fi
        fi
    fi
}

run_parallel_steps() {
    local step_names=("$@")
    print_info "Running ${#step_names[@]} steps in PARALLEL"
    for step in "${step_names[@]}"; do
        print_info "  - $step"
    done
    echo ""
}

# ==============================================================================
# Pipeline Steps
# ==============================================================================

step_unit_tests() {
    execute_step "Unit Tests" "./scripts/test.sh" ""
}

step_integration_tests() {
    if [ "$SKIP_DOCKER" = "true" ]; then
        print_step "Integration Tests (SKIPPED - Docker disabled)"
        print_info "Set SKIP_DOCKER=false to run integration tests"
        return 0
    fi
    execute_step "Integration Tests" "./scripts/integration-test.sh" "DOCKER_REQUIRED=true"
}

step_code_quality() {
    execute_step "Code Quality & SonarQube" "./scripts/quality.sh" "SONAR_ENABLED=false"
}

step_build_package() {
    execute_step "Build and Package" "./scripts/build.sh" ""
    if [ $? -eq 0 ]; then
        execute_step "Package Application" "./scripts/package.sh" ""
    fi
}

step_docker_build_push() {
    if [ "$SKIP_DOCKER" = "true" ]; then
        print_step "Docker Build and Push (SKIPPED - Docker disabled)"
        print_info "Set SKIP_DOCKER=false to run Docker build"
        return 0
    fi
    execute_step "Docker Build and Push" "./scripts/docker-build.sh" "DOCKER_PUSH=false VERSION=0.0.1-SNAPSHOT"
}

step_docker_scan() {
    if [ "$SKIP_DOCKER" = "true" ]; then
        print_step "Docker Vulnerability Scan (SKIPPED - Docker disabled)"
        return 0
    fi
    execute_step "Docker Vulnerability Scan" "./scripts/docker-scan.sh" "TRIVY_EXIT_CODE=0 SCAN_TYPE=both"
}

step_helm_package() {
    execute_step "Helm Chart Package" "./scripts/helm-package.sh" "HELM_CHART_PATH=./helm-chart HELM_PUSH=false"
}

step_deploy_dev() {
    if [ "$SKIP_DEPLOY" = "true" ]; then
        print_step "Deploy to Development (SKIPPED)"
        print_info "Set SKIP_DEPLOY=false to run deployment"
        return 0
    fi
    execute_step "Deploy to Development" "./scripts/deploy-dev.sh" "NAMESPACE=dev"
}

step_deploy_stage() {
    if [ "$SKIP_DEPLOY" = "true" ]; then
        print_step "Deploy to Staging (SKIPPED - Manual Trigger)"
        return 0
    fi
    print_step "Deploy to Staging (MANUAL TRIGGER REQUIRED)"
    print_info "This step requires manual approval in Bitbucket"
}

step_deploy_prod() {
    if [ "$SKIP_DEPLOY" = "true" ]; then
        print_step "Deploy to Production (SKIPPED - Manual Trigger)"
        return 0
    fi
    print_step "Deploy to Production (MANUAL TRIGGER REQUIRED)"
    print_info "This step requires manual approval in Bitbucket"
}

# ==============================================================================
# Pipeline Workflows
# ==============================================================================

pipeline_default() {
    print_header "DEFAULT PIPELINE"
    step_unit_tests
    step_build_package
}

pipeline_feature() {
    print_header "FEATURE BRANCH PIPELINE (feature/**)"
    run_parallel_steps "Unit Tests" "Integration Tests" "Code Quality"
    step_unit_tests
    step_integration_tests
    step_code_quality
    step_build_package
}

pipeline_develop() {
    print_header "DEVELOP BRANCH PIPELINE"
    run_parallel_steps "Unit Tests" "Integration Tests" "Code Quality"
    step_unit_tests
    step_integration_tests
    step_code_quality
    step_build_package
    step_docker_build_push
    run_parallel_steps "Docker Vulnerability Scan" "Helm Package"
    step_docker_scan
    step_helm_package
    step_deploy_dev
}

pipeline_main() {
    print_header "MAIN BRANCH PIPELINE"
    run_parallel_steps "Unit Tests" "Integration Tests" "Code Quality"
    step_unit_tests
    step_integration_tests
    step_code_quality
    step_build_package
    step_docker_build_push
    run_parallel_steps "Docker Vulnerability Scan" "Helm Package"
    step_docker_scan
    step_helm_package
    step_deploy_dev
    step_deploy_stage
}

pipeline_release() {
    print_header "RELEASE BRANCH PIPELINE"
    run_parallel_steps "Unit Tests" "Integration Tests" "Code Quality"
    step_unit_tests
    step_integration_tests
    step_code_quality
    step_build_package
    step_docker_build_push
    run_parallel_steps "Docker Vulnerability Scan" "Helm Package"
    step_docker_scan
    step_helm_package
    step_deploy_dev
    step_deploy_stage
    step_deploy_prod
}

pipeline_hotfix() {
    print_header "HOTFIX BRANCH PIPELINE (hotfix/**)"
    run_parallel_steps "Unit Tests" "Integration Tests" "Code Quality"
    step_unit_tests
    step_integration_tests
    step_code_quality
    step_build_package
    step_docker_build_push
    run_parallel_steps "Docker Vulnerability Scan" "Helm Package"
    step_docker_scan
    step_helm_package
    step_deploy_dev
    step_deploy_stage
    step_deploy_prod
}

pipeline_tag() {
    print_header "TAG-BASED PIPELINE (v*)"
    run_parallel_steps "Unit Tests" "Integration Tests" "Code Quality"
    step_unit_tests
    step_integration_tests
    step_code_quality
    step_build_package
    step_docker_build_push
    run_parallel_steps "Docker Vulnerability Scan" "Helm Package"
    step_docker_scan
    step_helm_package
    step_deploy_prod
}

pipeline_pr() {
    print_header "PULL REQUEST PIPELINE"
    run_parallel_steps "Unit Tests" "Integration Tests" "Code Quality"
    step_unit_tests
    step_integration_tests
    step_code_quality
    step_build_package
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    echo -e "${BOLD}${GREEN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║              BITBUCKET PIPELINE SIMULATOR                                    ║
║              Local Testing for Bitbucket Pipelines                           ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    print_info "Pipeline Type: $PIPELINE_TYPE"
    print_info "Simulate Mode: $SIMULATE_MODE"
    print_info "Skip Docker: $SKIP_DOCKER"
    print_info "Skip Deploy: $SKIP_DEPLOY"
    print_info "Start Time: $(date)"

    # Ensure we're in the right directory
    cd "$(dirname "$0")"

    # Run the appropriate pipeline
    case "$PIPELINE_TYPE" in
        default)
            pipeline_default
            ;;
        feature)
            pipeline_feature
            ;;
        develop)
            pipeline_develop
            ;;
        main)
            pipeline_main
            ;;
        release)
            pipeline_release
            ;;
        hotfix)
            pipeline_hotfix
            ;;
        tag)
            pipeline_tag
            ;;
        pr)
            pipeline_pr
            ;;
        *)
            print_error "Unknown pipeline type: $PIPELINE_TYPE"
            echo "Valid types: default, feature, develop, main, release, hotfix, tag, pr"
            exit 1
            ;;
    esac

    # Print summary
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    print_header "PIPELINE EXECUTION SUMMARY"
    echo -e "${BOLD}Total Steps:     ${NC}$TOTAL_STEPS"
    echo -e "${GREEN}${BOLD}Completed Steps: ${NC}${GREEN}$COMPLETED_STEPS${NC}"

    if [ $FAILED_STEPS -gt 0 ]; then
        echo -e "${RED}${BOLD}Failed Steps:    ${NC}${RED}$FAILED_STEPS${NC}"
    else
        echo -e "${GREEN}${BOLD}Failed Steps:    ${NC}${GREEN}$FAILED_STEPS${NC}"
    fi

    echo -e "${BOLD}Duration:        ${NC}${DURATION}s"
    echo -e "${BOLD}End Time:        ${NC}$(date)"

    if [ $FAILED_STEPS -eq 0 ]; then
        echo -e "\n${GREEN}${BOLD}✓ Pipeline completed successfully!${NC}\n"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Pipeline failed with $FAILED_STEPS error(s)${NC}\n"
        exit 1
    fi
}

# ==============================================================================
# Usage Information
# ==============================================================================

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Bitbucket Pipeline Simulator"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  PIPELINE_TYPE     Pipeline type to simulate (default, feature, develop, main, release, hotfix, tag, pr)"
    echo "  SIMULATE_MODE     Run in simulation mode (true/false, default: true)"
    echo "  SKIP_DOCKER       Skip Docker-related steps (true/false, default: false)"
    echo "  SKIP_DEPLOY       Skip deployment steps (true/false, default: true)"
    echo ""
    echo "Examples:"
    echo "  # Simulate develop branch pipeline"
    echo "  PIPELINE_TYPE=develop ./simulate-pipeline.sh"
    echo ""
    echo "  # Run actual commands for feature branch"
    echo "  PIPELINE_TYPE=feature SIMULATE_MODE=false ./simulate-pipeline.sh"
    echo ""
    echo "  # Simulate main branch with Docker steps"
    echo "  PIPELINE_TYPE=main SKIP_DOCKER=false ./simulate-pipeline.sh"
    echo ""
    exit 0
fi

# Run the main function
main
