#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Main notification function
send_notification() {
    local channel=$1

    log_info "Sending notification via $channel..."

    case $channel in
        slack)
            send_slack_notification
            ;;
        email)
            send_email_notification
            ;;
        teams)
            send_teams_notification
            ;;
        discord)
            send_discord_notification
            ;;
        webhook)
            send_webhook_notification
            ;;
        *)
            log_error "Unknown channel: $channel"
            return 1
            ;;
    esac
}

# Slack notification
send_slack_notification() {
    if [[ -z "${SLACK_WEBHOOK_URL}" ]]; then
        log_error "SLACK_WEBHOOK_URL is required for Slack notifications"
        return 1
    fi

    # Build Slack payload with auto-detected info
    local payload=$(cat <<EOF
{
  "text": "${MESSAGE}",
  "attachments": [{
    "color": "${STATUS_COLOR}",
    "title": "${TITLE}",
    "fields": [
      {"title": "Environment", "value": "${ENVIRONMENT:-N/A}", "short": true},
      {"title": "Status", "value": "${STATUS}", "short": true}
    ]
  }]
}
EOF
)

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN: Would send to Slack: $payload"
        return 0
    fi

    curl -X POST "${SLACK_WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        -s -o /dev/null -w "%{http_code}" | grep -q "200" && \
        log_success "Slack notification sent" || \
        log_error "Failed to send Slack notification"
}

# Email notification
send_email_notification() {
    if [[ -z "${EMAIL_TO}" ]] || [[ -z "${EMAIL_SMTP_HOST}" ]]; then
        log_error "EMAIL_TO and EMAIL_SMTP_HOST are required"
        return 1
    fi

    log_info "Email notification to ${EMAIL_TO}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN: Would send email"
        return 0
    fi

    # Email implementation using Python script
    python3 <<PYTHON
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

try:
    msg = MIMEMultipart('alternative')
    msg['Subject'] = os.getenv('TITLE', 'Bitbucket Pipeline Notification')
    msg['From'] = os.getenv('EMAIL_FROM', 'noreply@bitbucket.com')
    msg['To'] = os.getenv('EMAIL_TO')

    text = os.getenv('MESSAGE')
    html = f"<html><body><h2>{os.getenv('TITLE')}</h2><p>{text}</p></body></html>"

    msg.attach(MIMEText(text, 'plain'))
    msg.attach(MIMEText(html, 'html'))

    server = smtplib.SMTP(os.getenv('EMAIL_SMTP_HOST'), int(os.getenv('EMAIL_SMTP_PORT', '587')))
    if os.getenv('EMAIL_USE_TLS', 'true') == 'true':
        server.starttls()
    if os.getenv('EMAIL_SMTP_USERNAME'):
        server.login(os.getenv('EMAIL_SMTP_USERNAME'), os.getenv('EMAIL_SMTP_PASSWORD'))
    server.send_message(msg)
    server.quit()
    print("Email sent successfully")
except Exception as e:
    print(f"Failed to send email: {str(e)}")
    exit(1)
PYTHON

    log_success "Email notification sent"
}

# Teams notification
send_teams_notification() {
    if [[ -z "${TEAMS_WEBHOOK_URL}" ]]; then
        log_error "TEAMS_WEBHOOK_URL is required for Teams notifications"
        return 1
    fi

    local color="${TEAMS_THEME_COLOR:-0078D7}"
    local payload=$(cat <<EOF
{
  "@type": "MessageCard",
  "@context": "http://schema.org/extensions",
  "themeColor": "${color}",
  "summary": "${TITLE}",
  "sections": [{
    "activityTitle": "${TITLE}",
    "activitySubtitle": "${MESSAGE}",
    "facts": [
      {"name": "Environment", "value": "${ENVIRONMENT:-N/A}"},
      {"name": "Status", "value": "${STATUS}"}
    ]
  }]
}
EOF
)

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN: Would send to Teams"
        return 0
    fi

    curl -X POST "${TEAMS_WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        -s -o /dev/null -w "%{http_code}" | grep -q "200" && \
        log_success "Teams notification sent" || \
        log_error "Failed to send Teams notification"
}

