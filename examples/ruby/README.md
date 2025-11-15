# Production-Ready Ruby Pipeline

Battle-tested CI/CD pipeline for Ruby and Rails projects, based on best practices from **GitHub**, **Shopify**, and **Basecamp**.

## Key Features

✅ **Bundler Management** - Fast dependency resolution and caching
✅ **RSpec Parallel Tests** - Multi-threaded test execution
✅ **SimpleCov Coverage** - 80% threshold enforced
✅ **RuboCop Linting** - Style guide enforcement with auto-fix
✅ **Brakeman Security** - Rails security scanning
✅ **Rails Optimizations** - Asset pipeline, database migrations
✅ **Docker Multi-stage** - Optimized Ruby images
✅ **Kubernetes Deployment** - Helm charts with rollback

## Pipeline Flow Diagram

```mermaid
graph TB
    Start([Git Commit/Push]) --> Branch{Branch Type?}

    Branch -->|feature/*| F1[bundle install<br/>--jobs=4]
    F1 --> F2[RuboCop Lint<br/>--parallel]
    F2 --> F3[RSpec Tests<br/>+ SimpleCov]
    F3 --> FEnd([End])

    Branch -->|develop| D1[bundle install<br/>+ DB setup]
    D1 --> D2{Parallel}
    D2 --> D3[RuboCop<br/>+ Brakeman]
    D2 --> D4[Security Scan<br/>bundle-audit]
    D3 --> D5[Docker Build<br/>Rails Assets]
    D4 --> D5
    D5 --> D6[Push to Registry]
    D6 --> D7[Deploy to Dev<br/>+ Migrations]
    D7 --> DEnd([Auto Deployed])

    Branch -->|main| M1[bundle install<br/>+ RSpec]
    M1 --> M2{Parallel}
    M2 --> M3[Quality<br/>RuboCop + Metrics]
    M2 --> M4[Security<br/>Brakeman + Audit]
    M3 --> M5[Integration Tests<br/>type:integration]
    M4 --> M5
    M5 --> M6[System Tests<br/>Capybara + Chrome]
    M6 --> M7[Docker Build & Scan]
    M7 --> M8{Manual Approval}
    M8 -->|Approved| M9[Deploy to Staging]
    M9 --> MEnd([Deployed to Staging])
    M8 -->|Rejected| MReject([Deployment Cancelled])

    Branch -->|v*| T1[bundle install<br/>--deployment]
    T1 --> T2{Parallel}
    T2 --> T3[Quality Gates]
    T2 --> T4[Security Audit]
    T3 --> T5[Assets Precompile<br/>RAILS_ENV=production]
    T4 --> T5
    T5 --> T6[Docker Build<br/>Production Bundle]
    T6 --> T7[Tag Latest + Version]
    T7 --> T8{Manual Approval}
    T8 -->|Approved| T9[Deploy to Production]
    T9 --> T10[Health Check<br/>+ Smoke Tests]
    T10 --> TEnd([Production Live])
    T8 -->|Rejected| TReject([Release Cancelled])

    style Start fill:#90EE90
    style DEnd fill:#87CEEB
    style MEnd fill:#FFA500
    style TEnd fill:#FF6347
    style FEnd fill:#D3D3D3
    style MReject fill:#FF0000
    style TReject fill:#FF0000

    style D2 fill:#FFE4B5
    style M2 fill:#FFE4B5
    style T2 fill:#FFE4B5
    style M8 fill:#FFD700
    style T8 fill:#FFD700
```

### Pipeline Stages Explained

| Stage | Description | Duration | Failure Impact |
|-------|-------------|----------|----------------|
| **Build & Test** | bundle install + RSpec with coverage | ~3-5 min | ❌ Pipeline stops |
| **Quality Check** | RuboCop (parallel) + RubyCritic | ~2-3 min | ❌ Pipeline stops |
| **Security Scan** | Brakeman + bundle-audit | ~2-3 min | ⚠️ Warning (develop), ❌ Fail (main/tags) |
| **Integration Tests** | RSpec integration suite | ~5-8 min | ❌ Pipeline stops |
| **System Tests** | Capybara with headless Chrome | ~8-12 min | ❌ Pipeline stops |
| **Docker Build** | Multi-stage Rails image | ~4-6 min | ❌ Pipeline stops |
| **Deploy to Dev** | Auto-deploy with migrations | ~3-5 min | ⚠️ Warning only |
| **Deploy to Staging** | Manual approval required | ~4-6 min | ❌ Rollback triggered |
| **Deploy to Production** | Manual approval + smoke tests | ~10-15 min | ❌ Auto rollback |

### Bundler Cache Benefits

- **First build**: ~8-12 minutes
- **With cache**: ~2-4 minutes (70% faster)
- **Incremental**: ~45-90 seconds

### Rails-Specific Optimizations

- **Bootsnap**: ~40% faster boot time
- **Parallel tests**: 4x speedup with 4 cores
- **Asset caching**: Reuse precompiled assets

## Required Configuration

### 1. Gemfile

```ruby
source 'https://rubygems.org'
ruby '3.3.0'

# Rails (if applicable)
gem 'rails', '~> 7.1.0'

# Database
gem 'pg', '~> 1.5'

# Application server
gem 'puma', '~> 6.4'

group :development, :test do
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'
  gem 'rubocop', '~> 1.59', require: false
  gem 'rubocop-rails', '~> 2.23', require: false
  gem 'rubocop-rspec', '~> 2.25', require: false
  gem 'brakeman', '~> 6.1', require: false
end

group :test do
  gem 'simplecov', '~> 0.22', require: false
  gem 'rspec-junit-formatter', '~> 0.6'
  gem 'capybara', '~> 3.39'
  gem 'selenium-webdriver', '~> 4.16'
end
```

