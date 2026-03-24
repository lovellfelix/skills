# GrenadianBuzz CLI Reference Guide

**Production-grounded reference for the GBuzz CLI**

Based on source code: `/Users/lovellfelix/projects/grenadianbuzz/cli`

---

## Table of Contents

1. [Overview](#overview)
2. [Global Architecture](#global-architecture)
3. [Global Options](#global-options)
4. [Configuration](#configuration)
5. [Core Commands](#core-commands)
   - [crawl](#crawl)
   - [notify](#notify)
   - [archive](#archive)
   - [discover](#discover)
   - [fix-streams](#fix-streams)
   - [task-runner](#task-runner)
6. [Common Workflows](#common-workflows)
7. [Logging & Debugging](#logging--debugging)
8. [Error Handling](#error-handling)

---

## Overview

The GBuzz CLI is a production tool for:
- **Content crawling**: RSS feeds, WordPress sites, HTML obituary sources, radio stations
- **Notifications**: Newsletters, feedback requests, seasonal greetings
- **Station management**: Discovery, validation, and automatic stream repair
- **Data archiving**: Expired analytics retention and cleanup
- **Task scheduling**: Continuous or one-time task execution with monitoring

**Binary name**: `gbuzz` (not `gb`)

**Entry point**: `/Users/lovellfelix/projects/grenadianbuzz/cli/gbuzz/cli.py`

---

## Global Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      gbuzz CLI                              │
│  (Global options: --log-level, -v, --timestamp, --config)  │
└─────────────────────────────────────────────────────────────┘
           │
           ├─── crawl
           │    ├─ rss
           │    ├─ wordpress
           │    ├─ station
           │    ├─ station-discover
           │    └─ obituary-html
           │
           ├─── notify
           │    ├─ newsletter
           │    ├─ feedback
           │    ├─ newyear
           │    └─ christmas
           │
           ├─── archive
           │    └─ run
           │
           ├─── discover
           │    ├─ feeds
           │    └─ stations
           │
           ├─── fix-streams
           │
           └─── task-runner
```

---

## Global Options

Applied to all commands:

```bash
--log-level LEVEL              # Logging level: DEBUG, INFO, WARNING, ERROR
                               # (overrides -v flags)

-v, -vv, -vvv                  # Verbose mode:
                               # -v = INFO (general info)
                               # -vv = VERBOSE (detailed operations, level 15)
                               # -vvv = DEBUG (full debugging)

--timestamp / --no-timestamp   # Enable/disable timestamp in logs
                               # (default: enabled)

--json-format                  # Output logs in JSON format
                               # Ideal for Kubernetes/container environments
                               # Includes pod/namespace metadata auto-detection

--config PATH                  # Path to YAML config file
                               # (default: ~/.config/gbuzz/config.yaml)
```

### Option Precedence

`--log-level` > `-v/-vv/-vvv` flags

```bash
# --log-level takes precedence
gbuzz --log-level DEBUG -v crawl rss  # Uses DEBUG, not INFO
```

---

## Configuration

### Environment Variables (Recommended)

```bash
export API_URL="https://api.example.com"
export API_CLIENT_KEY="your-secret-key"
```

### Configuration File: ~/.config/gbuzz/config.yaml

```yaml
# Required
API_URL: "https://api.example.com"
API_CLIENT_KEY: "your-secret-key"

# Optional HTTP configuration
HTTP_TIMEOUT: 30              # Read timeout in seconds
CONNECT_TIMEOUT: 10           # Connection timeout in seconds
HTTP_POOL_CONNECTIONS: 10     # Number of connection pools
HTTP_POOL_MAXSIZE: 20         # Max connections per pool
HTTP_KEEP_ALIVE: true         # Enable keep-alive on session

# Optional: Station discovery and fixing
STATION_DISCOVERY_ENABLED: true
STATION_DISCOVERY_COUNTRIES: "Grenada,Jamaica,Trinidad"
STATION_DISCOVERY_GENRES: "news,calypso,reggae"
STATION_DISCOVERY_LIMIT: 100
STATION_DISCOVERY_AUTO_VALIDATE: true
STATION_AUTO_FIX_ENABLED: true
STATION_AUTO_FIX_LIMIT: 50
STATION_AUTO_FIX_VERIFY: true
```

### Config Precedence

Environment variables > config file

If both are set, environment variables override the config file.

---

## Core Commands

### crawl

Crawl content from various sources with TTL (time-to-live) management.

**Purpose**: Periodically fetch fresh content; skip runs if TTL hasn't expired (unless `--now`)

**Generic crawlers** (registered from task registry):
- `rss` - RSS feed sources
- `wordpress` - WordPress REST API sources
- `station` - Validate existing radio stations
- `station-discover` - Discover new radio stations
- `obituary-html` - HTML obituary listings

**Usage**:
```bash
gbuzz crawl <crawler-name> [OPTIONS]
```

**Options**:
```
--ttl SECONDS              # Time-to-live between crawls (default: 21600 = 6 hours)
--now                      # Force crawl and skip TTL/hash checks
```

**Examples**:
```bash
# Crawl RSS feeds (use cache if TTL not expired)
gbuzz crawl rss

# Force crawl RSS regardless of TTL
gbuzz crawl rss --now

# Crawl with custom TTL (1 hour)
gbuzz crawl wordpress --ttl 3600

# Verbose crawling
gbuzz -vv crawl station --now

# JSON-format logs for containers
gbuzz --json-format crawl rss --now
```

### notify

Send notifications to users based on schedules.

**Purpose**: Email notifications (newsletters, feedback requests, seasonal greetings)

**Available notifications**:

#### newsletter
Send newsletters to inactive users
```bash
gbuzz notify newsletter [OPTIONS]

# Default schedule: Saturdays 9-11 AM (user's local timezone)
```

#### feedback
Request user feedback
```bash
gbuzz notify feedback [OPTIONS]

# Default schedule: Multiple times daily (user's local timezone)
```

#### newyear
New Year's greeting
```bash
gbuzz notify newyear [OPTIONS]

# Default schedule: New Year's Day 9 AM (user's local timezone)
```

#### christmas
Christmas greeting
```bash
gbuzz notify christmas [OPTIONS]

# Default schedule: Christmas Day 9 AM (user's local timezone)
```

**Options** (all notify commands):
```
--cron SCHEDULE            # Cron expression (e.g., "0 9 * * 1" = Monday 9 AM)
                           # Interpreted in user's local timezone
--grace-minutes MINS       # Grace period in minutes (default: varies by command)
--force                    # Force delivery, bypassing normal checks
--users-limit N            # Limit number of users to notify
```

**Examples**:
```bash
# Send newsletter now (bypassing normal conditions)
gbuzz notify newsletter --force

# Send feedback request with custom schedule (daily at 8 AM)
gbuzz notify feedback --cron "0 8 * * *"

# Limit to 100 users
gbuzz notify newsletter --users-limit 100 --force

# Christmas greeting (dry-run first to verify)
gbuzz -v notify christmas --force

# New Year with custom grace period
gbuzz notify newyear --force --grace-minutes 120
```

**Timezone Behavior**:
- Cron expressions are evaluated in each user's local timezone
- Grace period allows staggering notifications across time zones
- Use `--grace-minutes` to spread delivery over a range

### archive

Archive expired analytics data with retention policies.

**Purpose**: Clean up old analytics, maintain data retention compliance

**Usage**:
```bash
gbuzz archive run [OPTIONS]
```

**Options**:
```
--mode MODE                # latest (default) or all
                           # latest = archive latest batch only
                           # all = archive all expired entries
--retention MONTHS         # Retention period in months (default: 23)
--dry-run                  # Simulate without modifying
--force                    # Force archiving even if conditions not met
```

**Examples**:
```bash
# Preview archiving (dry-run)
gbuzz archive run --dry-run

# Archive latest batch only (default)
gbuzz archive run

# Archive all expired data with 18-month retention
gbuzz archive run --mode all --retention 18

# Verify then archive (dry-run first)
gbuzz archive run --dry-run --mode all
gbuzz archive run --mode all  # Run if dry-run looks good

# Production: archive with force flag
gbuzz archive run --mode all --force
```

### discover

Discover feeds and radio stations from various sources.

**Usage**:
```bash
gbuzz discover <subcommand> [OPTIONS]
```

#### discover feeds
Discover feed endpoints (RSS, Atom, JSON, WordPress) from a website

**Usage**:
```bash
gbuzz discover feeds <URL> [OPTIONS]
```

**Options**:
```
--min-confidence VALUE     # Minimum confidence to include (0.0-1.0)
--format FORMAT            # json (default) or table
```

**Examples**:
```bash
# Discover feeds from a news site
gbuzz discover feeds https://example.com --min-confidence 0.7

# All feeds (low confidence threshold)
gbuzz discover feeds https://example.com --min-confidence 0.0
```

#### discover stations
Discover radio stations from Radio Browser API

**Usage**:
```bash
gbuzz discover stations [OPTIONS]
```

**Options**:
```
--country COUNTRY          # Filter by country name (e.g., "Grenada", "Jamaica")
--search NAME              # Search by station name
--tag TAG                  # Search by tag/genre (e.g., "calypso", "reggae")
--caribbean                # Get all Caribbean stations
--limit N                  # Max results (default: 50)
--validate                 # Validate stream URLs after discovery
--format FORMAT            # json (default) or table
```

**Examples**:
```bash
# Find Grenada stations
gbuzz discover stations --country Grenada

# Search by name
gbuzz discover stations --search "Nation"

# All Caribbean stations
gbuzz discover stations --caribbean

# Validate and show as table
gbuzz discover stations --caribbean --validate --format table

# Search by tag with limit
gbuzz discover stations --tag calypso --limit 20

# Verbose discovery with validation
gbuzz -v discover stations --country Jamaica --validate
```

### fix-streams

Validate and repair station stream URLs using fallback methods.

**Purpose**: Detect broken streams and repair using fallback strategies:
1. Check station homepage for stream links
2. Search Radio Browser API
3. Scrape TuneIn for replacement URL

**Usage**:
```bash
gbuzz fix-streams [OPTIONS]
```

**Options**:
```
--validate-only            # Only validate; don't fix
--dry-run                  # Show what would be fixed without applying
--limit N                  # Max stations to process (default: 100)
--format FORMAT            # json (default) or table
```

**Examples**:
```bash
# Check stream health (validation only)
gbuzz fix-streams --validate-only

# Preview repairs without applying
gbuzz fix-streams --dry-run

# Fix broken streams
gbuzz fix-streams

# Process only 10 stations
gbuzz fix-streams --limit 10

# Verbose output with table format
gbuzz -vv fix-streams --format table

# Dry-run first, then apply
gbuzz fix-streams --dry-run
gbuzz fix-streams  # After reviewing output
```

**Output Format** (JSON):
```json
[
  {
    "station_id": "uuid",
    "station_name": "Station Name",
    "old_url": "https://old-stream.url",
    "new_url": "https://new-stream.url",
    "fixed": true,
    "method": "radio_browser",  // or "homepage", "tunein", "already_valid"
    "error": null
  }
]
```

### task-runner

Run multiple tasks in continuous or one-time mode.

**Purpose**: Automate repeating work (crawling, notifications, archiving) at scale

**Usage**:
```bash
gbuzz task-runner [OPTIONS]
```

**Options**:
```
--tasks NAMES              # Comma-separated task names (e.g., "rss,wordpress,station")
--all                      # Run all available tasks
--once                     # Run once and exit (no loop)
--interval SECS            # Seconds between iterations (default: 300 = 5 min)
--force                    # Force execution (bypass TTL checks)
--ttl SECS                 # Task freshness TTL in seconds (default: 10800 = 3 hours)
--metrics-port PORT        # Prometheus metrics server port
```

**Examples**:
```bash
# Run all tasks continuously (every 5 minutes)
gbuzz task-runner --all

# Run specific tasks once
gbuzz task-runner --tasks rss,wordpress --once

# Run all tasks every 10 minutes
gbuzz task-runner --all --interval 600

# Production: with metrics and JSON logging
gbuzz --json-format task-runner --all --interval 300 --metrics-port 8080

# Force execution (skip TTL checks) for specific tasks
gbuzz task-runner --tasks rss,station --once --force

# Verbose execution
gbuzz -vv task-runner --tasks rss,wordpress --once
```

**Available tasks** (dynamically registered):
- All `crawl` commands: `rss`, `wordpress`, `station`, `station-discover`, `obituary-html`
- All `notify` commands: `newsletter`, `feedback`, `newyear`, `christmas`
- `archive_task` - Archive analytics

**Metrics** (when `--metrics-port` is set):
Prometheus metrics available at `http://localhost:<port>/metrics`
- Task execution duration
- Task throughput
- Error counts

---

## Common Workflows

### Daily Editorial Workflow

```bash
#!/bin/bash

# 1. Fetch fresh content (all sources)
gbuzz task-runner --tasks rss,wordpress,station --once --force

# 2. Check station health
gbuzz fix-streams --dry-run

# 3. Review logs
# (logs already in stdout from above commands)
```

### Continuous Background Operation (Production)

```bash
# Run all tasks every 5 minutes with Prometheus metrics
gbuzz --json-format task-runner --all --interval 300 --metrics-port 8080 &

# Monitor metrics
curl http://localhost:8080/metrics | grep gbuzz
```

### Kubernetes Deployment

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gbuzz-tasks
spec:
  containers:
  - name: gbuzz
    image: gbuzz:latest
    command: ["gbuzz", "--json-format", "task-runner", "--all", "--metrics-port", "8080"]
    env:
    - name: API_URL
      value: "https://api.example.com"
    - name: API_CLIENT_KEY
      valueFrom:
        secretKeyRef:
          name: gbuzz-secrets
          key: api-key
    ports:
    - containerPort: 8080
```

### Monthly Data Cleanup

```bash
# 1. Preview what would be archived
gbuzz archive run --dry-run --mode all

# 2. If satisfied, run archiving
gbuzz archive run --mode all --retention 23

# 3. Verify completion
gbuzz -v archive run --force
```

### Discover and Fix Radio Stations

```bash
# 1. Discover new Caribbean stations
gbuzz discover stations --caribbean --validate --limit 20

# 2. Fix broken streams in existing database
gbuzz fix-streams --dry-run

# 3. Apply repairs
gbuzz fix-streams
```

### Scheduled Notifications (Cron)

```cron
# Daily newsletter at 9 AM
0 9 * * * gbuzz notify newsletter --force

# Weekly feedback request (Monday 10 AM)
0 10 * * 1 gbuzz notify feedback --force

# Holiday greetings (via task-runner)
0 9 25 12 * gbuzz notify christmas --force
0 9 1 1 * gbuzz notify newyear --force
```

---

## Logging & Debugging

### Log Levels

```bash
# Default: WARNING level (only errors and warnings)
gbuzz crawl rss

# Info level (general status messages)
gbuzz -v crawl rss
# Same as:
gbuzz --log-level INFO crawl rss

# Verbose level (detailed operation logs)
gbuzz -vv crawl rss

# Debug level (full debugging information)
gbuzz -vvv crawl rss
# Same as:
gbuzz --log-level DEBUG crawl rss
```

### Log Format

**Standard output**:
```
2026-03-23 10:15:30 [INFO] [gbuzz] Starting RSS crawl
2026-03-23 10:15:31 [INFO] [gbuzz] Fetched 12 articles from source 'National News'
```

**JSON format** (with `--json-format`):
```json
{
  "timestamp": "2026-03-23T10:15:30Z",
  "level": "INFO",
  "logger": "gbuzz.crawl.rss",
  "message": "Fetched 12 articles",
  "pod": "gbuzz-tasks-abc123",
  "namespace": "production"
}
```

### Debugging Specific Commands

```bash
# Verbose RSS crawl
gbuzz -vv crawl rss --now

# Debug station discovery
gbuzz -vvv discover stations --country Grenada

# Full debug of task-runner
gbuzz -vvv task-runner --tasks rss --once

# Timestamp-free logs (for CI/CD)
gbuzz --no-timestamp crawl rss
```

---

## Error Handling

### Exit Codes

```
0       Success
1       Generic error (API, network, file system)
2       Usage/validation error (bad arguments)
```

### Common Errors

**Error**: `API_URL not configured`
```bash
# Solution: Set environment variable or config file
export API_URL="https://api.example.com"
# OR create ~/.config/gbuzz/config.yaml
```

**Error**: `Connection timeout`
```bash
# Solution: Increase timeout in config
# ~/.config/gbuzz/config.yaml
HTTP_TIMEOUT: 60        # Increase from default 30s
CONNECT_TIMEOUT: 20     # Increase from default 10s
```

**Error**: `TTL not expired` (when running crawlers)
```bash
# Solution: Use --now to force crawl
gbuzz crawl rss --now

# Or use task-runner --force
gbuzz task-runner --tasks rss --once --force
```

**Error**: `Failed to validate station stream`
```bash
# Check specific stream manually
gbuzz -vv fix-streams --limit 1

# View fallback strategy in debug logs
gbuzz -vvv fix-streams --dry-run
```

---

## Design Patterns

### Idempotent Operations

All crawlers are idempotent: running twice with same TTL produces same results
- Duplicate detection via content hash
- No side effects (read-only or safe writes)

### Graceful Degradation

If a source fails:
- Other sources continue
- Partial results returned
- Error logged but doesn't halt task-runner

### Dry-Run First Pattern

```bash
# Always dry-run mutating operations first
gbuzz archive run --dry-run
# Review output...
gbuzz archive run  # Only after verification
```

### Timeout Safety

All network operations have timeouts (default 30s read, 10s connect)
- Configurable via config file
- Override with `--config` flag

---

## Production Checklist

- [ ] Config file created with valid API credentials
- [ ] API_URL and API_CLIENT_KEY verified working
- [ ] First crawl tested with `--now` flag
- [ ] Archive dry-run verified before production archive
- [ ] Task-runner tested with `--once` before continuous operation
- [ ] Metrics port configured and accessible (if using Prometheus)
- [ ] Log rotation configured (for timestamp-enabled logs)
- [ ] Error alerting set up (parse logs or monitor metrics)
