# Bitbucket Pipeline Simulator

A local testing tool for simulating Bitbucket Pipeline execution without actually pushing to Bitbucket.

## Quick Start

```bash
# Simulate the develop branch pipeline
./simulate-pipeline.sh

# Or specify the pipeline type
PIPELINE_TYPE=develop ./simulate-pipeline.sh
```

## Pipeline Types

The simulator supports all the pipeline types configured in `bitbucket-pipelines.yml`:

### 1. Default Pipeline
```bash
PIPELINE_TYPE=default ./simulate-pipeline.sh
```
**Steps:**
- Unit Tests
- Build and Package

### 2. Feature Branch Pipeline (`feature/**`)
```bash
PIPELINE_TYPE=feature ./simulate-pipeline.sh
```
**Steps:**
- Unit Tests (parallel)
- Integration Tests (parallel)
- Code Quality (parallel)
- Build and Package

### 3. Develop Branch Pipeline
```bash
PIPELINE_TYPE=develop ./simulate-pipeline.sh
```
**Steps:**
- Unit Tests (parallel)
- Integration Tests (parallel)
- Code Quality (parallel)
- Build and Package
- Docker Build and Push
- Docker Vulnerability Scan (parallel)
- Helm Package (parallel)
- Deploy to Development

### 4. Main Branch Pipeline
```bash
PIPELINE_TYPE=main ./simulate-pipeline.sh
```
**Steps:**
- All tests and quality checks (parallel)
- Build and Package
- Docker Build and Push
- Docker Scan + Helm Package (parallel)
- Deploy to Development
- Deploy to Staging (manual trigger)

### 5. Release Branch Pipeline
```bash
PIPELINE_TYPE=release ./simulate-pipeline.sh
```
**Steps:**
- All tests and quality checks (parallel)
- Build and Package
- Docker Build and Push
- Docker Scan + Helm Package (parallel)
- Deploy to Development
- Deploy to Staging (manual trigger)
- Deploy to Production (manual trigger)

### 6. Hotfix Branch Pipeline (`hotfix/**`)
```bash
PIPELINE_TYPE=hotfix ./simulate-pipeline.sh
```
**Steps:**
- Same as release pipeline (fast-track for critical fixes)

### 7. Tag-Based Pipeline (`v*`)
```bash
PIPELINE_TYPE=tag ./simulate-pipeline.sh
```
**Steps:**
- All tests and quality checks (parallel)
- Build and Package
- Docker Build and Push
- Docker Scan + Helm Package (parallel)
- Deploy to Production

### 8. Pull Request Pipeline
```bash
PIPELINE_TYPE=pr ./simulate-pipeline.sh
```
**Steps:**
- Unit Tests (parallel)
- Integration Tests (parallel)
- Code Quality (parallel)
- Build and Package

## Configuration Options

### SIMULATE_MODE
Controls whether to actually run scripts or just simulate them.

```bash
# Simulation mode (default) - doesn't run actual commands
SIMULATE_MODE=true PIPELINE_TYPE=develop ./simulate-pipeline.sh

# Execution mode - runs actual scripts
SIMULATE_MODE=false PIPELINE_TYPE=develop ./simulate-pipeline.sh
```

### SKIP_DOCKER
Skip Docker-related steps (useful for environments without Docker).

```bash
# Skip Docker steps
SKIP_DOCKER=true PIPELINE_TYPE=develop ./simulate-pipeline.sh

# Include Docker steps (default)
SKIP_DOCKER=false PIPELINE_TYPE=develop ./simulate-pipeline.sh
```

### SKIP_DEPLOY
Skip deployment steps.

```bash
# Skip deployment (default for safety)
SKIP_DEPLOY=true PIPELINE_TYPE=develop ./simulate-pipeline.sh

# Run deployment steps
SKIP_DEPLOY=false PIPELINE_TYPE=develop ./simulate-pipeline.sh
```

## Common Use Cases

