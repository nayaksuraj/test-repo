# Slack Notification Pipe

Send rich, formatted notifications to Slack from your Bitbucket Pipelines with deployment status, build information, and custom messages.

## Features

- ✅ Rich message formatting with blocks and attachments
- ✅ Automatic commit and build information
- ✅ Status-based color coding (success, warning, error, info)
- ✅ Custom fields and metadata
- ✅ User and channel mentions
- ✅ Thread replies support
- ✅ Action buttons (View Pipeline)
- ✅ Emoji and icon support
- ✅ Fully customizable

## Usage

### Basic Usage

```yaml
- step:
    name: Notify Slack
    script:
      - pipe: docker://nayaksuraj/slack-pipe:1.0.0
        variables:
          SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
          MESSAGE: "✅ Deployment to production completed"
          TITLE: "Production Deployment"
          ENVIRONMENT: "production"
```

### Complete Example

```yaml
- step:
    name: Notify Deployment
    script:
      - pipe: docker://nayaksuraj/slack-pipe:1.0.0
        variables:
          SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
          MESSAGE: "🚀 Application deployed successfully!"
          TITLE: "Production Release"
          STATUS: "success"
          ENVIRONMENT: "production"
          MENTION_CHANNEL: "channel"  # @channel
          CUSTOM_FIELDS: '{"Version":"1.2.3","Duration":"5m 23s","Replicas":"3"}'
          INCLUDE_COMMIT_INFO: "true"
          INCLUDE_BUILD_INFO: "true"
```

### Different Status Levels

```yaml
# Success notification (green)
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "✅ Build successful"
    STATUS: "success"

# Warning notification (yellow)
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "⚠️ Build passed with warnings"
    STATUS: "warning"

# Error notification (red)
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "❌ Build failed"
    STATUS: "error"

# Info notification (blue)
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "ℹ️ Starting deployment"
    STATUS: "info"
```

### Mention Users or Channels

```yaml
# Mention specific users
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "❌ Production deployment failed"
    STATUS: "error"
    MENTION_USERS: "U123456,U789012"  # Slack user IDs

# Mention @channel
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "🚀 Major release deployed"
    MENTION_CHANNEL: "channel"

# Mention @here
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "⚠️ Deployment requires approval"
    MENTION_CHANNEL: "here"
```

### Custom Fields

```yaml
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "Deployment metrics"
    CUSTOM_FIELDS: |
      {
        "Version": "v2.1.0",
        "Region": "us-east-1",
        "Duration": "3m 45s",
        "Instances": "5",
        "Health": "100%"
      }
```

### Thread Replies

Reply to an existing Slack message thread:

```yaml
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "Update: Migration completed"
    THREAD_TS: "1234567890.123456"  # Thread timestamp from original message
```

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SLACK_WEBHOOK_URL` | ✅ Yes | - | Slack incoming webhook URL (secured) |
| `MESSAGE` | No | "✅ Pipeline completed successfully" | Main notification message |
| `TITLE` | No | "Bitbucket Pipeline" | Notification title |
| `STATUS` | No | "success" | Status level: success, warning, error, info |
| `ENVIRONMENT` | No | - | Deployment environment (dev, staging, production) |
| `INCLUDE_COMMIT_INFO` | No | "true" | Include git commit information |
| `INCLUDE_BUILD_INFO` | No | "true" | Include build/pipeline information |
| `MENTION_USERS` | No | - | Slack user IDs to mention (comma-separated) |
| `MENTION_CHANNEL` | No | - | Mention @channel or @here |
| `CUSTOM_FIELDS` | No | - | Custom fields as JSON key-value pairs |
| `THREAD_TS` | No | - | Thread timestamp to reply to existing message |
| `NOTIFICATION_COLOR` | No | Auto (based on status) | Color for attachment (hex or success/warning/danger) |
| `DEBUG` | No | "false" | Enable debug output |

## Automatic Information Included

The pipe automatically includes the following information (if `INCLUDE_COMMIT_INFO` and `INCLUDE_BUILD_INFO` are enabled):

### Commit Information
- **Commit Hash**: Short commit SHA with link to Bitbucket
- **Branch**: Git branch name
- **Tag**: Git tag (if available)
- **Author**: Commit author name

### Build Information
- **Build Number**: Bitbucket build number
- **Repository**: Repository slug
- **View Pipeline Button**: Direct link to pipeline results

## Setting Up Slack Webhook

1. Go to your Slack workspace: https://api.slack.com/apps
2. Create a new app or select existing app
3. Enable "Incoming Webhooks"
4. Add a new webhook to your workspace
5. Select the channel for notifications
6. Copy the webhook URL
7. Add to Bitbucket repository variables as `SLACK_WEBHOOK_URL` (secured)

## Message Format

The pipe sends messages in Slack's Block Kit format with:

- **Header Block**: Title with status icon
- **Section Block**: Main message
- **Fields Block**: Structured information (commit, build, custom fields)
- **Actions Block**: Button to view pipeline (if build URL available)
- **Attachment**: Color-coded footer with timestamp

Example notification appearance:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Production Deployment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Application deployed successfully!

Commit: abc1234          Branch: main
Tag: v2.1.0              Author: John Doe
Build: #123              Repository: my-app
Environment: production  Version: v2.1.0

[View Pipeline]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Bitbucket Pipelines | just now
```

