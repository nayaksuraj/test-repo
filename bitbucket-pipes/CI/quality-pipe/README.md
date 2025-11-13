# Quality Pipe

A comprehensive Bitbucket Pipe for code quality analysis across multiple programming languages. Includes SonarQube integration, linting, code coverage, and static analysis.

## Features

- **SonarQube/SonarCloud Integration**: Full support for Sonar analysis
- **Code Coverage**: Automatic coverage report generation and threshold checking
- **Linting**: ESLint, Pylint, Flake8, and more
- **Static Analysis**: Checkstyle, SpotBugs, PMD for Java
- **Multi-language Support**: Java, JavaScript, Python, Go, .NET
- **Coverage Threshold**: Fail builds based on coverage requirements
- **Flexible**: Custom quality commands supported

## Supported Languages & Tools

### Java
- Maven / Gradle
- JaCoCo (Coverage)
- Checkstyle
- SpotBugs
- PMD
- SonarQube

### JavaScript/TypeScript
- NPM / Yarn
- ESLint
- Prettier
- Jest Coverage
- SonarQube

### Python
- Pytest with coverage
- Pylint
- Flake8
- Mypy
- Black
- SonarQube

### Go
- Go test with coverage
- Golint
- SonarQube

### .NET
- dotnet test with coverage
- SonarQube

## Usage

### Basic Usage (Auto-detection with Coverage)

```yaml
pipelines:
  default:
    - step:
        name: Code Quality
        script:
          - pipe: nayaksuraj/quality-pipe:1.0.0
            variables:
              COVERAGE_ENABLED: 'true'
```

### SonarCloud Analysis

```yaml
pipelines:
  default:
    - step:
        name: SonarCloud Analysis
        script:
          - pipe: nayaksuraj/quality-pipe:1.0.0
            variables:
              SONAR_ENABLED: 'true'
              SONAR_TOKEN: $SONAR_TOKEN
              SONAR_PROJECT_KEY: 'my-project'
              SONAR_ORGANIZATION: 'my-org'
              COVERAGE_ENABLED: 'true'
```

### Self-hosted SonarQube

```yaml
pipelines:
  default:
    - step:
        name: SonarQube Analysis
        script:
          - pipe: nayaksuraj/quality-pipe:1.0.0
            variables:
              SONAR_ENABLED: 'true'
              SONAR_HOST_URL: 'https://sonar.mycompany.com'
              SONAR_TOKEN: $SONAR_TOKEN
              SONAR_PROJECT_KEY: 'my-project'
              COVERAGE_ENABLED: 'true'
```

### Java with Full Static Analysis

```yaml
pipelines:
  default:
    - step:
        name: Java Quality Checks
        script:
          - pipe: nayaksuraj/quality-pipe:1.0.0
            variables:
              COVERAGE_ENABLED: 'true'
              CHECKSTYLE_ENABLED: 'true'
              SPOTBUGS_ENABLED: 'true'
              PMD_ENABLED: 'true'
              COVERAGE_THRESHOLD: '80'
              FAIL_ON_LOW_COVERAGE: 'true'
```

### JavaScript/TypeScript with Linting

```yaml
pipelines:
  default:
    - step:
        name: JS Quality Checks
        script:
          - pipe: nayaksuraj/quality-pipe:1.0.0
            variables:
              LINT_ENABLED: 'true'
              COVERAGE_ENABLED: 'true'
              COVERAGE_THRESHOLD: '85'
```

### Python with Comprehensive Analysis

```yaml
pipelines:
  default:
    - step:
        name: Python Quality Checks
        script:
          - pipe: nayaksuraj/quality-pipe:1.0.0
            variables:
              LINT_ENABLED: 'true'
              COVERAGE_ENABLED: 'true'
              SONAR_ENABLED: 'true'
              SONAR_TOKEN: $SONAR_TOKEN
              SONAR_PROJECT_KEY: 'python-api'
              COVERAGE_THRESHOLD: '90'
```

### Coverage Enforcement

```yaml
pipelines:
  default:
    - step:
        name: Coverage Check
        script:
          - pipe: nayaksuraj/quality-pipe:1.0.0
            variables:
              COVERAGE_ENABLED: 'true'
              COVERAGE_THRESHOLD: '80'
              FAIL_ON_LOW_COVERAGE: 'true'
```

### Custom Quality Command

```yaml
pipelines:
  default:
    - step:
        name: Custom Quality
        script:
          - pipe: nayaksuraj/quality-pipe:1.0.0
            variables:
              QUALITY_COMMAND: 'make lint && make test-coverage'
```

### Multi-module Project

