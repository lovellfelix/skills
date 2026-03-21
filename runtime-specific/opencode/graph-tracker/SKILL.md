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

| Domain | Use Case |
|--------|----------|
| `engineering` | GitHub issues, PRs, Jira tickets, branches, commits |
| `personal` | Personal notes, goals, ideas |
| `family` | Family members, family events, reminders |
| `health` | Health goals, appointments, medications |
| `finance` | Financial goals, budgets, transactions |
| *(custom)* | Any string — the domain is free-text |

### Node Types (Free-Text)

No hardcoded enum — any string is valid. Common examples:

#### Engineering
| Type | External ID Format | Example |
|------|-------------------|---------|
| `github_issue` | `owner/repo#42` | `anomalyco/opencode#123` |
| `github_pr` | `owner/repo#99` | `anomalyco/opencode#456` |
| `jira_ticket` | `PROJ-123` | `MYPROJ-789` |
| `branch` | `feature/xyz` | `fix/login-bug` |
| `commit` | `abc1234` | Short SHA |

#### Personal
| Type | External ID Format | Example |
|------|-------------------|---------|
| `person` | `child-a` | `child-a`, `spouse`, `mom` |
| `reminder` | `reminder-YYYY-MM-DD-desc` | `reminder-2024-03-15-dentist` |
| `event` | `event-YYYY-MM-DD-desc` | `event-2024-06-15-birthday` |
| `note` | `note-desc` | `note-school-preferences` |
| `goal` | `goal-desc` | `goal-reading-list-2024` |

### Relationship Types (Free-Text)

No hardcoded enum — any string is valid. Common examples:

#### Engineering
| Relationship | Meaning | Example |
|-------------|---------|---------|
| `pr_for_issue` | PR addresses this issue | PR #99 -> Issue #42 |
| `fixes` | Resolves the target | PR #99 fixes Issue #42 |
| `implements` | Implements the target | Branch implements Jira ticket |
| `branch_for_issue` | Branch created for issue | `fix/login` -> Issue #42 |
| `linked_to` | General link | PROJ-123 linked_to #42 |
| `blocks` | Blocks the target | Issue #10 blocks Issue #20 |
| `relates_to` | Related items | Issue #10 relates_to #11 |
| `parent_of` / `child_of` | Hierarchy | Epic parent_of Story |

#### Personal
| Relationship | Meaning | Example |
|-------------|---------|---------|
| `parent_of` / `child_of` | Family hierarchy | user parent_of child-a |
| `sibling_of` | Siblings | child-a sibling_of child-b |
| `reminder_for` | Reminder about a person/thing | reminder reminder_for child-a |
| `belongs_to` | Ownership/association | note belongs_to child-a |
| `scheduled_for` | Event scheduling | event scheduled_for 2024-03-15 |
| `resource_for` | Useful reference for a person/event/topic | school resource_for child-a |
| `related_to` | General association | note related_to goal |

## Apple Notes Integration

- Personal notes in Apple Notes should prefer hashtags over folder taxonomy.
- Reuse existing hashtags when possible; avoid creating close duplicates for the same person, family topic, event, or resource.
- When an Apple Notes item is mirrored into the graph, carry its hashtags into node tags or `metadata_json` for better traversal and filtering.
- Use a stable note external ID format such as `apple-note:<title-slug>` if the note lacks a stronger identifier.
- Prefer a compact shared vocabulary across linked items, for example: `#family`, `#person-alice`, `#health`, `#event-birthday`, `#resource-school`.

## MCP Tools Reference

### `upsert_node` — Create or update a graph node

```typescript
// Engineering example
upsert_node({
  domain: "engineering",
  item_type: "github_issue",
  external_id: "owner/repo#42",
  title: "Fix login validation",
  status: "open",
  repo: "owner/repo",
  url: "https://github.com/owner/repo/issues/42",
  metadata_json: '{"labels":["bug","auth"],"assignee":"user"}',
  tags: "bug,auth,login",
})

// Personal example
upsert_node({
  domain: "family",
  item_type: "person",
  external_id: "child-a",
  title: "Alice",
  status: "active",
  metadata_json: '{"birthday":"2018-05-20","school":"Springfield Elementary","grade":"1st"}',
  tags: "family,child",
})

// Reminder example
upsert_node({
  domain: "family",
  item_type: "reminder",
  external_id: "reminder-2024-03-15-dentist",
  title: "Alice dentist appointment",
  status: "pending",
  metadata_json: '{"date":"2024-03-15","time":"14:00","location":"Dr. Smith"}',
  tags: "health,appointment",
})
```

### `link_nodes` — Create a relationship