# Discord notification
send_discord_notification() {
    if [[ -z "${DISCORD_WEBHOOK_URL}" ]]; then
        log_error "DISCORD_WEBHOOK_URL is required for Discord notifications"
        return 1
    fi

    local payload=$(cat <<EOF
{
  "content": "${MESSAGE}",
  "username": "${DISCORD_USERNAME:-CI/CD Bot}",
  "embeds": [{
    "title": "${TITLE}",
    "description": "${MESSAGE}",
    "color": ${DISCORD_COLOR:-65280},
    "fields": [
      {"name": "Environment", "value": "${ENVIRONMENT:-N/A}", "inline": true},
      {"name": "Status", "value": "${STATUS}", "inline": true}
    ]
  }]
}
EOF
)

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN: Would send to Discord"
        return 0
    fi

    curl -X POST "${DISCORD_WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        -s -o /dev/null -w "%{http_code}" | grep -q "204" && \
        log_success "Discord notification sent" || \
        log_error "Failed to send Discord notification"
}

# Generic webhook notification
send_webhook_notification() {
    if [[ -z "${WEBHOOK_URL}" ]]; then
        log_error "WEBHOOK_URL is required for webhook notifications"
        return 1
    fi

    local method="${WEBHOOK_METHOD:-POST}"
    local payload="${WEBHOOK_PAYLOAD_TEMPLATE}"

    if [[ -z "${payload}" ]]; then
        payload=$(cat <<EOF
{
  "message": "${MESSAGE}",
  "title": "${TITLE}",
  "status": "${STATUS}",
  "environment": "${ENVIRONMENT}"
}
EOF
)
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN: Would send webhook to ${WEBHOOK_URL}"
        return 0
    fi

    curl -X "${method}" "${WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        -s -o /dev/null -w "%{http_code}" | grep -q "2[0-9][0-9]" && \
        log_success "Webhook notification sent" || \
        log_error "Failed to send webhook notification"
}

# Determine color based on status
get_status_color() {
    case "${STATUS}" in
        success) echo "#36a64f"; echo "65280" ;; # Green
        warning) echo "#ff9900"; echo "16750848" ;; # Yellow
        error) echo "#ff0000"; echo "16711680" ;; # Red
        info) echo "#0078D7"; echo "30975" ;; # Blue
        *) echo "#808080"; echo "8421504" ;; # Gray
    esac
}

# Main execution
main() {
    log_info "Universal Notification Pipe v1.0.0"

    # Validate required variables
    if [[ -z "${CHANNELS}" ]]; then
        log_error "CHANNELS variable is required"
        exit 1
    fi

    if [[ -z "${MESSAGE}" ]]; then
        log_error "MESSAGE variable is required"
        exit 1
    fi

    # Set defaults
    TITLE="${TITLE:-Bitbucket Pipeline Notification}"
    STATUS="${STATUS:-success}"
    DRY_RUN="${DRY_RUN:-false}"

    # Get status colors
    read -r STATUS_COLOR DISCORD_COLOR <<< "$(get_status_color)"
    export STATUS_COLOR DISCORD_COLOR

    # Debug mode
    if [[ "${DEBUG}" == "true" ]]; then
        log_info "Debug mode enabled"
        log_info "CHANNELS: ${CHANNELS}"
        log_info "MESSAGE: ${MESSAGE}"
        log_info "STATUS: ${STATUS}"
        log_info "ENVIRONMENT: ${ENVIRONMENT}"
    fi

    # Split channels and send notifications
    IFS=',' read -ra CHANNEL_ARRAY <<< "${CHANNELS}"
    local failed=0

    for channel in "${CHANNEL_ARRAY[@]}"; do
        channel=$(echo "$channel" | xargs) # Trim whitespace
        if ! send_notification "$channel"; then
            failed=$((failed + 1))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_error "$failed notification(s) failed"
        exit 1
    fi

    log_success "All notifications sent successfully!"
}

main "$@"