```yaml
pipelines:
  default:
    - parallel:
      - step:
          name: Backend Quality
          script:
            - pipe: nayaksuraj/quality-pipe:1.0.0
              variables:
                WORKING_DIR: 'backend'
                COVERAGE_ENABLED: 'true'
                SONAR_ENABLED: 'true'
                SONAR_TOKEN: $SONAR_TOKEN
                SONAR_PROJECT_KEY: 'backend'
      - step:
          name: Frontend Quality
          script:
            - pipe: nayaksuraj/quality-pipe:1.0.0
              variables:
                WORKING_DIR: 'frontend'
                LINT_ENABLED: 'true'
                COVERAGE_ENABLED: 'true'
                SONAR_PROJECT_KEY: 'frontend'
```

## Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `QUALITY_COMMAND` | Custom quality command to override auto-detection | No | - |
| `SONAR_ENABLED` | Enable SonarQube/SonarCloud analysis | No | false |
| `SONAR_TOKEN` | SonarQube authentication token | Conditional | - |
| `SONAR_HOST_URL` | SonarQube server URL | No | https://sonarcloud.io |
| `SONAR_PROJECT_KEY` | SonarQube project key | Conditional | - |
| `SONAR_ORGANIZATION` | SonarCloud organization | Conditional | - |
| `CHECKSTYLE_ENABLED` | Enable Checkstyle analysis for Java | No | false |
| `LINT_ENABLED` | Enable linting (ESLint, Pylint, etc.) | No | true |
| `COVERAGE_ENABLED` | Generate code coverage reports | No | true |
| `COVERAGE_THRESHOLD` | Minimum code coverage percentage required | No | 80 |
| `FAIL_ON_LOW_COVERAGE` | Fail pipeline if coverage is below threshold | No | false |
| `SPOTBUGS_ENABLED` | Enable SpotBugs analysis for Java | No | false |
| `PMD_ENABLED` | Enable PMD analysis for Java | No | false |
| `WORKING_DIR` | Working directory where analysis should be executed | No | . |
| `DEBUG` | Enable debug mode for verbose output | No | false |

## SonarQube Setup

### SonarCloud

1. Create account at https://sonarcloud.io
2. Create a new project
3. Generate authentication token
4. Add token to Bitbucket repository variables as `SONAR_TOKEN`

```yaml
- pipe: nayaksuraj/quality-pipe:1.0.0
  variables:
    SONAR_ENABLED: 'true'
    SONAR_TOKEN: $SONAR_TOKEN
    SONAR_PROJECT_KEY: 'my-org_my-project'
    SONAR_ORGANIZATION: 'my-org'
```

### Self-hosted SonarQube

```yaml
- pipe: nayaksuraj/quality-pipe:1.0.0
  variables:
    SONAR_ENABLED: 'true'
    SONAR_HOST_URL: 'https://sonar.company.com'
    SONAR_TOKEN: $SONAR_TOKEN
    SONAR_PROJECT_KEY: 'my-project'
```

## Coverage Reports

Coverage reports are generated in standard locations:

- **Maven**: `target/site/jacoco/index.html`
- **Gradle**: `build/reports/jacoco/test/html/index.html`
- **Python**: `htmlcov/index.html`
- **Go**: `coverage.html`
- **.NET**: `TestResults/*/coverage.cobertura.xml`

### Coverage Threshold

Set minimum coverage requirements:

```yaml
variables:
  COVERAGE_THRESHOLD: '85'
  FAIL_ON_LOW_COVERAGE: 'true'
```

The pipe will:
1. Generate coverage reports
2. Calculate coverage percentage
3. Compare against threshold
4. Fail build if below threshold (when `FAIL_ON_LOW_COVERAGE=true`)

## Static Analysis Tools

### Java

Enable multiple static analysis tools:

```yaml
variables:
  CHECKSTYLE_ENABLED: 'true'  # Code style checking
  SPOTBUGS_ENABLED: 'true'    # Bug pattern detection
  PMD_ENABLED: 'true'         # Code quality rules
```

**Note**: These plugins must be configured in your `pom.xml` or `build.gradle`.

### JavaScript/TypeScript

Linting is enabled by default if ESLint is configured:

```yaml
variables:
  LINT_ENABLED: 'true'
```

Ensure you have `.eslintrc.js` or `.eslintrc.json` in your project.

### Python

Multiple linters run automatically:

- **Pylint**: Comprehensive code analysis
- **Flake8**: Style guide enforcement
- **Mypy**: Static type checking (if configured)

```yaml
variables:
  LINT_ENABLED: 'true'
```

## Project Configuration

### Maven (pom.xml)

Add quality plugins to your `pom.xml`:

