#!/bin/bash
# =============================================================================
# Slack Notification Pipe - Send Rich Notifications to Slack
# =============================================================================
# Enterprise-grade Slack integration for pipeline notifications
# =============================================================================

set -e
set -o pipefail

# =============================================================================
# Color Output
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Debug Mode
# =============================================================================
if [[ "${DEBUG}" == "true" ]]; then
    info "Debug mode enabled"
    set -x
fi

# =============================================================================
# Validate Required Variables
# =============================================================================
if [[ -z "${SLACK_WEBHOOK_URL}" ]]; then
    error "SLACK_WEBHOOK_URL is required"
    exit 1
fi

# =============================================================================
# Configuration
# =============================================================================
MESSAGE="${MESSAGE:-✅ Pipeline completed successfully}"
TITLE="${TITLE:-Bitbucket Pipeline}"
STATUS="${STATUS:-success}"
INCLUDE_COMMIT_INFO="${INCLUDE_COMMIT_INFO:-true}"
INCLUDE_BUILD_INFO="${INCLUDE_BUILD_INFO:-true}"

# =============================================================================
# Get Git and Build Information
# =============================================================================
GIT_COMMIT="${BITBUCKET_COMMIT:-unknown}"
GIT_COMMIT_SHORT="${GIT_COMMIT:0:7}"
GIT_BRANCH="${BITBUCKET_BRANCH:-unknown}"
GIT_TAG="${BITBUCKET_TAG:-}"
REPO_SLUG="${BITBUCKET_REPO_SLUG:-unknown}"
BUILD_NUMBER="${BITBUCKET_BUILD_NUMBER:-unknown}"
PIPELINE_UUID="${BITBUCKET_PIPELINE_UUID:-}"

# Author information
COMMIT_AUTHOR="${BITBUCKET_COMMIT_AUTHOR_DISPLAYNAME:-Unknown}"
COMMIT_AUTHOR_EMAIL="${BITBUCKET_COMMIT_AUTHOR_EMAIL:-}"

# Build URL
if [[ -n "${BITBUCKET_WORKSPACE}" ]] && [[ -n "${BITBUCKET_REPO_SLUG}" ]] && [[ -n "${BUILD_NUMBER}" ]]; then
    BUILD_URL="https://bitbucket.org/${BITBUCKET_WORKSPACE}/${BITBUCKET_REPO_SLUG}/pipelines/results/${BUILD_NUMBER}"
else
    BUILD_URL=""
fi

# Commit URL
if [[ -n "${BITBUCKET_WORKSPACE}" ]] && [[ -n "${BITBUCKET_REPO_SLUG}" ]] && [[ "${GIT_COMMIT}" != "unknown" ]]; then
    COMMIT_URL="https://bitbucket.org/${BITBUCKET_WORKSPACE}/${BITBUCKET_REPO_SLUG}/commits/${GIT_COMMIT}"
else
    COMMIT_URL=""
fi

# =============================================================================
# Determine Notification Color and Icon
# =============================================================================
if [[ -n "${NOTIFICATION_COLOR}" ]]; then
    COLOR="${NOTIFICATION_COLOR}"
else
    case "${STATUS}" in
        success)
            COLOR="good"
            ICON="✅"
            ;;
        warning)
            COLOR="warning"
            ICON="⚠️"
            ;;
        error|failure)
            COLOR="danger"
            ICON="❌"
            ;;
        info)
            COLOR="#439FE0"
            ICON="ℹ️"
            ;;
        *)
            COLOR="#36a64f"
            ICON="📢"
            ;;
    esac
fi

# =============================================================================
# Build Slack Message
# =============================================================================
info "Building Slack notification..."

# Start with mentions if any
MENTION_TEXT=""
if [[ -n "${MENTION_CHANNEL}" ]]; then
    if [[ "${MENTION_CHANNEL}" == "channel" ]]; then
        MENTION_TEXT="<!channel> "
    elif [[ "${MENTION_CHANNEL}" == "here" ]]; then
        MENTION_TEXT="<!here> "
    fi
fi

if [[ -n "${MENTION_USERS}" ]]; then
    IFS=',' read -ra USERS <<< "${MENTION_USERS}"
    for user in "${USERS[@]}"; do
        MENTION_TEXT="${MENTION_TEXT}<@${user}> "
    done
fi

# Build fields array
FIELDS="[]"

