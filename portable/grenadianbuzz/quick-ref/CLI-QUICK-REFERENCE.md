# GrenadianBuzz CLI Quick Reference

**One-page command cheat sheet for the actual GBuzz CLI**

---

## Command Structure

# Top-level help (short)
```
Usage: gbuzz [global options] <command> [command options]

Options:
  --log-level LEVEL    Set logging level (DEBUG, INFO, WARNING, ERROR)
  -v, -vv, -vvv        Verbosity (increase logging)
  --json-format        Output logs in JSON format
  --config PATH        Path to YAML config file (default: ~/.config/gbuzz/config.yaml) (example default path for local dev; in CI prefer env vars/secrets)
  --help               Show this help message

Commands:
  crawl         Crawl content sources (rss, wordpress, station...)
  notify        Send notifications (newsletter, feedback, seasonal)
  archive       Archive expired analytics data
  discover      Discover feeds and radio stations
  fix-streams   Validate and repair station streams
  task-runner   Run scheduled/continuous tasks
```

```
gbuzz [global options] <command> [command options]
gbuzz crawl rss --now
gbuzz notify newsletter --force
gbuzz archive run --mode latest
gbuzz discover stations --country Grenada
gbuzz fix-streams --dry-run
gbuzz task-runner --tasks rss,wordpress --once
```

---

## Global Options (All Commands)

| Option | Purpose |
|--------|---------|
| `--log-level LEVEL` | Set logging level (DEBUG, INFO, WARNING, ERROR) |
| `-v, -vv, -vvv` | Verbose: -v=INFO, -vv=VERBOSE(15), -vvv=DEBUG |
| `--timestamp/--no-timestamp` | Enable or disable timestamp in logs (default: enabled) |
| `--json-format` | Output logs in JSON format (for Kubernetes/containers) |
| `--config PATH` | Path to YAML config file (default: ~/.config/gbuzz/config.yaml) |

---

## Configuration

### Environment Variables (Recommended)
```bash
export API_URL="https://your-api-endpoint.com"
# WARNING: replace with your real client key. Use environment variables or a secrets manager in CI. Do NOT commit secrets to git.
export API_CLIENT_KEY="YOUR_API_CLIENT_KEY"
```

### Configuration File (~/.config/gbuzz/config.yaml)
```yaml
API_URL: "https://your-api-endpoint.com"
# WARNING: replace with your real client key. Use environment variables or a secrets manager in CI. Do NOT commit secrets to git.
API_CLIENT_KEY: "YOUR_API_CLIENT_KEY"
# Optional HTTP configuration
HTTP_TIMEOUT: 30
CONNECT_TIMEOUT: 10
HTTP_POOL_CONNECTIONS: 10
HTTP_POOL_MAXSIZE: 20
HTTP_KEEP_ALIVE: true
```

---

## Commands

### crawl

Crawl content from various sources. Available crawlers are dynamically registered from the tasks registry.

```bash
# Common crawlers
gbuzz crawl rss [--ttl 21600] [--now]
gbuzz crawl wordpress [--ttl 21600] [--now]
gbuzz crawl station [--ttl 21600] [--now]
gbuzz crawl station-discover [--ttl 21600] [--now]
gbuzz crawl obituary-html [--ttl 21600] [--now]

# Options
--ttl SECONDS    # Time-to-live between crawls (default: 21600 = 6 hours)
--now            # Force crawl and skip TTL/hash checks
```

### notify

Send notifications to users.

```bash
# Newsletter notifications (default: Saturdays 9-11 AM)
gbuzz notify newsletter [--cron CRON] [--grace-minutes MINS] [--force] [--users-limit N]

# Feedback requests (default: multiple times daily)
gbuzz notify feedback [--cron CRON] [--grace-minutes MINS] [--force] [--users-limit N]

# New Year greeting (default: New Year's Day 9 AM)
gbuzz notify newyear [--cron CRON] [--grace-minutes MINS] [--force] [--users-limit N]

# Christmas greeting
gbuzz notify christmas [--cron CRON] [--grace-minutes MINS] [--force] [--users-limit N]

# Options
--cron SCHEDULE          # Cron schedule (e.g., "0 9 * * 1" for Monday 9 AM)
--grace-minutes MINS     # Grace period in minutes
--force                  # Force delivery bypassing checks
--users-limit N          # Limit number of users to notify
```