## Pipeline Integration Examples

### Deployment Success

```yaml
- step:
    name: Deploy to Production
    deployment: production
    script:
      - ./deploy.sh
    after-script:
      - pipe: docker://nayaksuraj/slack-pipe:1.0.0
        variables:
          SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
          MESSAGE: "🎉 Production deployment successful"
          TITLE: "Production Release"
          ENVIRONMENT: "production"
          STATUS: "success"
```

### Build Failure

```yaml
- step:
    name: Build Application
    script:
      - mvn clean package
    after-script:
      - |
        if [ $BITBUCKET_EXIT_CODE -ne 0 ]; then
          pipe docker://nayaksuraj/slack-pipe:1.0.0 \
            SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL \
            MESSAGE="❌ Build failed" \
            STATUS="error" \
            MENTION_CHANNEL="here"
        fi
```

### Multi-Environment Deployment

```yaml
pipelines:
  branches:
    develop:
      - step:
          name: Deploy to Dev
          script:
            - ./deploy.sh dev
      - step:
          name: Notify
          script:
            - pipe: docker://nayaksuraj/slack-pipe:1.0.0
              variables:
                SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
                MESSAGE: "✅ Deployed to Dev"
                ENVIRONMENT: "dev"
                STATUS: "success"

    main:
      - step:
          name: Deploy to Staging
          script:
            - ./deploy.sh staging
      - step:
          name: Notify
          script:
            - pipe: docker://nayaksuraj/slack-pipe:1.0.0
              variables:
                SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
                MESSAGE: "🚀 Deployed to Staging"
                ENVIRONMENT: "staging"
                STATUS: "success"
                MENTION_CHANNEL: "here"

  tags:
    'v*':
      - step:
          name: Deploy to Production
          script:
            - ./deploy.sh production
      - step:
          name: Notify
          script:
            - pipe: docker://nayaksuraj/slack-pipe:1.0.0
              variables:
                SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
                MESSAGE: "🎉 Production release ${BITBUCKET_TAG}"
                TITLE: "Production Deployment"
                ENVIRONMENT: "production"
                STATUS: "success"
                MENTION_CHANNEL: "channel"
                CUSTOM_FIELDS: '{"Version":"${BITBUCKET_TAG}","Release Notes":"https://github.com/org/repo/releases/${BITBUCKET_TAG}"}'
```

## Troubleshooting

### Webhook URL Issues

```bash
# Test webhook URL manually
curl -X POST YOUR_WEBHOOK_URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test message"}'
```

### Enable Debug Mode

```yaml
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "Test notification"
    DEBUG: "true"  # Shows full payload and response
```

### Common Issues

1. **403 Forbidden**: Webhook URL is invalid or expired
2. **404 Not Found**: Webhook URL is malformed
3. **No notification received**: Check channel permissions and webhook configuration
4. **Message formatting issues**: Verify JSON syntax in CUSTOM_FIELDS

## Security Best Practices

1. ✅ Store `SLACK_WEBHOOK_URL` as a **secured** Bitbucket variable
2. ✅ Never commit webhook URLs to source code
3. ✅ Use separate webhooks for different environments
4. ✅ Rotate webhook URLs periodically
5. ✅ Limit webhook permissions to specific channels

## Building the Pipe

```bash
cd bitbucket-pipes/slack-pipe
docker build -t nayaksuraj/slack-pipe:1.0.0 .
docker push nayaksuraj/slack-pipe:1.0.0
```

## License

MIT License - See repository root for details.

## Support

For issues, feature requests, or contributions:
- Repository: https://github.com/nayaksuraj/test-repo
- Issues: https://github.com/nayaksuraj/test-repo/issues
