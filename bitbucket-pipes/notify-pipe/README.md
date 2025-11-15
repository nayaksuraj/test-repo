# Universal Notification Pipe

Send notifications to **Slack**, **Email**, **Microsoft Teams**, **Discord**, **Webhooks**, and more - all from a single pipe. No need to configure multiple notification tools!

## 🎯 Features

- ✅ **Multi-Channel Support** - Slack, Email, Teams, Discord, Generic Webhooks
- ✅ **Single Configuration** - One pipe for all notification channels
- ✅ **Rich Formatting** - Status colors, custom fields, attachments
- ✅ **Auto-Detection** - Automatically includes commit, build, and repo info
- ✅ **Flexible** - Send to one or multiple channels simultaneously
- ✅ **Secure** - All credentials stored as secured Bitbucket variables
- ✅ **Priority Levels** - Low, Normal, High, Urgent
- ✅ **Mentions** - Tag users or channels
- ✅ **Dry Run** - Test configuration without sending

## 🚀 Quick Start

### Send to Slack

```yaml
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "slack"
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "✅ Deployed to production"
    STATUS: "success"
    ENVIRONMENT: "production"
```

### Send to Multiple Channels

```yaml
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "slack,email,teams"
    MESSAGE: "🚀 Production deployment completed"
    STATUS: "success"
    # Slack
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    # Email
    EMAIL_TO: "team@example.com"
    EMAIL_SMTP_HOST: "smtp.gmail.com"
    EMAIL_SMTP_USERNAME: $EMAIL_USERNAME
    EMAIL_SMTP_PASSWORD: $EMAIL_PASSWORD
    # Teams
    TEAMS_WEBHOOK_URL: $TEAMS_WEBHOOK_URL
```

## 📋 Supported Channels

| Channel | Description | Requires |
|---------|-------------|----------|
| **slack** | Slack via incoming webhooks | `SLACK_WEBHOOK_URL` |
| **email** | Email via SMTP | `EMAIL_TO`, `EMAIL_SMTP_HOST`, credentials |
| **teams** | Microsoft Teams | `TEAMS_WEBHOOK_URL` |
| **discord** | Discord webhooks | `DISCORD_WEBHOOK_URL` |
| **webhook** | Generic HTTP webhooks | `WEBHOOK_URL` |

## 📖 Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `CHANNELS` | Channels to notify (comma-separated) | `"slack,email"` |
| `MESSAGE` | Main notification message | `"✅ Deployment successful"` |

### Common Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `TITLE` | Notification title | `"Bitbucket Pipeline Notification"` | `"Production Release"` |
| `STATUS` | Status level | `"success"` | `"success"`, `"warning"`, `"error"`, `"info"` |
| `ENVIRONMENT` | Deployment environment | - | `"production"` |
| `PRIORITY` | Notification priority | `"normal"` | `"low"`, `"normal"`, `"high"`, `"urgent"` |
| `CUSTOM_FIELDS` | Custom JSON fields | - | `'{"Version":"1.2.3"}'` |
| `INCLUDE_COMMIT_INFO` | Include git info | `"true"` | `"true"`, `"false"` |
| `INCLUDE_BUILD_INFO` | Include pipeline info | `"true"` | `"true"`, `"false"` |

## 📱 Channel-Specific Configuration

### Slack

```yaml
variables:
  CHANNELS: "slack"
  SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL  # Required
  SLACK_CHANNEL: "#deployments"          # Optional: override default
  SLACK_USERNAME: "Deploy Bot"           # Optional: bot name
  SLACK_ICON_EMOJI: ":rocket:"          # Optional: bot icon
  MENTION_CHANNEL: "channel"            # Optional: @channel
  MENTION_USERS: "U123,U456"            # Optional: mention users
```

**Setup Slack Webhook:**
1. Go to https://api.slack.com/apps
2. Create new app → Incoming Webhooks
3. Add webhook to workspace
4. Copy webhook URL
5. Add to Bitbucket: `SLACK_WEBHOOK_URL` (mark as secured)