### 1. Quick Validation (No Docker)
Test your pipeline without Docker dependencies:
```bash
PIPELINE_TYPE=develop SKIP_DOCKER=true ./simulate-pipeline.sh
```

### 2. Full Local Test (With Docker)
Run the actual scripts with Docker:
```bash
PIPELINE_TYPE=develop SIMULATE_MODE=false ./simulate-pipeline.sh
```

### 3. Test Feature Branch Changes
Before pushing feature branch changes:
```bash
PIPELINE_TYPE=feature SIMULATE_MODE=false SKIP_DOCKER=true ./simulate-pipeline.sh
```

### 4. Test Release Pipeline
Simulate a release pipeline:
```bash
PIPELINE_TYPE=release ./simulate-pipeline.sh
```

### 5. Validate PR Before Creating
Test what the PR pipeline will run:
```bash
PIPELINE_TYPE=pr SIMULATE_MODE=false SKIP_DOCKER=true ./simulate-pipeline.sh
```

## Understanding the Output

### Color Coding
- **Blue** - Headers and section titles
- **Purple** - Step names
- **Cyan** - Information messages
- **Yellow** - Sub-steps being executed
- **Green** - Successful operations
- **Red** - Failed operations

### Pipeline Summary
At the end of each run, you'll see:
- Total steps executed
- Completed steps count
- Failed steps count
- Total duration
- Overall status

### Example Output
```
╔══════════════════════════════════════════════════════════════════════════════╗
║              BITBUCKET PIPELINE SIMULATOR                                    ║
╚══════════════════════════════════════════════════════════════════════════════╝

[1] STEP: Unit Tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ▸ Making script executable
  ℹ SIMULATING: ./scripts/test.sh
  ✓ Step completed (simulated)

PIPELINE EXECUTION SUMMARY
Total Steps:     9
Completed Steps: 8
Failed Steps:    0
Duration:        8s
✓ Pipeline completed successfully!
```

## Comparing with Bitbucket

### What's Similar
- Same step execution order
- Same environment variables
- Same scripts are called
- Parallel steps indicated

### What's Different
- Local execution (no Bitbucket environment)
- No artifact uploads to Bitbucket
- No actual deployments (unless SKIP_DEPLOY=false)
- Manual trigger steps are shown but not executed

## Troubleshooting

### Script Not Found
If you see "Script not found" errors, ensure you're running from the repository root:
```bash
cd /path/to/test-repo
./simulate-pipeline.sh
```

### Permission Denied
Make the simulator executable:
```bash
chmod +x simulate-pipeline.sh
```

### Docker Errors
If Docker steps fail, either:
1. Skip Docker steps: `SKIP_DOCKER=true`
2. Ensure Docker is running: `docker ps`

### Maven/Build Errors
When running in execution mode (`SIMULATE_MODE=false`), ensure:
- Maven is installed: `mvn --version`
- Java 17 is available: `java -version`
- Dependencies are available

## Integration with CI/CD

You can use this simulator in your local development workflow:

1. **Before committing**: Run feature pipeline
   ```bash
   PIPELINE_TYPE=feature SIMULATE_MODE=false ./simulate-pipeline.sh
   ```

2. **Before creating PR**: Run PR pipeline
   ```bash
   PIPELINE_TYPE=pr SIMULATE_MODE=false ./simulate-pipeline.sh
   ```

3. **Before merging to develop**: Run develop pipeline
   ```bash
   PIPELINE_TYPE=develop SIMULATE_MODE=false SKIP_DEPLOY=true ./simulate-pipeline.sh
   ```

## Help

View help information:
```bash
./simulate-pipeline.sh --help
```

## Related Documentation

- [bitbucket-pipelines.yml](./bitbucket-pipelines.yml) - Actual Bitbucket pipeline configuration
- [PIPELINE_VARIABLES.md](./PIPELINE_VARIABLES.md) - Pipeline variables documentation
- [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md) - CI/CD setup guide
- [scripts/README.md](./scripts/README.md) - Script documentation
