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

## Bitbucket Pipeline Configuration

The project includes a comprehensive Bitbucket Pipeline configuration that automates:

### Pipeline Features

1. **Default Pipeline** (all branches)
   - Build and test the application
   - Cache Maven dependencies for faster builds

2. **Main/Master Branch Pipeline**
   - Build and test
   - Code quality analysis
   - Deploy to staging environment

3. **Pull Request Pipeline**
   - Build and test
   - Code quality checks

4. **Tag Pipeline** (release-*)
   - Build and test
   - Code quality analysis
   - Manual deployment to production

5. **Custom Pipelines**
   - `build-only`: Quick build without tests
   - `full-build-deploy`: Complete pipeline with all deployments

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

Add environment variables in Bitbucket repository settings:
- Go to Repository Settings → Pipelines → Repository variables

### Deployment Configuration

Update the deployment steps in `bitbucket-pipelines.yml`:

```yaml
- step: &deploy-staging
    name: Deploy to Staging
    deployment: staging
    script:
      - # Add your deployment commands
```

### Adding More Steps

You can add additional steps like:
- Security scanning
- Code coverage reports
- Docker image building
- Database migrations

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
