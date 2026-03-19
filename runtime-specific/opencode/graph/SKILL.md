---
name: graph
description: Work item graph - track issues, PRs, JIRA tickets and their relationships across sessions. Use when the user says "graph", "track this", "what was I working on", or asks about work item status.
---

# Work Item Graph

Track and query engineering work items (GitHub issues, PRs, JIRA tickets) and their relationships using session-memory graph tools.

## Instructions

### If no arguments: ask what they want

```
Do you want to:
1) Track a work item (issue, PR, JIRA ticket)
2) View work status dashboard
3) Link items (issue -> PR, JIRA -> GitHub)
4) Check what you were working on
```

### Track a work item

Use session-memory MCP:
```
upsert_node({
  domain: "engineering",
  item_type: "github_issue" | "github_pr" | "jira_ticket",
  item_id: "<repo#number>" | "<PROJ-123>",
  title: "<title>",
  status: "open" | "in_progress" | "in_review" | "merged" | "closed",
  metadata: { "url": "...", "repo": "..." }
})
```

### View dashboard

```
work_status_dashboard({})
```

Present results as:
- **Issues needing PRs** - items without linked PRs
- **Open PRs** - status (draft/in_review/approved)
- **JIRA <-> GitHub links** - cross-system relationships
- **Recently updated** - last 7 days of activity

### Link items

```
link_nodes({
  from_domain: "engineering",
  from_item_type: "github_issue",
  from_item_id: "<repo#123>",
  to_domain: "engineering",
  to_item_type: "github_pr",
  to_item_id: "<repo#456>",
  relationship: "has_pr"
})
```

Relationship types: `has_pr`, `implements`, `blocks`, `related_to`, `parent_of`

### Resume context ("what was I working on")

1. `work_status_dashboard({})` - get all tracked items
2. `retrieve_session_context({ session_id: "<git-basename>", limit: 10 })` - recent session state
3. Present a prioritized list of active items with their current status

### Update status

```
update_node_status({
  domain: "engineering",
  item_type: "github_pr",
  item_id: "<repo#456>",
  status: "merged"
})
```

## Rules

- Silently upsert items discovered during other workflows (morning briefing, standup).
- Use `domain: "engineering"` for all work items.
- Item IDs follow format: `repo#number` for GitHub, `PROJ-123` for JIRA.
