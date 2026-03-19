---
name: standup
description: Generate standup update from git activity, session memory, GitHub, and tasks. Use when the user says "standup", "daily update", or asks for a summary of recent work.
---

# Standup Generator

Generate a standup update by aggregating work activity from multiple sources.

## Instructions

### 1. GATHER DATA (parallel)

Run all in parallel:

**Session Memory:**
- `retrieve_session_context({ session_id: "<git-basename>", limit: 50 })` — recent work context
- `task_board({ include_done: true })` — completed and in-progress tasks

**GitHub (cross-repo):**
- `gh search commits --author=@me --committer-date=">$(date -v-1d +%Y-%m-%d)" --json sha,commit,repository --limit 20`
- `gh pr list --author=@me --state=all --limit 10 --json number,title,state,repository,createdAt,mergedAt`
- `gh search issues --author=@me --updated=">$(date -v-1d +%Y-%m-%d)" --json number,title,state,repository`

**Calendar:**
- `bash ~/.config/opencode/scripts/apple-calendar.sh today --json`

**Graceful degradation:** If `gh` is unavailable or rate-limited, use session memory only. If Apple scripts fail, skip calendar context.

### 2. AGGREGATE

Merge commits, PRs, tasks, and session contexts into a unified timeline:
- Group by time period: yesterday vs today vs planned
- De-duplicate across sources (same PR might appear in commits and PRs)
- Note repos touched

### 3. PRESENT

```
Yesterday:
- [Completed items — from commits, PRs, closed tasks]
- [Progress on ongoing items — from session context]
- [Repos: repo1, repo2]

Today:
- [Planned items — from in-progress tasks, calendar]
- [Key meetings — from calendar]

Blockers:
- [Dependencies, technical blockers]
- None — if no blockers
```

### 4. ADAPT based on arguments

- `"detailed"` — include commit SHAs, PR numbers, file changes
- `"for #channel"` — Slack-friendly, more concise, single paragraph per section
- `"since Monday"` — adjust date range: `--committer-date=">$(date -v-Mon +%Y-%m-%d)"`
- `"weekly"` — aggregate entire week, group by project/repo

### 5. STORE (silent)

Store standup in session-memory:
```
store_session_context({
  session_id: "<git-basename>",
  context_type: "workflow",
  key: "standup-YYYY-MM-DD",
  value: "<standup-content>"
})
```

### 6. LEARN (silent)

If user edits or provides feedback on format, track `style:standup_format` preference.

## Rules

- Do NOT narrate data gathering. Present the final standup directly.
- Default to yesterday-to-today, concise format.
- If no work activity is found, say so honestly rather than fabricating.