```xml
<build>
  <plugins>
    <!-- JaCoCo Coverage -->
    <plugin>
      <groupId>org.jacoco</groupId>
      <artifactId>jacoco-maven-plugin</artifactId>
      <version>0.8.11</version>
      <executions>
        <execution>
          <goals>
            <goal>prepare-agent</goal>
            <goal>report</goal>
          </goals>
        </execution>
      </executions>
    </plugin>

    <!-- Checkstyle -->
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-checkstyle-plugin</artifactId>
      <version>3.3.1</version>
    </plugin>

    <!-- SpotBugs -->
    <plugin>
      <groupId>com.github.spotbugs</groupId>
      <artifactId>spotbugs-maven-plugin</artifactId>
      <version>4.8.2.0</version>
    </plugin>
  </plugins>
</build>
```

### Gradle (build.gradle)

```groovy
plugins {
    id 'jacoco'
    id 'checkstyle'
    id 'com.github.spotbugs' version '5.2.3'
    id 'org.sonarqube' version '4.4.1.3373'
}

jacoco {
    toolVersion = "0.8.11"
}

sonarqube {
    properties {
        property "sonar.projectKey", "my-project"
    }
}
```

### JavaScript (package.json)

```json
{
  "scripts": {
    "test": "jest --coverage",
    "lint": "eslint src/**/*.{js,jsx,ts,tsx}"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "eslint": "^8.55.0"
  }
}
```

## Quality Gates

Combine with quality gates for production pipelines:

```yaml
pipelines:
  branches:
    main:
      - step:
          name: Quality Analysis
          script:
            - pipe: nayaksuraj/quality-pipe:1.0.0
              variables:
                SONAR_ENABLED: 'true'
                SONAR_TOKEN: $SONAR_TOKEN
                SONAR_PROJECT_KEY: 'production-app'
                COVERAGE_ENABLED: 'true'
                COVERAGE_THRESHOLD: '90'
                FAIL_ON_LOW_COVERAGE: 'true'
                CHECKSTYLE_ENABLED: 'true'
                SPOTBUGS_ENABLED: 'true'
```

## Troubleshooting

### SonarQube Analysis Fails

**Issue**: `ERROR: SONAR_TOKEN is required`

**Solution**: Add `SONAR_TOKEN` to repository variables

```yaml
variables:
  SONAR_TOKEN: $SONAR_TOKEN  # Reference secure variable
```

### Coverage Not Generated

**Issue**: No coverage reports found

**Solution**: Ensure coverage tools are configured:

**Maven**: Add JaCoCo plugin to `pom.xml`
**Gradle**: Enable `jacoco` plugin
**NPM**: Run tests with `--coverage` flag

### Checkstyle Not Running

**Issue**: Checkstyle skipped

**Solution**:
1. Add `maven-checkstyle-plugin` to `pom.xml`
2. Enable in pipe: `CHECKSTYLE_ENABLED: 'true'`

### Custom Project Structure

For non-standard project layouts:

```yaml
variables:
  WORKING_DIR: 'src/main/myapp'
  SONAR_ENABLED: 'true'
```

## Best Practices

1. **Always enable coverage** for production branches
2. **Use SonarQube** for comprehensive analysis
3. **Set coverage thresholds** appropriate for your project
4. **Enable static analysis** (Checkstyle, SpotBugs) for Java
5. **Run linting** on every commit
6. **Use quality gates** on main/production branches
7. **Fail builds** on quality issues in critical branches

## Integration Examples

### Pull Request Quality Check

```yaml
pipelines:
  pull-requests:
    '**':
      - step:
          name: PR Quality Check
          script:
            - pipe: nayaksuraj/quality-pipe:1.0.0
              variables:
                COVERAGE_ENABLED: 'true'
                LINT_ENABLED: 'true'
                SONAR_ENABLED: 'true'
                SONAR_TOKEN: $SONAR_TOKEN
                SONAR_PROJECT_KEY: 'myproject'
```

### Release Branch (Strict)

```yaml
pipelines:
  branches:
    release/*:
      - step:
          name: Release Quality (Strict)
          script:
            - pipe: nayaksuraj/quality-pipe:1.0.0
              variables:
                COVERAGE_ENABLED: 'true'
                COVERAGE_THRESHOLD: '95'
                FAIL_ON_LOW_COVERAGE: 'true'
                SONAR_ENABLED: 'true'
                CHECKSTYLE_ENABLED: 'true'
                SPOTBUGS_ENABLED: 'true'
                PMD_ENABLED: 'true'
```

## Support

For issues or questions:
- Repository: https://github.com/nayaksuraj/test-repo
- Bitbucket Pipes Documentation: https://support.atlassian.com/bitbucket-cloud/docs/pipes/

## License

MIT License