### Email

```yaml
variables:
  CHANNELS: "email"
  EMAIL_TO: "team@example.com,ops@example.com"  # Required
  EMAIL_FROM: "cicd@company.com"                # Optional
  EMAIL_SMTP_HOST: "smtp.gmail.com"             # Required
  EMAIL_SMTP_PORT: "587"                        # Optional (default: 587)
  EMAIL_SMTP_USERNAME: $EMAIL_USERNAME          # Required
  EMAIL_SMTP_PASSWORD: $EMAIL_PASSWORD          # Required (secured)
  EMAIL_USE_TLS: "true"                         # Optional (default: true)
```

**Setup Gmail SMTP:**
1. Enable 2-factor authentication
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use App Password as `EMAIL_SMTP_PASSWORD`
4. Set `EMAIL_SMTP_HOST: "smtp.gmail.com"`

**Other SMTP Providers:**
- **SendGrid**: `smtp.sendgrid.net:587`
- **AWS SES**: `email-smtp.us-east-1.amazonaws.com:587`
- **Mailgun**: `smtp.mailgun.org:587`
- **Office365**: `smtp.office365.com:587`

### Microsoft Teams

```yaml
variables:
  CHANNELS: "teams"
  TEAMS_WEBHOOK_URL: $TEAMS_WEBHOOK_URL  # Required
  TEAMS_THEME_COLOR: "0078D7"            # Optional: card color (hex)
```

**Setup Teams Webhook:**
1. Open Teams channel
2. Click "..." → Connectors
3. Add "Incoming Webhook"
4. Name it and copy URL
5. Add to Bitbucket: `TEAMS_WEBHOOK_URL` (mark as secured)

### Discord

```yaml
variables:
  CHANNELS: "discord"
  DISCORD_WEBHOOK_URL: $DISCORD_WEBHOOK_URL  # Required
  DISCORD_USERNAME: "CI/CD Bot"              # Optional: bot name
  DISCORD_AVATAR_URL: "https://..."          # Optional: bot avatar
```

**Setup Discord Webhook:**
1. Open Discord server settings
2. Integrations → Webhooks → New Webhook
3. Configure and copy URL
4. Add to Bitbucket: `DISCORD_WEBHOOK_URL` (mark as secured)

### Generic Webhook

```yaml
variables:
  CHANNELS: "webhook"
  WEBHOOK_URL: "https://api.example.com/notify"        # Required
  WEBHOOK_METHOD: "POST"                                # Optional (default: POST)
  WEBHOOK_HEADERS: '{"Authorization":"Bearer token"}'  # Optional
  WEBHOOK_PAYLOAD_TEMPLATE: '{"text":"{{MESSAGE}}"}'   # Optional
```

## 📚 Usage Examples

### Basic Success Notification

```yaml
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "slack"
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "✅ Build completed successfully"
    STATUS: "success"
```

### Production Deployment with Multiple Channels

```yaml
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "slack,email,teams"
    MESSAGE: "🚀 v1.2.3 deployed to production"
    TITLE: "Production Release"
    STATUS: "success"
    ENVIRONMENT: "production"
    PRIORITY: "high"
    CUSTOM_FIELDS: '{"Version":"1.2.3","Duration":"5m 23s","Replicas":"3"}'
    # Slack
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MENTION_CHANNEL: "channel"
    # Email
    EMAIL_TO: "team@company.com"
    EMAIL_SMTP_HOST: $EMAIL_SMTP_HOST
    EMAIL_SMTP_USERNAME: $EMAIL_USERNAME
    EMAIL_SMTP_PASSWORD: $EMAIL_PASSWORD
    # Teams
    TEAMS_WEBHOOK_URL: $TEAMS_WEBHOOK_URL
```

### Error Notification with Mentions

