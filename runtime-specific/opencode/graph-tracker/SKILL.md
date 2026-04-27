---
name: graph-tracker
description: "Persistent graph of nodes and relationships — engineering (GitHub issues, PRs, Jira) AND personal (family, reminders, events, notes). Enables work continuity, standup dashboards, personal knowledge graphs, and cross-session resumption."
version: 0.1.0
portable: false
tags: [github, jira, issues, prs, tracking, graph, continuity, standup, personal, family, notes, reminders]
applies_to: [workflow, engineering, personal-assistant, standup, personal]
---

# Graph Tracker Skill

## What I Do

Persistent **graph-based tracking** of any entity and its relationships:

### Engineering Domain

- **Track work items**: GitHub issues, PRs, Jira tickets, branches, commits
- **Link relationships**: PR fixes issue, branch implements ticket, Jira linked to PR
- **Dashboard views**: Open issues without PRs, active PRs, Jira status at a glance
- **Graph traversal**: Follow any item to see its full context (issue -> branch -> PR -> Jira)

### Personal Domain

- **Track people**: Family members, contacts, colleagues
- **Track events**: Calendar events, appointments, reminders, deadlines
- **Track notes**: Personal notes, observations, ideas linked to people or projects
- **Track goals**: Health goals, financial targets, learning objectives

### Cross-Domain

- **Cross-session continuity**: Resume work or personal context across sessions
- **Unified graph**: Engineering and personal nodes can link to each other

## When to Use Me

Automatically engage this skill when:

### Engineering Triggers

- User creates or references a GitHub issue or PR
- User mentions a Jira ticket (`PROJ-123`)
- User asks "what am I working on?", "what's open?", "show my PRs"
- User runs `/standup`, `/morning`, or `/work-status`
- User creates a branch for an issue
- User says "continue working on..." or "pick up where I left off"

### Personal Triggers

- User mentions family members, children, spouse
- User asks about reminders, upcoming events, or deadlines
- User wants to track personal notes or observations about someone/something
- User asks "what do I need to remember about X?"
- User wants to link personal context to work items

## Architecture

### Storage

All data lives in the shared session-memory SQLite database (`~/.agents/memory/session.db`, with legacy fallback to `~/.opencode/sessions/session.db`):

```
graph_nodes   - Nodes of any type (engineering, personal, etc.)
graph_edges   - Directed relationships between nodes
graph_tags    - Searchable tags/labels per node
```

This is **not** session-scoped — items persist across sessions for continuity.

### Domains

Every node has a `domain` field for namespace filtering:

| Domain        | Use Case                                            |
| ------------- | --------------------------------------------------- |
| `engineering` | GitHub issues, PRs, Jira tickets, branches, commits |
| `personal`    | Personal notes, goals, ideas                        |
| `family`      | Family members, family events, reminders            |
| `health`      | Health goals, appointments, medications             |
| `finance`     | Financial goals, budgets, transactions              |
| _(custom)_    | Any string — the domain is free-text                |

### Node Types (Free-Text)

No hardcoded enum — any string is valid. Common examples:

#### Engineering

| Type           | External ID Format | Example                  |
| -------------- | ------------------ | ------------------------ |
| `github_issue` | `owner/repo#42`    | `anomalyco/opencode#123` |
| `github_pr`    | `owner/repo#99`    | `anomalyco/opencode#456` |
| `jira_ticket`  | `PROJ-123`         | `MYPROJ-789`             |
| `branch`       | `feature/xyz`      | `fix/login-bug`          |
| `commit`       | `abc1234`          | Short SHA                |

#### Personal

| Type       | External ID Format         | Example                       |
| ---------- | -------------------------- | ----------------------------- |
| `person`   | `child-a`                  | `child-a`, `spouse`, `mom`    |
| `reminder` | `reminder-YYYY-MM-DD-desc` | `reminder-2024-03-15-dentist` |
| `event`    | `event-YYYY-MM-DD-desc`    | `event-2024-06-15-birthday`   |
| `note`     | `note-desc`                | `note-school-preferences`     |
| `goal`     | `goal-desc`                | `goal-reading-list-2024`      |

