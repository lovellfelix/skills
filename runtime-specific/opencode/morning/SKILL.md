---
name: morning
description: Morning briefing — calendar, reminders, weather, GitHub issues, priorities. Use when the user says "morning", "briefing", "start my day", or asks what's on today.
---

# Morning Briefing

Generate a morning briefing by gathering data in parallel, then synthesizing into a prioritized plan.

## Instructions

### 1. GATHER CONTEXT (parallel, silent)

Run all of these in parallel:

**Always:**
- `date +%u` and `date +%H` (determine weekday/weekend and time of day)
- Load preferences via session-memory MCP: `get_user_preferences({ user_id: "default" })` — look for `planning:work_context` and `identity:zip_code`
- `bash ~/.config/opencode/scripts/apple-calendar.sh today --json`
- `bash ~/.config/opencode/scripts/apple-reminders.sh overdue --json`
- `bash ~/.config/opencode/scripts/apple-reminders.sh today --json`
- `bash ~/.config/opencode/scripts/apple-notes-safe.sh read-context`

**If after 16:00:**
- `bash ~/.config/opencode/scripts/apple-calendar.sh tomorrow --json`

**If ZIP code found in preferences:**
- `bash ~/.config/opencode/scripts/weather.sh today --zip "$ZIP" --json`

**If work mode** (user explicitly asks OR `planning:work_context` is `"true"`):
- `gh search issues --assignee @me --state open --sort updated --order desc --limit 50 --json number,title,url,repository,labels,updatedAt,createdAt,commentsCount`
- Session-memory: `task_board({ include_done: false })`

### 2. DETERMINE MODE

- **Weekend** (day 6-7): personal mode, skip work sections
- **Holiday** (all-day "Holiday" calendar event): personal mode
- **Default**: personal mode — only include work if user explicitly asked or preference is set
- Side projects are NOT work

### 3. SYNTHESIZE

Use an Agent (model: haiku) to prioritize: top 3 priorities with rationale, time block suggestions, deadline callouts, and blockers.

### 4. PRESENT

```
Good morning. Here's the shape of today.

Calendar
[Events in time order, concise time ranges]

Work (only if work mode)
Priorities
1) [Most important] — [why now] — [time block]
2) [Second] — [context]
3) [Third]

GitHub (only if work mode + data exists)
1) [repo#number] [title] — [next action]
2) ...

Personal
Top items
1) ...
2) ...

Weather (only if data exists)
[Temp/high/low, anything notable]

One suggestion
[Single tactical suggestion for the day]
```

**Omit any section that has no data.** No "(unavailable)" placeholders.

### 5. STORE (silent)

- Store today's plan in session-memory: `store_session_context({ session_id: "<git-basename>", context_type: "workflow", key: "daily-plan-YYYY-MM-DD", value: "..." })`
- Sync to Apple Notes: `bash ~/.config/opencode/scripts/apple-notes-safe.sh sync-context '<json>'`

### 6. LEARN (silent)

Track any observed patterns (meeting-heavy days, focus patterns) via `track_user_preference`.

## Rules

- Do NOT narrate intermediate steps. Gather silently, present the final briefing.
- Do NOT ask permission to store. Just store.
- Gather data in the main agent, not subagents (scripts need local access).
- If any source fails (MCP server unreachable, script error, gh not authenticated), skip that section silently — don't fail the whole briefing.
- If session-memory MCP is unavailable, skip preference loading and plan storage. Use known defaults from auto-memory instead.
- If knowledgebase MCP is unavailable, skip KB lookups entirely.