### 2. .rspec

```
--require spec_helper
--format documentation
--color
--order random
```

### 3. spec/spec_helper.rb

```ruby
require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  minimum_coverage 80
  refuse_coverage_drop
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
```

### 4. .rubocop.yml

```yaml
require:
  - rubocop-rails
  - rubocop-rspec

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3
  Exclude:
    - 'db/schema.rb'
    - 'db/migrate/**/*'
    - 'vendor/**/*'
    - 'node_modules/**/*'

Style/Documentation:
  Enabled: false

Style/StringLiterals:
  Enabled: true
  EnforcedStyle: single_quotes

Layout/LineLength:
  Max: 120

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - 'config/routes.rb'

Metrics/MethodLength:
  Max: 15
```

### 5. Dockerfile (Rails)

```dockerfile
# Build stage
FROM ruby:3.3-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install bundler
RUN gem install bundler:2.5.3

# Copy Gemfile
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install --jobs=4 --retry=3

# Copy application
COPY . .

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=production

# Runtime stage
FROM ruby:3.3-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1001 appuser && chown -R appuser:appuser /app
USER appuser

# Copy gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application from builder
COPY --from=builder --chown=appuser:appuser /app /app

EXPOSE 3000

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server", "-b", "0.0.0.0"]
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
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/test

# RubyGems (for publishing gems)
RUBYGEMS_API_KEY=***        # Mark as secured
```

## Testing Best Practices

### RSpec Test Example

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
  end

  describe '#full_name' do
    it 'returns first and last name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe 'with factories' do
    it 'creates valid user' do
      user = create(:user)
      expect(user).to be_valid
    end
  end
end
```

### Factory Bot

Create `spec/factories/users.rb`:

```ruby
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { 'password123' }

    trait :admin do
      role { :admin }
    end

    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, user: user)
      end
    end
  end
end
```

### System Test (Rails)

```ruby
require 'rails_helper'

RSpec.describe 'User registration', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it 'allows user to register' do
    visit new_user_registration_path

    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'

    click_button 'Sign up'

    expect(page).to have_content('Welcome!')
  end
end
```

## Performance Optimization

### Parallel Tests

```bash
# Install parallel_tests gem
gem install parallel_tests

# Run tests in parallel
bundle exec parallel_rspec spec/

# With 4 processes
bundle exec parallel_rspec -n 4 spec/
```

### Bootsnap (Rails)

Add to Gemfile:

```ruby
gem 'bootsnap', require: false
```

Configure in `config/boot.rb`:

```ruby
require 'bootsnap/setup'
```

### Database Cleaner

```ruby
# spec/support/database_cleaner.rb
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :feature) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

## Code Quality

### RuboCop Auto-Correct

```bash
# Auto-fix safe corrections
bundle exec rubocop --auto-correct

# Auto-fix all corrections (use with caution)
bundle exec rubocop --auto-correct-all

# Generate TODO file for existing violations
bundle exec rubocop --auto-gen-config
```

### Brakeman Security Scan

```bash
# Install brakeman
gem install brakeman

# Run scan
brakeman

# Generate HTML report
brakeman -o brakeman-report.html

# Exit with error on warnings
brakeman --exit-on-warn
```

## Common Issues

### Bundle Install Failing?

1. **Clear bundler cache**:
   ```bash
   bundle clean --force
   rm -rf vendor/bundle
   bundle install
   ```

2. **Update bundler**:
   ```bash
   gem install bundler
   bundle update --bundler
   ```

3. **Check Ruby version**:
   ```bash
   ruby -v
   # Should match .ruby-version or Gemfile
   ```

### Tests Failing?

1. **Run with verbose output**:
   ```bash
   bundle exec rspec --format documentation
   ```

2. **Run specific test**:
   ```bash
   bundle exec rspec spec/models/user_spec.rb:10
   ```

3. **Reset test database**:
   ```bash
   RAILS_ENV=test bundle exec rake db:drop db:create db:schema:load
   ```

### Coverage Too Low?

1. **View coverage report**:
   ```bash
   open coverage/index.html
   ```

2. **Exclude files from coverage**:
   ```ruby
   SimpleCov.start 'rails' do
     add_filter '/spec/'
     add_filter '/config/'
     add_filter '/lib/tasks/'
   end
   ```

## Rails-Specific Features

### Database Migrations

```yaml
# Add to pipeline
- step:
    name: Database Migration
    script:
      - bundle exec rake db:migrate RAILS_ENV=production
      - bundle exec rake db:seed RAILS_ENV=production
```

### Asset Precompilation

```bash
# Precompile assets
bundle exec rake assets:precompile RAILS_ENV=production

# Clean old assets
bundle exec rake assets:clean
```

### Background Jobs

```ruby
# Gemfile
gem 'sidekiq', '~> 7.2'

# config/sidekiq.yml
production:
  :concurrency: 5
  :queues:
    - default
    - mailers
    - critical
```

## Custom Pipelines

### Performance Testing

```bash
# Trigger from Bitbucket UI: Pipelines → Run pipeline → performance-test
# Uses Siege for load testing
```

### Publish Gem

```bash
# Trigger from Bitbucket UI: Pipelines → Run pipeline → publish-gem
# Publishes to RubyGems.org
```

## References

- [GitHub Ruby Style Guide](https://github.com/github/rubocop-github)
- [Shopify Ruby Style Guide](https://ruby-style-guide.shopify.dev/)
- [RSpec Best Practices](https://rspec.info/documentation/)
- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)

---

**Based on patterns from GitHub, Shopify, and Basecamp** 🚀
