# Spring Boot Demo Application

A simple Spring Boot application with Bitbucket Pipeline configuration.

## Project Overview

This is a basic Spring Boot web application built with Maven, featuring REST endpoints and automated CI/CD pipeline.

## Prerequisites

- Java 17 or higher
- Maven 3.8+
- Git

## Project Structure

```
.
├── src/
│   ├── main/
│   │   ├── java/com/example/demo/
│   │   │   └── DemoApplication.java
│   │   └── resources/
│   │       └── application.properties
│   └── test/
│       └── java/com/example/demo/
│           └── DemoApplicationTests.java
├── pom.xml
├── bitbucket-pipelines.yml
└── README.md
```

## Running the Application

### Build the project

```bash
mvn clean install
```

### Run the application

```bash
mvn spring-boot:run
```

The application will start on `http://localhost:8080`

### Available Endpoints

- `GET /` - Returns "Hello, Spring Boot!"
- `GET /health` - Returns "OK" (health check)

## Testing

Run tests with:

```bash
mvn test
```

## Reusable Bitbucket Pipeline Configuration

The project includes a **comprehensive and reusable** Bitbucket Pipeline configuration that can be used in ANY project!

### Key Features

- **Project-Agnostic**: Works with Maven, Gradle, npm, Python, Go, .NET, and more
- **Fully Parameterized**: Customize via environment variables
- **Multiple Workflows**: Automated pipelines for branches, tags, and pull requests
- **Security Scanning**: Optional security checks
- **Flexible Deployment**: Configure staging and production deployments
- **Manual Controls**: Custom pipelines for specific scenarios

### Quick Start for Reuse

To use this pipeline in your own project:

1. Copy `bitbucket-pipelines.yml` to your project
2. Update the Docker `image` to match your stack
3. Set build commands in Bitbucket Repository Variables
4. Push and watch it work!

**See [PIPELINE_REUSE_GUIDE.md](./PIPELINE_REUSE_GUIDE.md) for complete documentation.**

### Pipeline Features

1. **Default Pipeline** (all branches)
   - Build and test the application
   - Cache dependencies for faster builds

2. **Main/Master Branch Pipeline**
   - Build and test
   - Code quality analysis
   - Deploy to staging environment

3. **Pull Request Pipeline**
   - Build and test
   - Code quality checks

4. **Tag Pipeline** (release-*, v*)
   - Build and test
   - Code quality analysis
   - Security scanning
   - Manual deployment to production

5. **Custom Pipelines**
   - `build-only`: Quick build without tests
   - `quality-check`: Full quality analysis
   - `deploy-staging-only`: Deploy to staging
   - `full-pipeline`: Complete pipeline with all steps
   - `emergency-deploy`: Emergency production deployment

### Pipeline Steps

#### Build and Test
- Compiles the application
- Runs all unit tests
- Packages the application as a JAR file
- Stores the JAR as an artifact

#### Code Quality Analysis
- Runs Maven verify
- Can be extended with tools like SonarQube, Checkstyle, etc.

#### Deployment
- **Staging**: Automatic deployment for main/master branches
- **Production**: Manual trigger required for tagged releases

### Docker Image

The pipeline uses `maven:3.8.6-openjdk-17` Docker image, which includes:
- Maven 3.8.6
- OpenJDK 17
- All necessary build tools

### Caching

Maven dependencies are cached to improve build performance:
- `maven`: Built-in Bitbucket cache
- `maven-local`: Local Maven repository cache

## Customizing the Pipeline

### Adding Environment Variables

Configure your build in Bitbucket repository settings:
- Go to Repository Settings → Pipelines → Repository Variables

Set these variables to customize for your project:

| Variable | Description | Example |
|----------|-------------|---------|
| `BUILD_COMMAND` | Build command | `mvn clean compile` |
| `TEST_COMMAND` | Test command | `mvn test` |
| `PACKAGE_COMMAND` | Package command | `mvn package -DskipTests` |
| `DEPLOY_STAGING_SCRIPT` | Staging deployment | `scp target/*.jar user@server:/path/` |
| `DEPLOY_PRODUCTION_SCRIPT` | Production deployment | `kubectl apply -f deployment.yml` |

### Deployment Configuration

Configure deployment via repository variables:

```bash
# Example: Deploy to server via SCP
DEPLOY_STAGING_SCRIPT=scp target/*.jar user@staging-server:/app/

# Example: Deploy to Kubernetes
DEPLOY_PRODUCTION_SCRIPT=kubectl set image deployment/myapp myapp=registry/myapp:$BITBUCKET_COMMIT
```

### Reusing in Other Projects

This pipeline works with:
- Java (Maven, Gradle)
- Node.js (npm, yarn)
- Python (pip, pytest)
- .NET, Go, Ruby, PHP, and more!

**See [PIPELINE_REUSE_GUIDE.md](./PIPELINE_REUSE_GUIDE.md) for detailed examples and configurations.**

## Development

### Adding New Endpoints

Edit `src/main/java/com/example/demo/DemoApplication.java` and add new `@GetMapping` or `@PostMapping` methods.

### Configuration

Edit `src/main/resources/application.properties` to modify application settings.

## CI/CD Pipeline Triggers

- **Push to any branch**: Runs build and test
- **Push to main/master**: Runs build, test, quality checks, and deploys to staging
- **Create pull request**: Runs build, test, and quality checks
- **Create tag `release-*`**: Runs full pipeline with manual production deployment option
- **Manual trigger**: Custom pipelines can be run manually from Bitbucket UI

## License

This project is for demonstration purposes.