```typescript
// Engineering: PR fixes issue
link_nodes({
  source_type: "github_pr",
  source_external_id: "owner/repo#99",
  target_type: "github_issue",
  target_external_id: "owner/repo#42",
  relationship: "fixes",
})

// Personal: reminder for child
link_nodes({
  source_type: "reminder",
  source_external_id: "reminder-2024-03-15-dentist",
  target_type: "person",
  target_external_id: "child-a",
  relationship: "reminder_for",
})
```

### `query_nodes` — Search and filter

```typescript
// All open PRs (engineering domain)
query_nodes({ domain: "engineering", item_type: "github_pr", status: "open" })

// All family members
query_nodes({ domain: "family", item_type: "person" })

// All pending reminders
query_nodes({ item_type: "reminder", status: "pending" })

// Search by title
query_nodes({ search: "Alice" })

// By tag
query_nodes({ tag: "health" })
```

### `get_node_graph` — Traverse relationships

```typescript
// See everything connected to a person
get_node_graph({
  item_type: "person",
  external_id: "child-a",
  depth: 2,
})
// Returns: person node + reminders, events, notes linked to them

// See everything connected to an issue
get_node_graph({
  item_type: "github_issue",
  external_id: "owner/repo#42",
  depth: 2,
})
// Returns: issue + branch + PR + Jira ticket
```

### `work_status_dashboard` — Engineering standup view

```typescript
// Full engineering dashboard (filters to domain='engineering')
work_status_dashboard({})

// Filtered by repo
work_status_dashboard({ repo: "owner/repo" })
```

### `update_node_status` — Status change

```typescript
// Engineering
update_node_status({
  item_type: "github_pr",
  external_id: "owner/repo#99",
  status: "merged",
})

// Personal
update_node_status({
  item_type: "reminder",
  external_id: "reminder-2024-03-15-dentist",
  status: "completed",
})
```

### `remove_node` — Delete node and edges

```typescript
remove_node({
  item_type: "reminder",
  external_id: "reminder-2024-03-15-dentist",
})
```

## Workflow Integration Patterns

### Engineering: When creating a PR

```
1. upsert_node  → domain: engineering, type: github_pr
2. upsert_node  → domain: engineering, type: github_issue (if not tracked)
3. link_nodes   → pr_for_issue or fixes relationship
4. upsert_node  → domain: engineering, type: branch + branch_for_pr
```

### Engineering: During standup

```
1. work_status_dashboard  → get engineering picture
2. Present: issues needing PRs, PRs needing review, Jira status, with title and status for each item
3. For any recommendation, include: why now, evidence/signals, and the immediate next step
4. End with a single strongest recommendation using `Best first task`, `Why this first`, and `Do this now`
5. If dashboard data lacks titles, status, owners, or next steps, mark the item as needing lookup instead of presenting it as a confident recommendation
```

### Personal: Family member tracking

```
1. upsert_node  → domain: family, type: person, id: child-a
2. upsert_node  → domain: family, type: reminder, id: reminder-dentist
3. link_nodes   → reminder_for relationship
4. upsert_node  → domain: family, type: note, id: note-school-preferences
5. link_nodes   → belongs_to relationship (note → person)
```

### Personal: "What do I need to remember about Alice?"

```
1. get_node_graph → type: person, id: child-a, depth: 2
2. Present: all reminders, events, notes linked to Alice
```

## Auto-Tracking Triggers

Agents should **silently** track items when they observe:

| Trigger | Action |
|---------|--------|
| `gh issue create` output | `upsert_node(domain: engineering, type: github_issue)` |
| `gh pr create` output | `upsert_node(domain: engineering, type: github_pr)` + link |
| Branch checkout for issue | `upsert_node(domain: engineering, type: branch)` + link |
| Jira ticket reference | `upsert_node(domain: engineering, type: jira_ticket)` |
| PR merged notification | `update_node_status(merged)` |
| User mentions family member | `upsert_node(domain: family, type: person)` |
| User sets a reminder | `upsert_node(domain: family/personal, type: reminder)` + link |

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

- **Deduplication**: `upsert_node` uses `(item_type, external_id)` as unique key
- **Cascade deletes**: Removing a node removes all its edges and tags
- **Status sync**: Update status when you observe changes
- **No auto-cleanup**: Items persist until explicitly removed
- **Domain filtering**: Use `domain` to keep queries focused

## Security & Privacy

- All data stored locally in `~/.opencode/sessions/session.db`
- No external API calls from this skill — it only stores data
- Personal data (family names, appointments) stays local
- External lookups (GitHub, Jira) use existing tools (`gh` CLI, captain MCP)