```yaml
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "slack,discord"
    MESSAGE: "❌ Production deployment failed"
    STATUS: "error"
    ENVIRONMENT: "production"
    PRIORITY: "urgent"
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MENTION_USERS: "U123456,U789012"  # Slack user IDs
    DISCORD_WEBHOOK_URL: $DISCORD_WEBHOOK_URL
```

### Conditional Notifications

```yaml
# Only notify on failure
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "slack,email"
    MESSAGE: "❌ Tests failed on ${BITBUCKET_BRANCH}"
    STATUS: "error"
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    EMAIL_TO: "oncall@company.com"
  condition:
    changesets:
      includePaths:
        - "src/**"
```

### Different Status Levels

```yaml
# Success (Green)
STATUS: "success"
MESSAGE: "✅ All tests passed"

# Warning (Yellow)
STATUS: "warning"
MESSAGE: "⚠️ Tests passed with warnings"

# Error (Red)
STATUS: "error"
MESSAGE: "❌ Build failed"

# Info (Blue)
STATUS: "info"
MESSAGE: "ℹ️ Deployment started"
```

### Custom Webhook Integration

```yaml
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "webhook"
    WEBHOOK_URL: "https://api.datadog.com/api/v1/events"
    WEBHOOK_METHOD: "POST"
    WEBHOOK_HEADERS: '{"DD-API-KEY":"${DATADOG_API_KEY}"}'
    WEBHOOK_PAYLOAD_TEMPLATE: |
      {
        "title": "{{TITLE}}",
        "text": "{{MESSAGE}}",
        "tags": ["env:{{ENVIRONMENT}}", "status:{{STATUS}}"],
        "alert_type": "{{STATUS}}"
      }
```

### Dry Run (Test Configuration)

```yaml
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "slack,email,teams"
    MESSAGE: "Test notification"
    DRY_RUN: "true"  # Validates but doesn't send
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    EMAIL_TO: "test@example.com"
    EMAIL_SMTP_HOST: "smtp.gmail.com"
    TEAMS_WEBHOOK_URL: $TEAMS_WEBHOOK_URL
```

## 🎨 Message Formatting

### Emoji Support

All channels support emojis:
```yaml
MESSAGE: "✅ Success"
MESSAGE: "❌ Failed"
MESSAGE: "⚠️ Warning"
MESSAGE: "🚀 Deployed"
MESSAGE: "🔄 Rolling back"
MESSAGE: "📊 Report ready"
```

### Markdown Support

Most channels support markdown:
```yaml
MESSAGE: |
  **Production Deployment Complete**
  - Version: 1.2.3
  - Duration: 5 minutes
  - Status: Success ✅
```

### Custom Fields

Add structured data:
```yaml
CUSTOM_FIELDS: |
  {
    "Version": "${BITBUCKET_TAG}",
    "Duration": "5m 23s",
    "Replicas": "3",
    "Region": "us-east-1",
    "Deployed By": "${BITBUCKET_REPO_OWNER}"
  }
```

## 🔍 Auto-Included Information

When `INCLUDE_COMMIT_INFO: "true"` (default):
- Commit hash
- Commit message
- Author name
- Branch name

When `INCLUDE_BUILD_INFO: "true"` (default):
- Pipeline number
- Build duration
- Pipeline URL
- Repository name

When `INCLUDE_REPO_INFO: "true"` (default):
- Repository full name
- Repository owner
- Repository URL

## 🔧 Advanced Configuration

### Priority Levels

```yaml
PRIORITY: "low"     # Minimal notification
PRIORITY: "normal"  # Standard notification (default)
PRIORITY: "high"    # Important notification
PRIORITY: "urgent"  # Critical notification (mentions, special formatting)
```

### Attach Pipeline Logs

```yaml
ATTACH_LOGS: "true"  # Attach last 100 lines of pipeline output
```

### Multiple Recipients

```yaml
# Email
EMAIL_TO: "team@company.com,ops@company.com,dev@company.com"

# Slack users
MENTION_USERS: "U123456,U789012,U345678"
```

