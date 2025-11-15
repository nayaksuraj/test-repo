# Production-Ready PHP Pipeline

Battle-tested CI/CD pipeline for PHP projects (Laravel, Symfony, WordPress), based on best practices from **Laravel**, **Symfony**, and **WordPress.com**.

## Key Features

✅ **Composer Management** - Fast dependency resolution and caching
✅ **PHPUnit Parallel Tests** - Multi-threaded test execution
✅ **PHPStan/Psalm** - Static analysis at strictest levels
✅ **PHPCS/PHPCBF** - PSR-12 code standards enforcement
✅ **Laravel/Symfony Optimized** - Framework-specific caching
✅ **Security Scanning** - Composer audit, Trivy, secrets detection
✅ **Docker Multi-stage** - Optimized PHP-FPM images
✅ **Kubernetes Deployment** - Helm charts with rollback

## Required Configuration

### 1. composer.json

```json
{
    "name": "myorg/myapp",
    "description": "My PHP Application",
    "type": "project",
    "require": {
        "php": "^8.3",
        "laravel/framework": "^11.0"
    },
    "require-dev": {
        "phpunit/phpunit": "^11.0",
        "phpstan/phpstan": "^1.10",
        "vimeo/psalm": "^5.20",
        "squizlabs/php_codesniffer": "^3.8",
        "laravel/pint": "^1.13"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "Database\\": "database/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\": "tests/"
        }
    },
    "scripts": {
        "test": "phpunit",
        "test:coverage": "phpunit --coverage-html coverage",
        "phpstan": "phpstan analyse --level=8",
        "psalm": "psalm --show-info=true",
        "cs": "phpcs --standard=PSR12",
        "cs:fix": "phpcbf --standard=PSR12",
        "post-autoload-dump": [
            "@php artisan package:discover --ansi"
        ]
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true
    }
}
```

### 2. phpunit.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         executionOrder="random"
         stopOnFailure="false">
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory>tests/Feature</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory suffix=".php">app</directory>
        </include>
    </source>
    <coverage>
        <report>
            <clover outputFile="coverage.xml"/>
            <html outputDirectory="coverage"/>
        </report>
    </coverage>
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="CACHE_DRIVER" value="array"/>
        <env name="DB_CONNECTION" value="mysql"/>
        <env name="DB_DATABASE" value="test"/>
        <env name="MAIL_MAILER" value="array"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
    </php>
</phpunit>
```

### 3. phpstan.neon

```neon
parameters:
    level: 8
    paths:
        - app
    excludePaths:
        - app/Console/Kernel.php
        - app/Exceptions/Handler.php
    ignoreErrors:
        - '#Unsafe usage of new static#'
    checkMissingIterableValueType: false
    checkGenericClassInNonGenericObjectType: false
```

### 4. psalm.xml

```xml
<?xml version="1.0"?>
<psalm
    errorLevel="3"
    resolveFromConfigFile="true"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns="https://getpsalm.org/schema/config"
    xsi:schemaLocation="https://getpsalm.org/schema/config vendor/vimeo/psalm/config.xsd"
>
    <projectFiles>
        <directory name="app" />
        <ignoreFiles>
            <directory name="vendor" />
        </ignoreFiles>
    </projectFiles>
</psalm>
```

### 5. Dockerfile (Laravel with PHP-FPM + Nginx)

```dockerfile
# Build stage
FROM composer:2.6 AS builder

WORKDIR /app

# Copy composer files
COPY composer.json composer.lock ./

# Install dependencies
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-scripts \
    --optimize-autoloader \
    --classmap-authoritative

# Copy application
COPY . .

# Laravel optimizations
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Runtime stage - PHP-FPM
FROM php:8.3-fpm-alpine AS php-fpm

WORKDIR /var/www/html

# Install runtime dependencies
RUN apk add --no-cache \
    libpng \
    libjpeg-turbo \
    libzip \
    mysql-client \
    && docker-php-ext-install pdo_mysql gd zip opcache

# Configure OPcache
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=20000" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini

# Create non-root user
RUN addgroup -g 1001 appuser && adduser -D -u 1001 -G appuser appuser

# Copy application from builder
COPY --from=builder --chown=appuser:appuser /app /var/www/html

USER appuser

EXPOSE 9000

# Nginx stage
FROM nginx:alpine AS nginx

COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /app/public /var/www/html/public
```

### 6. nginx.conf

```nginx
server {
    listen 80;
    server_name _;
    root /var/www/html/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass php-fpm:9000;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

## Bitbucket Variables

Configure these in **Repository Settings → Pipelines → Repository Variables**:

```bash
# Docker Registry
DOCKER_REGISTRY=docker.io
DOCKER_REPOSITORY=myorg/myapp
DOCKER_USERNAME=your-username
DOCKER_PASSWORD=***         # Mark as secured

# Kubernetes
KUBECONFIG=***              # Base64 encoded, mark as secured

# Database (for tests)
DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=test
DB_USERNAME=test
DB_PASSWORD=test            # Mark as secured

# Laravel
APP_KEY=***                 # Generate with: php artisan key:generate --show
```

## Testing Best Practices

### PHPUnit Test Example

```php
<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use App\Services\UserService;

class UserServiceTest extends TestCase
{
    private UserService $userService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->userService = new UserService();
    }

    public function testGetUserReturnsUser(): void
    {
        $user = $this->userService->getUser(1);

        $this->assertNotNull($user);
        $this->assertEquals('John Doe', $user->name);
    }

    /**
     * @dataProvider invalidUserIdsProvider
     */
    public function testGetUserWithInvalidIdThrowsException(int $invalidId): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->userService->getUser($invalidId);
    }

    public function invalidUserIdsProvider(): array
    {
        return [
            [0],
            [-1],
            [-999],
        ];
    }
}
```

### Laravel Feature Test

```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User;

class UserControllerTest extends TestCase
{
    use RefreshDatabase;

    public function testUserCanRegister(): void
    {
        $response = $this->post('/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(302);
        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }

    public function testAuthenticatedUserCanViewProfile(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->get('/profile');

        $response->assertStatus(200);
        $response->assertSee($user->name);
    }
}
```

## Performance Optimization

### OPcache Configuration

Create `opcache.ini`:

```ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.save_comments=1
opcache.fast_shutdown=1
```

### Laravel Optimizations

```bash
# Cache configuration
php artisan config:cache

# Cache routes
php artisan route:cache

# Cache views
php artisan view:cache

# Optimize composer autoloader
composer dump-autoload --optimize --classmap-authoritative
```

### Parallel PHPUnit Tests

```bash
# Install ParaTest
composer require --dev brianium/paratest

# Run tests in parallel
vendor/bin/paratest --processes=4

# Laravel parallel tests
php artisan test --parallel --processes=4
```

## Code Quality

### Laravel Pint (Code Formatter)

```bash
# Install Pint
composer require laravel/pint --dev

# Run Pint
vendor/bin/pint

# Check without fixing
vendor/bin/pint --test
```

### PHPStan

```bash
# Run PHPStan at level 8
vendor/bin/phpstan analyse --level=8 app

# Generate baseline for existing issues
vendor/bin/phpstan analyse --level=8 --generate-baseline
```

### Psalm

```bash
# Run Psalm
vendor/bin/psalm

# Fix issues automatically (where possible)
vendor/bin/psalm --alter --issues=all
```

## Common Issues

### Composer Install Failing?

1. **Clear composer cache**:
   ```bash
   composer clear-cache
   composer install --no-cache
   ```

2. **Update composer**:
   ```bash
   composer self-update
   ```

3. **Check PHP version**:
   ```bash
   php -v
   # Should match composer.json requirement
   ```

### Tests Failing?

1. **Run with verbose output**:
   ```bash
   vendor/bin/phpunit --verbose
   ```

2. **Run specific test**:
   ```bash
   vendor/bin/phpunit --filter=testUserCanRegister
   ```

3. **Reset test database** (Laravel):
   ```bash
   php artisan migrate:fresh --env=testing
   php artisan db:seed --env=testing
   ```

### Memory Issues?

1. **Increase PHP memory limit**:
   ```ini
   memory_limit = 512M
   ```

2. **For PHPUnit**:
   ```bash
   php -d memory_limit=-1 vendor/bin/phpunit
   ```

## Laravel-Specific Features

### Database Migrations

```yaml
# Add to pipeline
- step:
    name: Database Migration
    script:
      - php artisan migrate --force
      - php artisan db:seed --force
```

### Queue Workers

```yaml
# config/horizon.yml (Laravel Horizon)
production:
  supervisor-1:
    connection: redis
    queue: [default, emails, notifications]
    balance: auto
    processes: 10
    tries: 3
    timeout: 300
```

### Task Scheduling

```php
// app/Console/Kernel.php
protected function schedule(Schedule $schedule)
{
    $schedule->command('emails:send')->everyFiveMinutes();
    $schedule->command('cache:prune-stale-tags')->hourly();
}
```

## Symfony-Specific Features

### Symfony Console

```bash
# Cache warmup
php bin/console cache:warmup --env=prod

# Clear cache
php bin/console cache:clear --env=prod
```

### Doctrine Migrations

```bash
# Run migrations
php bin/console doctrine:migrations:migrate --no-interaction
```

## Custom Pipelines

### Performance Testing

```bash
# Trigger from Bitbucket UI: Pipelines → Run pipeline → performance-test
# Uses Apache Bench for load testing
```

### Auto-fix Code Style

```bash
# Trigger from Bitbucket UI: Pipelines → Run pipeline → code-fix
# Automatically fixes PSR-12 violations
```

## References

- [Laravel Best Practices](https://github.com/alexeymezenin/laravel-best-practices)
- [Symfony Best Practices](https://symfony.com/doc/current/best_practices.html)
- [PHP The Right Way](https://phptherightway.com/)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)

---

**Based on patterns from Laravel, Symfony, and WordPress.com** 🚀
