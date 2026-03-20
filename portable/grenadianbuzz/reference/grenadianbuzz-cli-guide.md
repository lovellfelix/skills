# GrenadianBuzz CLI Reference Guide

**Deep reference for command-line interface design and workflows for GrenadianBuzz tools**

Based on actual CLI surface: `~/projects/grenadianbuzz/cli`

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Command Structure](#command-structure)
3. [Common Patterns](#common-patterns)
4. [Content Management Commands](#content-management-commands)
5. [User & Moderation Commands](#user--moderation-commands)
6. [Analytics & Reporting](#analytics--reporting)
7. [Configuration & Authentication](#configuration--authentication)
8. [Error Handling & Debugging](#error-handling--debugging)
9. [Examples & Workflows](#examples--workflows)

---

## Architecture Overview

The GrenadianBuzz CLI is built for:
- **Admin operations**: Bulk content review, moderation, user management
- **Editorial workflows**: Publishing, scheduling, content curation
- **Data operations**: Analytics export, content sync, backup/restore
- **Troubleshooting**: Log inspection, health checks, debugging

### Design Principles

1. **Composable**: Small commands that chain together
2. **Scriptable**: JSON output, exit codes, idempotent operations
3. **Safe by default**: Destructive ops require explicit confirmation
4. **Documented inline**: `--help`, examples, exit codes
5. **Audit-aware**: All operations logged with timestamp, user, changes

---

## Command Structure

### Naming Convention

```
gb <resource> <action> [options]
```

**Examples**:
```bash
gb articles publish --title "..." --schedule-at "2026-03-21T10:00:00Z"
gb moderation queue --status=flagged --limit=20
gb users create --email "..." --role=admin
gb analytics export --start-date=2026-01-01 --format=json
```

### Option Patterns

| Pattern | Purpose | Example |
|---------|---------|---------|
| `--flag` | Boolean toggle | `--dry-run`, `--force` |
| `--key=value` | Single value | `--limit=10`, `--format=json` |
| `--key value` | Alternative syntax | `--filter-by flagged` |
| `-f, --file` | Short + long form | `-f article.json` or `--file article.json` |
| `--key="value with spaces"` | Quoted values | `--title="Top 10 Carnival Moments"` |

### Exit Codes

```
0 - Success
1 - Generic error
2 - Usage/validation error
3 - Authentication required
4 - Permission denied
5 - Resource not found
10 - Dry-run: would fail
```

### Standard Options (All Commands)

```bash
--format=json|table|csv|yaml    # Output format (default: table)
--output=file.json              # Write to file instead of stdout
--verbose                        # Show API calls, headers, timings
--dry-run                        # Preview changes without applying
--config=/path/to/config.json   # Use alternate config
```

---

## Common Patterns

### Authentication

```bash
# Login (stores token in ~/.gb/config.json)
gb auth login --email=admin@grenadianbuzz.com --password=...

# Use API key instead
gb auth login --api-key=<uuid>

# Check current session
gb auth whoami
gb auth token-info

# Logout
gb auth logout
```

**Token storage** (encrypted):
- Location: `~/.gb/config.json`
- Expiry: 24 hours (auto-refreshes with valid refresh token)
- Scope: Inherited from server; admin token = all operations

### Filtering & Pagination

```bash
# Pagination (cursor-based, stable across updates)
gb articles list --limit=20 --cursor="eyJwb3NpdGlvbiI6IDIwfQ=="

# Filtering (same as API)
gb articles list --status=published --category=obituaries --date-from=2026-01-01

# Sorting (field:direction)
gb articles list --sort=published_at:desc,like_count:desc

# Combining filters
gb articles list --status=published --author-id=<uuid> --limit=50 --format=json
```

### Bulk Operations

```bash
# Bulk update from file
gb articles bulk-update << EOF
{
  "updates": [
    { "id": "<uuid1>", "status": "archived" },
    { "id": "<uuid2>", "status": "archived" }
  ]
}
EOF

# Bulk export to file
gb articles export --format=json > articles_backup_2026-03.json

# Bulk import from file
gb articles import articles_backup_2026-03.json --dry-run
gb articles import articles_backup_2026-03.json --confirm
```

### Conditional Operations

```bash
# Only run if condition is true
gb articles publish --id=<uuid> --if-status=draft --force

# Retry with exponential backoff (automatic for transient errors)
gb moderation process-queue --retry-attempts=5 --retry-delay=2

# Timeout override
gb sync articles --timeout=30s

# Skip errors and continue
gb articles bulk-update updates.json --skip-errors --continue-on-failure
```

---

## Content Management Commands

### Articles

```bash
# List articles
gb articles list --status=draft --limit=20 --format=json

# Get single article
gb articles get <article-id> --include=comments,reactions

# Create new article
gb articles create \
  --title="New Story" \
  --content="..." \
  --category=news \
  --source-id=<uuid> \
  --status=draft

# Update article
gb articles update <article-id> \
  --title="Updated Title" \
  --content="..." \
  --status=published

# Publish with scheduling
gb articles publish <article-id> \
  --schedule-at="2026-03-21T10:00:00Z" \
  --notify-users=true

# Archive old articles (dry-run first)
gb articles archive --published-before=2025-01-01 --dry-run
gb articles archive --published-before=2025-01-01 --confirm

# Bulk delete
gb articles delete <id1>,<id2>,<id3> --force
```

### Obituaries

```bash
# List with search
gb obituaries list --search="name of deceased" --limit=10

# Create obituary
gb obituaries create \
  --name="John Doe" \
  --date-of-death="2026-03-15" \
  --biography="..." \
  --photo-url="..."

# Update obituary
gb obituaries update <obituary-id> --bio-update "Additional details..."

# Flag for review (manual curation)
gb obituaries flag <obituary-id> --reason="Needs verification"

# Approve flagged obituary
gb obituaries approve <obituary-id>

# List flagged
gb obituaries list --status=flagged --limit=20
```

### Events

```bash
# List upcoming events
gb events list --after-date=2026-03-20 --category=carnival,religious --sort=start_date:asc

# Create event
gb events create \
  --title="Grenada Independence Day" \
  --start-date="2026-02-07T09:00:00Z" \
  --end-date="2026-02-07T18:00:00Z" \
  --location="St. George's" \
  --category=national_holiday \
  --description="..."

# Update event
gb events update <event-id> --location="Updated venue"

# Mark event as featured
gb events feature <event-id> --until="2026-03-31T23:59:59Z"

# Duplicate event (for recurring events)
gb events duplicate <event-id> --repeat=weekly --until="2026-06-01"
```

### Radio Stations

```bash
# List stations
gb radio list --country=grenada --language=english

# Add station
gb radio add \
  --name="Station Name" \
  --stream-url="https://..." \
  --genre=news \
  --language=english

# Update station metadata
gb radio update <station-id> --timezone="America/Grenada"

# Check stream health
gb radio health-check <station-id> --verbose

# List all unhealthy streams
gb radio health-check --all --report=failing
```

---

## User & Moderation Commands

### User Management

```bash
# List users
gb users list --role=admin --active=true --limit=50

# Create user
gb users create \
  --email="user@example.com" \
  --role=subscriber \
  --subscription-tier=free

# Update user
gb users update <user-id> \
  --role=moderator \
  --subscription-tier=premium

# Promote to admin
gb users promote <user-id> --to=admin

# Demote from admin
gb users demote <user-id> --from=admin --to=moderator

# Reset password
gb users reset-password <user-id>

# List suspended users
gb users list --status=suspended --limit=20

# Suspend user (revoke API access, hide content)
gb users suspend <user-id> --reason="Spam behavior"

# Reactivate user
gb users reactivate <user-id>

# Delete user (irreversible; archive instead for audit)
gb users delete <user-id> --reason="GDPR deletion request" --confirm
```

### Moderation Queue

```bash
# View moderation queue (flagged content)
gb moderation queue \
  --status=pending \
  --sort=created_at:asc \
  --limit=20 \
  --format=table

# Get specific flagged item
gb moderation get <flagged-id> --include=flags,actions

# Flag content for review
gb moderation flag <article-id> \
  --reason="Spam" \
  --priority=high \
  --assigned-to=<moderator-uuid>

# Mark for further review
gb moderation escalate <flagged-id> --reason="Needs legal review"

# Approve flagged content
gb moderation approve <flagged-id> --notes="No policy violation"

# Remove flagged content
gb moderation remove <flagged-id> \
  --reason="Violates community standards" \
  --notify-author=true

# Bulk moderation action
gb moderation bulk-action << EOF
{
  "action": "approve",
  "flagged_ids": ["<uuid1>", "<uuid2>", "<uuid3>"],
  "notes": "Reviewed and cleared"
}
EOF

# Moderation report
gb moderation report --date-from=2026-01-01 --date-to=2026-03-20 --format=csv > mod_report.csv
```

### Comments

```bash
# List comments on article
gb comments list --article-id=<uuid> --status=approved --sort=created_at:desc

# Get comment thread
gb comments get <comment-id> --include=replies

# Hide comment (soft delete)
gb comments hide <comment-id> --reason="Spam"

# Restore hidden comment
gb comments restore <comment-id>

# Bulk hide comments by user
gb comments bulk-hide --author-id=<user-uuid> --reason="User suspended"
```

---

## Analytics & Reporting

### Dashboard Analytics

```bash
# Real-time stats
gb analytics dashboard \
  --metric=articles_published,total_views,top_users \
  --period=today \
  --format=json

# Engagement summary
gb analytics engagement \
  --start-date=2026-01-01 \
  --end-date=2026-03-20 \
  --granularity=daily \
  --format=csv > engagement.csv

# Top creators
gb analytics top-creators \
  --limit=10 \
  --period=this-month \
  --metric=follower_growth,engagement_rate

# Trending articles
gb analytics trending \
  --category=news,obituaries \
  --time-window=7d \
  --limit=20 \
  --format=json
```

### Content Reports

```bash
# Content by category
gb analytics content-breakdown \
  --start-date=2026-01-01 \
  --by=category \
  --format=table

# Author performance
gb analytics author-performance \
  --author-id=<uuid> \
  --metrics=articles_published,total_views,avg_engagement \
  --period=this-month

# Moderation stats
gb analytics moderation-stats \
  --start-date=2026-01-01 \
  --by=reason,reviewer \
  --format=json > mod_stats.json
```

### Export & Reporting

```bash
# Export articles for external analysis
gb export articles \
  --start-date=2026-01-01 \
  --end-date=2026-03-20 \
  --status=published \
  --include-comments=true \
  --format=json > articles_export.json

# Export user data (GDPR/privacy export)
gb export user-data <user-id> --format=json > user_data_<user-id>.json

# Schedule recurring report
gb reports schedule \
  --name="Weekly Engagement" \
  --type=engagement \
  --frequency=weekly \
  --send-to=admin@grenadianbuzz.com \
  --format=csv

# Generate ad-hoc report
gb reports generate \
  --type=content-performance \
  --start-date=2026-01-01 \
  --end-date=2026-03-20 \
  --output=report_2026_q1.pdf
```

---

## Configuration & Authentication

### Config Management

```bash
# Initialize config (first-time setup)
gb config init
# Prompts for: email, API key/password, default format, editor

# Show current config
gb config show

# Update config value
gb config set default-format=json
gb config set editor=vim
gb config set timeout=30s

# Show all saved profiles
gb config profiles

# Switch profile
gb config use-profile=production

# Create new profile
gb config profile-add staging \
  --api-url=https://staging-api.grenadianbuzz.com \
  --api-key=<key>

# Delete profile
gb config profile-delete staging --confirm
```

### Secrets & API Keys

```bash
# List API keys
gb auth api-keys list

# Create API key (with expiry)
gb auth api-keys create \
  --name="CI/CD Pipeline" \
  --expires-in=90d \
  --scopes=articles:read,moderation:write

# Revoke API key
gb auth api-keys revoke <key-id>

# Store/retrieve secrets from config
gb secrets set SLACK_WEBHOOK https://hooks.slack.com/...
gb secrets get SLACK_WEBHOOK

# Test stored credential
gb secrets test-connection <profile-name>
```

---

## Error Handling & Debugging

### Verbose Output & Logging

```bash
# Verbose mode (shows HTTP requests, responses, timing)
gb articles list --verbose --limit=5

# Debug mode (includes full stack traces)
gb articles list --debug

# Log to file
gb articles list --log-file=/tmp/gb-debug.log

# Check logs
gb logs tail --lines=50
gb logs search "error" --since=1h
```

### Troubleshooting

```bash
# Health check (API connectivity, auth status)
gb health-check

# Verify auth token
gb auth verify

# Check rate limiting
gb rate-limit status

# Test API with simple ping
gb ping

# Diagnose connectivity
gb diagnose --verbose > diagnostic_report.txt
```

### Common Issues

**Rate Limited**:
```bash
gb articles list --rate-limit-delay=2s --retry-attempts=5
```

**Timeout on Large Requests**:
```bash
gb export articles --timeout=60s --batch-size=100
```

**Authentication Failed**:
```bash
gb auth logout
gb auth login --email=admin@grenadianbuzz.com
```

**Malformed JSON in File**:
```bash
gb articles import articles.json --validate-only
# Fix errors, then retry
gb articles import articles.json --confirm
```

---

## Examples & Workflows

### Daily Editorial Workflow

```bash
#!/bin/bash
set -euo pipefail

# Check login
gb auth verify

# Review overnight moderation queue
gb moderation queue --status=pending --limit=20

# Bulk approve routine moderation flags
gb moderation bulk-action << 'EOF'
{
  "action": "approve",
  "flagged_ids": ["uuid1", "uuid2", "uuid3"],
  "notes": "Reviewed, no violations"
}
EOF

# Publish scheduled articles
gb articles list --status=scheduled --schedule-ready=true --dry-run
gb articles list --status=scheduled --schedule-ready=true | \
  jq '.data[].id' | \
  xargs -I {} gb articles publish {}

# Generate daily engagement report
gb analytics engagement --period=today --format=csv > report_$(date +%Y-%m-%d).csv

echo "Editorial workflow complete."
```

### Bulk Content Migration

```bash
#!/bin/bash

# Export articles from old system
gb export articles --status=published --format=json > backup_articles.json

# Validate export
gb articles import backup_articles.json --validate-only

# Dry-run import (see what would change)
gb articles import backup_articles.json --dry-run

# Actual import with confirmation
gb articles import backup_articles.json --confirm --verbose

# Verify counts match
EXPORTED=$(jq '.data | length' backup_articles.json)
IMPORTED=$(gb articles list --format=json | jq '.total')
[ "$EXPORTED" -eq "$IMPORTED" ] && echo "Migration successful" || echo "Mismatch!"
```

### Automated Cleanup

```bash
#!/bin/bash

# Archive articles older than 1 year (with safety)
gb articles archive --published-before=2025-03-20 --dry-run

# After review:
gb articles archive --published-before=2025-03-20 --confirm

# Clean up suspended users' content
gb comments bulk-hide --author-id=<suspended-user-uuid> --dry-run
gb comments bulk-hide --author-id=<suspended-user-uuid> --confirm

# Generate cleanup report
gb analytics moderation-stats --start-date=2026-03-01 --format=json > cleanup_stats.json
```

### Moderation Workflow with Escalation

```bash
#!/bin/bash

# Check queue
PENDING=$(gb moderation queue --status=pending --format=json | jq '.total')
echo "Pending moderation items: $PENDING"

# Process flagged items
gb moderation queue --status=pending --sort=created_at:asc | while read -r ITEM; do
  ID=$(echo "$ITEM" | jq -r '.id')
  REASON=$(echo "$ITEM" | jq -r '.reason')
  
  case "$REASON" in
    "spam")
      gb moderation remove "$ID" --reason="Spam" --notify-author=true
      ;;
    "offensive")
      gb moderation escalate "$ID" --reason="Needs legal review"
      ;;
    *)
      gb moderation approve "$ID" --notes="No violation found"
      ;;
  esac
done

# Report escalated items
gb moderation queue --status=escalated --format=csv > escalated_items.csv
```

---

## Integration Examples

### Slack Notifications

```bash
#!/bin/bash

WEBHOOK_URL=$(gb secrets get SLACK_WEBHOOK)

# Alert on moderation backlog
PENDING=$(gb moderation queue --status=pending --format=json | jq '.total')
if [ "$PENDING" -gt 50 ]; then
  curl -X POST "$WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"Moderation backlog high: $PENDING items\"}"
fi
```

### Health Monitoring

```bash
#!/bin/bash

# Check API health every 5 minutes
while true; do
  if ! gb health-check --quiet; then
    echo "API down at $(date)" >> /var/log/gb-health.log
    # Trigger alert
    gb secrets get ALERT_WEBHOOK | xargs -I {} curl -X POST {} -d "API down"
  fi
  sleep 300
done
```

---

## Design Considerations for CLI Extensions

When adding new CLI commands:

1. **Consistency**: Follow `gb <resource> <action>` pattern
2. **Safety**: Destructive ops require `--confirm` or `--force`
3. **Scriptability**: JSON output, no interactive prompts by default
4. **Discoverability**: Built-in help, examples, man pages
5. **Audit**: All changes logged with user, timestamp, changes
6. **Idempotency**: Running same command twice should be safe
7. **Composability**: Commands should chain with pipes and redirects

---

## See Also

- **API Reference**: `grenadianbuzz-api-patterns.md` (REST endpoints, versioning)
- **Domain Checklist**: `grenadianbuzz-domain-checklist.md` (validation patterns)
- **Dashboard Guide**: `grenadianbuzz-dashboard-guide.md` (web UI patterns)
- **Website Guide**: `grenadianbuzz-website-guide.md` (public site patterns)