## 🛠️ Troubleshooting

### Notification Not Received

1. **Check webhook URL**: Ensure it's correct and not expired
2. **Verify credentials**: Check SMTP credentials are correct
3. **Enable debug**: Set `DEBUG: "true"` to see detailed logs
4. **Test with dry run**: Use `DRY_RUN: "true"` to validate config

### Slack Webhook Errors

```yaml
# Error: Invalid webhook
# Solution: Regenerate webhook in Slack app settings

# Error: Channel not found
# Solution: Ensure bot is added to channel
```

### Email Delivery Issues

```yaml
# Error: SMTP authentication failed
# Solution: Use app-specific password for Gmail

# Error: Connection timeout
# Solution: Check firewall, use correct port (587 for TLS)
```

### Teams Card Not Showing

```yaml
# Error: Invalid JSON
# Solution: Ensure CUSTOM_FIELDS is valid JSON

# Error: Theme color not applied
# Solution: Use hex without '#': TEAMS_THEME_COLOR: "0078D7"
```

## 📊 Complete Pipeline Example

```yaml
image: atlassian/default-image:4

pipelines:
  branches:
    develop:
      - step:
          name: Deploy to Dev
          script:
            - echo "Deploying..."
      - pipe: docker://nayaksuraj/notify-pipe:1.0.0
        variables:
          CHANNELS: "slack"
          SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
          MESSAGE: "✅ Deployed to DEV"
          ENVIRONMENT: "dev"
          STATUS: "success"

    main:
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - echo "Deploying to production..."
      - pipe: docker://nayaksuraj/notify-pipe:1.0.0
        variables:
          CHANNELS: "slack,email,teams"
          MESSAGE: "🎉 Deployed to PRODUCTION"
          TITLE: "Production Release"
          ENVIRONMENT: "production"
          STATUS: "success"
          PRIORITY: "high"
          CUSTOM_FIELDS: '{"Version":"${BITBUCKET_TAG}"}'
          # Slack
          SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
          MENTION_CHANNEL: "channel"
          # Email
          EMAIL_TO: "team@company.com"
          EMAIL_SMTP_HOST: $EMAIL_SMTP_HOST
          EMAIL_SMTP_USERNAME: $EMAIL_USERNAME
          EMAIL_SMTP_PASSWORD: $EMAIL_PASSWORD
          # Teams
          TEAMS_WEBHOOK_URL: $TEAMS_WEBHOOK_URL
```

## 🔐 Security Best Practices

1. **Always mark credentials as secured** in Bitbucket variables
2. **Never hardcode** webhook URLs or passwords in pipeline
3. **Use app-specific passwords** for email (not account password)
4. **Rotate credentials** regularly
5. **Limit webhook scope** to specific channels/actions

## 📚 Additional Resources

- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)
- [Microsoft Teams Webhooks](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook)
- [Discord Webhooks](https://discord.com/developers/docs/resources/webhook)
- [SMTP Configuration Guide](https://support.google.com/mail/answer/7126229)

## 🆚 Comparison with Other Solutions

| Feature | notify-pipe | Multiple Separate Pipes |
|---------|-------------|------------------------|
| Configuration | Single pipe | 5+ pipes to configure |
| Maintenance | Update once | Update each pipe |
| Complexity | Low | High |
| Flexibility | High | Medium |
| Channels | 5+ | 1 per pipe |

## 🎓 Migration from slack-pipe

**Before:**
```yaml
- pipe: docker://nayaksuraj/slack-pipe:1.0.0
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "✅ Deployed"
```

**After:**
```yaml
- pipe: docker://nayaksuraj/notify-pipe:1.0.0
  variables:
    CHANNELS: "slack"  # Just add this
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
    MESSAGE: "✅ Deployed"
```

All other variables remain the same!

---

**Built with ❤️ for DevOps Teams** | **One Pipe to Notify Them All** 🚀
