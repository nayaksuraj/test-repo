# Test Pipe

A generic Bitbucket Pipe for running tests across multiple programming languages and frameworks. Auto-detects test tools and runs unit and integration tests with coverage support.

## Supported Frameworks

- **Java**: Maven, Gradle
- **JavaScript/TypeScript**: NPM, Yarn
- **Python**: Pytest
- **Go**: Go test
- **.NET**: dotnet test
- **PHP**: PHPUnit
- **Ruby**: RSpec
- **Rust**: Cargo

## Features

- **Auto-detection**: Automatically detects test framework based on project files
- **Unit & Integration Tests**: Run both unit and integration tests
- **Code Coverage**: Built-in support for coverage reporting
- **Docker Support**: TestContainers integration for integration tests
- **Multi-language**: Supports 8+ programming languages
- **Debug Mode**: Verbose output for troubleshooting
- **Flexible**: Override with custom test commands

## Usage

### Basic Usage (Auto-detection)

```yaml
pipelines:
  default:
    - step:
        name: Run Tests
        script:
          - pipe: nayaksuraj/test-pipe:1.0.0
```

### Maven Project

```yaml
pipelines:
  default:
    - step:
        name: Maven Tests
        script:
          - pipe: nayaksuraj/test-pipe:1.0.0
            variables:
              COVERAGE_ENABLED: 'true'
              TEST_ARGS: '-DskipIntegrationTests=false'
```

### Node.js Project

```yaml
pipelines:
  default:
    - step:
        name: NPM Tests
        script:
          - pipe: nayaksuraj/test-pipe:1.0.0
            variables:
              TEST_TOOL: 'npm'
              TEST_ARGS: '--verbose'
```

### Python Project with Coverage

```yaml
pipelines:
  default:
    - step:
        name: Pytest with Coverage
        script:
          - pipe: nayaksuraj/test-pipe:1.0.0
            variables:
              TEST_TOOL: 'pytest'
              COVERAGE_ENABLED: 'true'
              TEST_ARGS: '-v --tb=short'
```

### Go Project

```yaml
pipelines:
  default:
    - step:
        name: Go Tests
        script:
          - pipe: nayaksuraj/test-pipe:1.0.0
            variables:
              TEST_TOOL: 'go'
              COVERAGE_ENABLED: 'true'
```

### .NET Project

```yaml
pipelines:
  default:
    - step:
        name: .NET Tests
        script:
          - pipe: nayaksuraj/test-pipe:1.0.0
            variables:
              TEST_TOOL: 'dotnet'
              COVERAGE_ENABLED: 'true'
```

### Integration Tests with Docker

```yaml
pipelines:
  default:
    - step:
        name: Integration Tests
        services:
          - docker
        script:
          - pipe: nayaksuraj/test-pipe:1.0.0
            variables:
              INTEGRATION_TESTS: 'true'
              DOCKER_REQUIRED: 'true'
```

### Custom Test Command

```yaml
pipelines:
  default:
    - step:
        name: Custom Tests
        script:
          - pipe: nayaksuraj/test-pipe:1.0.0
            variables:
              TEST_COMMAND: 'make test'
              TEST_ARGS: 'verbose=true'
```

### Multi-module Project

```yaml
pipelines:
  default:
    - parallel:
      - step:
          name: Test Module 1
          script:
            - pipe: nayaksuraj/test-pipe:1.0.0
              variables:
                WORKING_DIR: 'module1'
      - step:
          name: Test Module 2
          script:
            - pipe: nayaksuraj/test-pipe:1.0.0
              variables:
                WORKING_DIR: 'module2'
```

## Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `TEST_COMMAND` | Custom test command to override auto-detection | No | - |
| `TEST_TOOL` | Specify test tool explicitly (maven, gradle, npm, pytest, go, dotnet, yarn) | No | Auto-detected |
| `TEST_ARGS` | Additional arguments to pass to the test command | No | '' |
| `INTEGRATION_TESTS` | Run integration tests in addition to unit tests (true/false) | No | false |
| `WORKING_DIR` | Working directory where tests should be executed | No | . |
| `SKIP_TESTS` | Skip test execution (useful for debugging) | No | false |
| `COVERAGE_ENABLED` | Enable code coverage collection (true/false) | No | false |
| `DOCKER_REQUIRED` | Docker is required for integration tests with TestContainers | No | false |
| `DEBUG` | Enable debug mode for verbose output (true/false) | No | false |

## Auto-detection Logic

The pipe auto-detects test frameworks based on these files:

- **Maven**: `pom.xml`
- **Gradle**: `build.gradle` or `build.gradle.kts`
- **NPM**: `package.json` (without `yarn.lock`)
- **Yarn**: `package.json` + `yarn.lock`
- **Pytest**: `setup.py`, `pyproject.toml`, or `pytest.ini`
- **Go**: `go.mod`
- **.NET**: `*.csproj` or `*.sln`
- **PHPUnit**: `composer.json` + `phpunit.xml`
- **RSpec**: `Gemfile`
- **Cargo**: `Cargo.toml`

## Test Reports

Test reports are generated in standard locations:

- **Maven**: `target/surefire-reports/`
- **Gradle**: `build/reports/tests/test/`
- **JaCoCo Coverage**: `target/site/jacoco/` or `build/reports/jacoco/`
- **Python Coverage**: `htmlcov/` and `coverage.xml`
- **Go Coverage**: `coverage.html`

## Integration Tests

For integration tests that require Docker (e.g., TestContainers):

1. Enable Docker service in your pipeline step
2. Set `INTEGRATION_TESTS: 'true'`
3. Set `DOCKER_REQUIRED: 'true'`

Example:

```yaml
- step:
    name: Integration Tests
    services:
      - docker
    script:
      - pipe: nayaksuraj/test-pipe:1.0.0
        variables:
          INTEGRATION_TESTS: 'true'
          DOCKER_REQUIRED: 'true'
```

## Troubleshooting

### Tests Not Detected

If auto-detection fails:

```yaml
variables:
  TEST_TOOL: 'maven'  # Specify explicitly
  DEBUG: 'true'       # Enable debug output
```

### Custom Test Location

If tests are in a subdirectory:

```yaml
variables:
  WORKING_DIR: 'backend'
```

### Integration Tests Failing

Ensure Docker is available:

```yaml
- step:
    services:
      - docker
    script:
      - pipe: nayaksuraj/test-pipe:1.0.0
        variables:
          DOCKER_REQUIRED: 'true'
```

## Examples by Language

### Java Spring Boot

```yaml
- pipe: nayaksuraj/test-pipe:1.0.0
  variables:
    COVERAGE_ENABLED: 'true'
    INTEGRATION_TESTS: 'true'
    DOCKER_REQUIRED: 'true'
```

### React Application

```yaml
- pipe: nayaksuraj/test-pipe:1.0.0
  variables:
    TEST_TOOL: 'npm'
    TEST_ARGS: '-- --coverage --watchAll=false'
```

### Python Flask API

```yaml
- pipe: nayaksuraj/test-pipe:1.0.0
  variables:
    TEST_TOOL: 'pytest'
    COVERAGE_ENABLED: 'true'
    TEST_ARGS: '-v --tb=short tests/'
```

### Go Microservice

```yaml
- pipe: nayaksuraj/test-pipe:1.0.0
  variables:
    TEST_TOOL: 'go'
    COVERAGE_ENABLED: 'true'
    TEST_ARGS: '-race -timeout 30s'
```

## Best Practices

1. **Always enable coverage** for production pipelines
2. **Run integration tests** on feature branches and main
3. **Use parallel steps** for multi-module projects
4. **Cache dependencies** to speed up builds
5. **Set timeouts** for long-running test suites

## Support

For issues or questions:
- Repository: https://github.com/nayaksuraj/test-repo
- Bitbucket Pipes Documentation: https://support.atlassian.com/bitbucket-cloud/docs/pipes/

## License

MIT License