# Add commit information
if [[ "${INCLUDE_COMMIT_INFO}" == "true" ]]; then
    if [[ -n "${COMMIT_URL}" ]]; then
        COMMIT_FIELD="{\"type\":\"mrkdwn\",\"text\":\"*Commit:*\n<${COMMIT_URL}|\`${GIT_COMMIT_SHORT}\`>\"}"
    else
        COMMIT_FIELD="{\"type\":\"mrkdwn\",\"text\":\"*Commit:*\n\`${GIT_COMMIT_SHORT}\`\"}"
    fi
    FIELDS=$(echo "$FIELDS" | jq ". += [$COMMIT_FIELD]")

    BRANCH_FIELD="{\"type\":\"mrkdwn\",\"text\":\"*Branch:*\n${GIT_BRANCH}\"}"
    FIELDS=$(echo "$FIELDS" | jq ". += [$BRANCH_FIELD]")

    if [[ -n "${GIT_TAG}" ]]; then
        TAG_FIELD="{\"type\":\"mrkdwn\",\"text\":\"*Tag:*\n${GIT_TAG}\"}"
        FIELDS=$(echo "$FIELDS" | jq ". += [$TAG_FIELD]")
    fi

    AUTHOR_FIELD="{\"type\":\"mrkdwn\",\"text\":\"*Author:*\n${COMMIT_AUTHOR}\"}"
    FIELDS=$(echo "$FIELDS" | jq ". += [$AUTHOR_FIELD]")
fi

# Add build information
if [[ "${INCLUDE_BUILD_INFO}" == "true" ]]; then
    BUILD_FIELD="{\"type\":\"mrkdwn\",\"text\":\"*Build:*\n#${BUILD_NUMBER}\"}"
    FIELDS=$(echo "$FIELDS" | jq ". += [$BUILD_FIELD]")

    REPO_FIELD="{\"type\":\"mrkdwn\",\"text\":\"*Repository:*\n${REPO_SLUG}\"}"
    FIELDS=$(echo "$FIELDS" | jq ". += [$REPO_FIELD]")
fi

# Add environment if specified
if [[ -n "${ENVIRONMENT}" ]]; then
    ENV_FIELD="{\"type\":\"mrkdwn\",\"text\":\"*Environment:*\n${ENVIRONMENT}\"}"
    FIELDS=$(echo "$FIELDS" | jq ". += [$ENV_FIELD]")
fi

# Add custom fields if provided
if [[ -n "${CUSTOM_FIELDS}" ]]; then
    # Parse JSON custom fields
    while IFS="=" read -r key value; do
        if [[ -n "$key" ]] && [[ -n "$value" ]]; then
            CUSTOM_FIELD="{\"type\":\"mrkdwn\",\"text\":\"*${key}:*\n${value}\"}"
            FIELDS=$(echo "$FIELDS" | jq ". += [$CUSTOM_FIELD]")
        fi
    done < <(echo "$CUSTOM_FIELDS" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"')
fi

# =============================================================================
# Construct Slack Payload
# =============================================================================
PAYLOAD=$(cat <<EOF
{
  "text": "${MENTION_TEXT}${ICON} ${MESSAGE}",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "${ICON} ${TITLE}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "${MESSAGE}"
      }
    },
    {
      "type": "section",
      "fields": ${FIELDS}
    }
  ],
  "attachments": [
    {
      "color": "${COLOR}",
      "fallback": "${MESSAGE}",
      "footer": "Bitbucket Pipelines",
      "footer_icon": "https://bitbucket.org/favicon.ico",
      "ts": $(date +%s)
    }
  ]
}
EOF
)

# Add thread_ts if replying to a thread
if [[ -n "${THREAD_TS}" ]]; then
    PAYLOAD=$(echo "$PAYLOAD" | jq ". += {\"thread_ts\": \"${THREAD_TS}\"}")
fi

# Add Build URL as action button if available
if [[ -n "${BUILD_URL}" ]]; then
    PAYLOAD=$(echo "$PAYLOAD" | jq ".blocks += [{
      \"type\": \"actions\",
      \"elements\": [
        {
          \"type\": \"button\",
          \"text\": {
            \"type\": \"plain_text\",
            \"text\": \"View Pipeline\"
          },
          \"url\": \"${BUILD_URL}\"
        }
      ]
    }]")
fi

# =============================================================================
# Send Notification to Slack
# =============================================================================
info "Sending notification to Slack..."

if [[ "${DEBUG}" == "true" ]]; then
    info "Payload:"
    echo "$PAYLOAD" | jq .
fi

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SLACK_WEBHOOK_URL}" \
    -H 'Content-Type: application/json' \
    -d "$PAYLOAD")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

# =============================================================================
# Check Response
# =============================================================================
if [[ "${HTTP_CODE}" == "200" ]]; then
    success "Slack notification sent successfully!"
    echo ""
    info "Notification Details:"
    echo "  Title: ${TITLE}"
    echo "  Message: ${MESSAGE}"
    echo "  Status: ${STATUS}"
    if [[ -n "${ENVIRONMENT}" ]]; then
        echo "  Environment: ${ENVIRONMENT}"
    fi
    echo "  Commit: ${GIT_COMMIT_SHORT}"
    echo "  Branch: ${GIT_BRANCH}"
    echo ""
else
    error "Failed to send Slack notification"
    echo "  HTTP Code: ${HTTP_CODE}"
    echo "  Response: ${RESPONSE_BODY}"
    exit 1
fi

success "Slack pipe completed successfully!"