### Relationship Types (Free-Text)

No hardcoded enum — any string is valid. Common examples:

#### Engineering

| Relationship             | Meaning                  | Example                       |
| ------------------------ | ------------------------ | ----------------------------- |
| `pr_for_issue`           | PR addresses this issue  | PR #99 -> Issue #42           |
| `fixes`                  | Resolves the target      | PR #99 fixes Issue #42        |
| `implements`             | Implements the target    | Branch implements Jira ticket |
| `branch_for_issue`       | Branch created for issue | `fix/login` -> Issue #42      |
| `linked_to`              | General link             | PROJ-123 linked_to #42        |
| `blocks`                 | Blocks the target        | Issue #10 blocks Issue #20    |
| `relates_to`             | Related items            | Issue #10 relates_to #11      |
| `parent_of` / `child_of` | Hierarchy                | Epic parent_of Story          |

#### Personal

| Relationship             | Meaning                                   | Example                        |
| ------------------------ | ----------------------------------------- | ------------------------------ |
| `parent_of` / `child_of` | Family hierarchy                          | user parent_of child-a         |
| `sibling_of`             | Siblings                                  | child-a sibling_of child-b     |
| `reminder_for`           | Reminder about a person/thing             | reminder reminder_for child-a  |
| `belongs_to`             | Ownership/association                     | note belongs_to child-a        |
| `scheduled_for`          | Event scheduling                          | event scheduled_for 2024-03-15 |
| `resource_for`           | Useful reference for a person/event/topic | school resource_for child-a    |
| `related_to`             | General association                       | note related_to goal           |

## Apple Notes Integration

- Personal notes in Apple Notes should prefer hashtags over folder taxonomy.
- Reuse existing hashtags when possible; avoid creating close duplicates for the same person, family topic, event, or resource.
- When an Apple Notes item is mirrored into the graph, carry its hashtags into node tags or `metadata_json` for better traversal and filtering.
- Use a stable note external ID format such as `apple-note:<title-slug>` if the note lacks a stronger identifier.
- Prefer a compact shared vocabulary across linked items, for example: `#family`, `#person-alice`, `#health`, `#event-birthday`, `#resource-school`.

## MCP Tools Reference

The graph-specific node tools are not currently exposed in this OpenCode runtime. Use the general `session-memory_*` context tools to persist graph-shaped records until the dedicated graph API is available again.

### `session-memory_store_session_context` — Store graph-shaped records

```typescript
// Engineering item keyed by external identifier
session-memory_store_session_context({
  session_id: "graph-tracker",
  context_key: "graph:engineering:github_issue:owner/repo#42",
  context_value: JSON.stringify({
    title: "Fix login validation",
    status: "open",
    repo: "owner/repo",
    url: "https://github.com/owner/repo/issues/42",
    tags: ["bug", "auth", "login"],
    links: [{ relationship: "linked_to", target: "graph:engineering:jira_ticket:PROJ-123" }]
  })
})

// Personal item keyed the same way
session-memory_store_session_context({
  session_id: "graph-tracker",
  context_key: "graph:family:person:child-a",
  context_value: JSON.stringify({
    title: "Alice",
    status: "active",
    tags: ["family", "child"],
    metadata: { birthday: "2018-05-20", school: "Springfield Elementary" }
  })
})
```

### `session-memory_retrieve_session_context` — Read graph records

```typescript
// Recent graph entries
session-memory_retrieve_session_context({
  session_id: "graph-tracker",
  limit: 50,
})
```

### `session-memory_query_memory` — Search graph records

```typescript
// Search for a person, issue, or tag label in stored graph JSON
session-memory_query_memory({ query: "graph child-a Alice health", limit: 10 })
```

### `session-memory_store_interaction` — Record relationship updates

```typescript
session-memory_store_interaction({
  session_id: "graph-tracker",
  role: "system",
  content: "Linked owner/repo#99 to owner/repo#42 with fixes relationship",
  metadata: JSON.stringify({
    source: "graph:engineering:github_pr:owner/repo#99",
    target: "graph:engineering:github_issue:owner/repo#42",
    relationship: "fixes"
  })
})
```

