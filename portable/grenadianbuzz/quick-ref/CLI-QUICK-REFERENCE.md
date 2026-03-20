# GrenadianBuzz CLI Quick Reference

**One-page command cheat sheet for common GrenadianBuzz CLI tasks**

---

## Command Structure

```
gb <resource> <action> [options]
gb articles publish --title "..." --content "..." --schedule-at "2026-03-21T10:00Z"
gb moderation queue --status=flagged --limit=20
gb users create --email "user@example.com" --role=moderator
gb analytics export --start-date=2026-01-01 --format=json
```

---

## Global Options (All Commands)

| Option | Purpose |
|--------|---------|
| `--format=json\|table\|csv\|yaml` | Output format (default: table) |
| `--output=file.json` | Write to file instead of stdout |
| `--verbose` | Show API calls, timings, headers |
| `--dry-run` | Preview changes without applying |
| `--config=/path/to/config.json` | Use alternate config file |

---

## Common Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Generic error |
| 2 | Usage/validation error |
| 3 | Authentication required |
| 4 | Permission denied |
| 5 | Resource not found |
| 10 | Dry-run: would fail |

---

## Content Management

### Articles

```bash
# Create article
gb articles create --title "..." --content "..." --source=manual

# Publish
gb articles publish <id> --schedule-at "2026-03-21T10:00Z"

# Edit
gb articles update <id> --title "New Title" --content "..."

# List with filters
gb articles list --status=draft --limit=50 --format=table

# Export
gb articles export --start-date=2026-01-01 --format=csv --output=articles.csv

# Bulk import
gb articles import --file=articles.json --mode=merge|replace --dry-run
```

### Obituaries

```bash
# Create
gb obituaries create --name "John Doe" --date-of-death "1960-02-14" --bio "..."

# Search
gb obituaries search "John Doe" --limit=10

# List recent
gb obituaries list --days=30 --format=table

# Update details
gb obituaries update <id> --bio "..." --image-url="..."

# Export with metadata
gb obituaries export --format=json --include-biographical-data
```

### Events

```bash
# Create event
gb events create --title "Carnival 2026" --date="2026-02-17" --location="Grenada"

# Upcoming list
gb events upcoming --days=30 --format=table

# Update
gb events update <id> --date="2026-02-18" --status=confirmed

# Categorize
gb events update <id> --category=cultural|religious|national|sports
```

### Radio

```bash
# List stations
gb radio list --format=table

# Update streaming metadata
gb radio update <id> --stream-url="..." --bitrate=128

# Test stream availability
gb radio health-check --format=json
```

---

## User & Moderation

### User Management

```bash
# Create user
gb users create --email "user@example.com" --role=user|moderator|admin

# List users
gb users list --role=moderator --limit=100 --format=csv

# Update role
gb users update <id> --role=admin

# Disable account
gb users disable <id> --reason="Abuse"

# Export user data
gb users export --format=json --include-metadata
```

### Moderation

```bash
# View flagged queue
gb moderation queue --status=flagged --limit=20 --format=table

# Approve content
gb moderation approve <id> --reason="Looks good"

# Remove content
gb moderation remove <id> --reason="Violates policy"

# Escalate to admin
gb moderation escalate <id> --severity=high --reason="..."

# Bulk actions (dry-run first!)
gb moderation process --status=flagged --action=approve --limit=10 --dry-run
gb moderation process --status=flagged --action=approve --limit=10 --force

# View audit log
gb moderation audit --days=7 --format=json --output=audit.json

# Find content by keyword
gb moderation search "spam keyword" --format=table --limit=50
```

---

## Analytics & Reporting

### Export Data

```bash
# Daily engagement metrics
gb analytics engagement --date=2026-03-20 --format=csv --output=engagement.csv

# Trending content
gb analytics trending --days=7 --limit=20 --format=json

# Top users/creators
gb analytics top-creators --days=30 --metric=engagement_score --format=table

# Subscriber churn
gb analytics churn --start-date=2026-01-01 --end-date=2026-03-20 --format=csv

# Geographic distribution
gb analytics geography --format=json --output=geo.json
```

### Real-Time Metrics

```bash
# Live dashboard data
gb analytics live --metric=active_users|engagement_rate|new_subscribers --format=json

# Hourly summary
gb analytics hourly --hours=24 --format=table
```

---

## Configuration & Auth

### Authentication

```bash
# Login
gb auth login --email=admin@grenadianbuzz.com --password=...

# Use API key
gb auth login --api-key=<uuid>

# Logout
gb auth logout

# Show current user
gb auth whoami --format=json
```

### Configuration

```bash
# Show config
gb config show --format=json

# Set API endpoint
gb config set api-url "https://api.grenadianbuzz.com"

# Set output format preference
gb config set default-format json

# List profiles
gb config profiles list

# Switch profile
gb config profiles use staging
```

---

## Common Workflows

### Daily Editorial Review

```bash
gb articles list --status=draft --limit=50
gb moderation queue --status=flagged --limit=20
gb articles publish <id1> <id2> --schedule-at "2026-03-21T12:00Z"
gb analytics trending --days=1 --limit=10
```

### Bulk Import & Verify

```bash
gb articles import --file=articles.json --dry-run
# Review output
gb articles import --file=articles.json --mode=merge --force
gb articles list --status=imported --format=csv
```

### Moderation SLA Check

```bash
gb moderation queue --status=flagged --sort=created_at
gb moderation audit --days=1 --format=json | jq '.[] | select(.status=="pending")'
# Escalate anything > 24h old
```

### Generate Weekly Report

```bash
gb analytics engagement --start-date=2026-03-13 --end-date=2026-03-20 --format=csv
gb analytics trending --days=7 --format=json
gb moderation audit --days=7 --format=json
# Combine into weekly_report.json
```

---

## Error Handling

### Retry Failed Operations

```bash
# Use --dry-run first
gb articles import --file=articles.json --dry-run

# Check --verbose for details
gb articles import --file=articles.json --verbose

# Retry with exponential backoff (built-in)
gb articles import --file=articles.json --retries=5
```

### Debug API Calls

```bash
# Show request/response details
gb articles list --verbose --format=json

# Output to file for inspection
gb articles list --output=response.json --verbose
```

---

## Tips

- **Dry-run everything destructive**: Always use `--dry-run` before `--force`
- **Chain commands**: Combine with Unix pipes: `gb articles list --format=json | jq '.items | length'`
- **Export for analysis**: Use `--format=csv` for spreadsheets, `--format=json` for scripting
- **Automate with scripts**: Exit codes (0=success) work with bash `&&` / `||`
- **Check help**: `gb <resource> <action> --help` always available

---

## See Also

- **Full CLI Guide**: `reference/grenadianbuzz-cli-guide.md` (70+ commands, workflows, advanced patterns)
- **API Patterns**: `reference/grenadianbuzz-api-patterns.md` (underlying endpoints)
- **Main Skill**: `SKILL.md` (cross-surface guidance)