### archive

Archive expired analytics data.

```bash
gbuzz archive run [--mode latest|all] [--retention MONTHS] [--dry-run] [--force]

# Options
--mode latest            # Archive latest batch only (default)
--mode all               # Archive all expired entries
--retention MONTHS       # Retention period in months (default: 23)
--dry-run                # Simulate without modifying data
--force                  # Force the archiving process
```

### discover

Discover feeds and stations from various sources.

```bash
# Discover feeds from a website
gbuzz discover feeds <URL> [--min-confidence 0.0] [--format json]

# Discover radio stations
gbuzz discover stations [--country COUNTRY] [--search NAME] [--tag TAG] \
                        [--caribbean] [--limit 50] [--validate] [--format json|table]

# Examples
gbuzz discover stations --country Grenada
gbuzz discover stations --caribbean --validate
gbuzz discover stations --search calypso --limit 20
```

### fix-streams

Validate and fix station stream URLs using fallback methods.

```bash
gbuzz fix-streams [--validate-only] [--dry-run] [--limit 100] [--format json|table]

# Options
--validate-only          # Only validate streams without fixing
--dry-run                # Show what would be fixed without applying changes
--limit N                # Maximum stations to process (default: 100)
--format json|table      # Output format (default: json)
```

### task-runner

Run multiple tasks in continuous or one-time mode.

```bash
# Run specific tasks
gbuzz task-runner --tasks rss,wordpress,station [--once] [--interval 300] [--force]

# Run all available tasks
gbuzz task-runner --all [--once] [--interval 300]

# Options
--tasks NAMES            # Comma-separated task names (e.g., rss,wordpress)
--all                    # Run all available tasks
--once                   # Run once and exit
--interval SECS          # Seconds between iterations (default: 300)
--force                  # Force task execution (bypass TTL checks)
--ttl SECS               # Task freshness TTL in seconds (default: 10800)
--metrics-port PORT      # Port for Prometheus metrics server
```

---

## Common Workflows

### Daily Content Crawl
```bash
# Run with verbose logging
gbuzz -v crawl rss --now
gbuzz -v crawl wordpress --now

# Or use task-runner for multiple sources at once
gbuzz task-runner --tasks rss,wordpress,station --once
```

### Monitor and Fix Stations
```bash
# Discover new stations
gbuzz -v discover stations --caribbean

# Validate existing streams (dry-run)
gbuzz fix-streams --dry-run

# Apply fixes
gbuzz fix-streams
```

### Scheduled Notifications
```bash
# Send newsletter immediately
gbuzz notify newsletter --force

# Send with custom schedule (every Friday 8 AM)
gbuzz notify newsletter --cron "0 8 * * 5"

# Limit to 100 users
gbuzz notify newsletter --users-limit 100
```

### Archive Old Analytics (Monthly)
```bash
# Check what would be archived
gbuzz archive run --mode all --dry-run

# Archive with 23-month retention
gbuzz archive run --mode all --retention 23
```

### Continuous Task Execution (Production)
```bash
# Run all tasks every 5 minutes with metrics
gbuzz task-runner --all --interval 300 --metrics-port 8080

# For Kubernetes with JSON logs
gbuzz --json-format task-runner --all --metrics-port 8080
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Generic error |
| 2 | Usage/validation error |

---

## Debugging

```bash
# Verbose output (INFO level)
gbuzz -v crawl rss

# Very verbose (VERBOSE level, detailed operations)
gbuzz -vv crawl rss

# Debug output (DEBUG level)
gbuzz -vvv crawl rss

# JSON logs with full details
gbuzz -vvv --json-format crawl rss

# Override log level
gbuzz --log-level DEBUG crawl rss
```

---

## Notes

- **Config precedence**: Environment variables override config file
- **Cron schedules**: Evaluated in user's local timezone (for notify commands)
- **TTL**: Time-to-live between crawls; use `--now` to bypass
- **Dry-run**: Always available on mutating operations (archive, fix-streams)
- **JSON format**: Ideal for container/Kubernetes deployments with structured logging
