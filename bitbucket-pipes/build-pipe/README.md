# Build Pipe

Generic build pipe that automatically detects and builds applications for multiple languages and frameworks.

## Supported Build Tools

- ✅ Maven (Java)
- ✅ Gradle (Java/Kotlin)
- ✅ npm (Node.js)
- ✅ Python (setup.py, pip)
- ✅ Go
- ✅ .NET
- ✅ Rust (Cargo)
- ✅ Ruby (Bundler)

## Usage

### Basic Usage (Auto-detection)

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
```

### With Custom Build Command

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_COMMAND: "mvn clean compile"
    BUILD_ARGS: "-DskipTests"
```

### Force Specific Build Tool

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_TOOL: "maven"
    BUILD_ARGS: "-Dmaven.test.skip=true"
```

## Variables

| Variable | Description | Required | Default | Example |
|----------|-------------|----------|---------|---------|
| `BUILD_COMMAND` | Custom build command | No | Auto-detected | `mvn clean package` |
| `BUILD_TOOL` | Force specific build tool | No | Auto-detected | `maven` |
| `BUILD_ARGS` | Additional build arguments | No | - | `-DskipTests` |
| `WORKING_DIR` | Working directory | No | `.` | `./backend` |
| `DEBUG` | Enable debug output | No | `false` | `true` |

## Examples

### Maven Project

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_ARGS: "-DskipTests -Dmaven.javadoc.skip=true"
```

### Node.js Project

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    BUILD_COMMAND: "npm ci && npm run build"
```

### Monorepo (specific directory)

```yaml
- pipe: docker://nayaksuraj/build-pipe:1.0.0
  variables:
    WORKING_DIR: "./services/api"
    BUILD_TOOL: "gradle"
```

## Building the Pipe

```bash
cd bitbucket-pipes/CI/build-pipe
docker build -t nayaksuraj/build-pipe:1.0.0 .
docker push nayaksuraj/build-pipe:1.0.0
```

## License

This pipe is part of the reusable Bitbucket Pipes collection.