## Workflow Integration Patterns

### Engineering: When creating a PR

```
1. session-memory_store_session_context  → graph:engineering:github_pr:<repo#pr>
2. session-memory_store_session_context  → graph:engineering:github_issue:<repo#issue> (if not tracked)
3. session-memory_store_interaction      → relationship metadata such as fixes or pr_for_issue
4. session-memory_store_session_context  → graph:engineering:branch:<branch-name>
```

### Engineering: During standup

```
1. session-memory_retrieve_session_context  → recent graph-tracker entries
2. session-memory_query_memory              → search for repo, issue, PR, or Jira identifiers when needed
3. Present: issues needing PRs, PRs needing review, Jira status, with title and status for each item
4. For any recommendation, include: why now, evidence/signals, and the immediate next step
5. End with a single strongest recommendation using `Best first task`, `Why this first`, and `Do this now`
6. If stored data lacks titles, status, owners, or next steps, mark the item as needing lookup instead of presenting it as a confident recommendation
```

### Personal: Family member tracking

```
1. session-memory_store_session_context  → graph:family:person:child-a
2. session-memory_store_session_context  → graph:family:reminder:reminder-dentist
3. session-memory_store_interaction      → reminder_for relationship metadata
4. session-memory_store_session_context  → graph:family:note:note-school-preferences
5. session-memory_store_interaction      → belongs_to relationship metadata (note → person)
```

### Personal: "What do I need to remember about Alice?"

```
1. session-memory_query_memory → search for graph child-a Alice and related reminder IDs
2. session-memory_retrieve_session_context → inspect the stored records and relationship entries
3. Present: all reminders, events, notes linked to Alice
```

## Auto-Tracking Triggers

Agents should **silently** track items when they observe:

| Trigger                     | Action                                                        |
| --------------------------- | ------------------------------------------------------------- |
| `gh issue create` output    | `session-memory_store_session_context(graph:engineering:github_issue:...)`        |
| `gh pr create` output       | `session-memory_store_session_context(graph:engineering:github_pr:...)` + relationship log |
| Branch checkout for issue   | `session-memory_store_session_context(graph:engineering:branch:...)` + relationship log     |
| Jira ticket reference       | `session-memory_store_session_context(graph:engineering:jira_ticket:...)`                |
| PR merged notification      | Update stored graph record status via `session-memory_store_session_context(...)`         |
| User mentions family member | `session-memory_store_session_context(graph:family:person:...)`                           |
| User sets a reminder        | `session-memory_store_session_context(graph:family:reminder:...)` + relationship log      |

**Silent tracking**: Do not ask the user before tracking. Track items as a side-effect of normal operations. Only surface the graph when the user asks for it or during standup/dashboard views.

## Graph Visualization

When presenting the graph to the user, use ASCII art for clarity:

### Engineering

```
PROJ-123 (Jira: In Progress)
  └─ linked_to → owner/repo#42 (Issue: open)
       ├─ branch_for_issue ← fix/login-bug
       └─ pr_for_issue ← owner/repo#99 (PR: in_review)
```

### Personal

```
Alice (Person: active)
  ├─ reminder_for ← Dentist appointment (Reminder: pending)
  ├─ belongs_to ← School preferences (Note: active)
  ├─ scheduled_for ← Birthday party (Event: upcoming)
  └─ sibling_of ↔ Bob (Person: active)
```

## Data Hygiene

- **Deduplication**: use stable `graph:<domain>:<type>:<external-id>` keys so repeated writes replace the same tracked entity
- **Relationship cleanup**: if an item is no longer relevant, remove or overwrite both the stored record and any related interaction entries manually
- **Status sync**: rewrite the stored record when you observe changes
- **No auto-cleanup**: records persist until explicitly replaced or pruned
- **Domain filtering**: keep domain and type in the `context_key` so retrieval and search stay focused

## Security & Privacy

- All data stored locally in `~/.agents/memory/session.db`
- No external API calls from this skill — it only stores data
- Personal data (family names, appointments) stays local
- External lookups (GitHub, Jira) use existing tools (`gh` CLI, captain MCP)
