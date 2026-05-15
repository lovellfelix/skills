---
name: jira-workflow
description: Use this skill when reading, creating, searching, and updating JIRA issues from OpenCode.
metadata:
  version: 0.1.0
  portable: false
  tags: [jira, atlassian, workflow, opencode, work]
---

# JIRA Workflow Skill

Use this skill when working with JIRA issues - reading, creating, updating, and searching tickets.

## Work Machine Activation

- This is a work-machine-only skill.
- It is linked only when the local work-machine flag file exists: `~/.work-env-skills`.
- The runtime linker can use a custom flag path via `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`.

## Prerequisites

- Captain MCP server must be enabled (work laptop with `~/.work-env-skills` signal file)
- Run `captain setup atlassian` to configure authentication
- Check status: `captain auth check`

## Available MCP Tools

When captain MCP is connected, these tools are available:

### Reading Issues

| Tool | Description |
|------|-------------|
| `get_jira_issue` | Get detailed information about a JIRA issue |
| `get_jira_issue_comments` | Get all comments for a JIRA issue |
| `search_jira_issues` | Search using JQL with cursor-based pagination |

### Modifying Issues

| Tool | Description |
|------|-------------|
| `create_jira_issue` | Create a new JIRA issue |
| `update_jira_issue` | Update an existing JIRA issue (status, assignee, fields) |
| `add_jira_comment` | Add a comment to a JIRA issue |
| `add_jira_attachment` | Upload a local file as attachment |
| `link_jira_issue` | Link issue to another issue or external URL |

## Common JQL Queries

```text
# My open issues
assignee = currentUser() AND status != Done

# Issues in current sprint
sprint in openSprints() AND assignee = currentUser()

# Recently updated by me
updatedBy = currentUser() AND updated >= -7d

# High priority bugs
priority = High AND type = Bug AND status != Done

# Issues mentioning a keyword
text ~ "memory leak"

# Issues in specific project
project = MYPROJ AND status = "In Progress"
```

## Workflow Examples

### Update ticket status after completing work

```text
1. get_jira_issue - Get current issue details
2. add_jira_comment - Document what was done
3. update_jira_issue - Change status to "Done" or "In Review"
```

### Create ticket from bug investigation

```text
1. create_jira_issue - Create bug ticket with:
   - Summary: Brief description
   - Description: Stack trace, reproduction steps
   - Priority: Based on severity
   - Labels: relevant tags
2. link_jira_issue - Link to related tickets
```

### Sprint standup prep

```text
1. search_jira_issues - Query: "assignee = currentUser() AND sprint in openSprints()"
2. For each issue: get_jira_issue_comments to see recent activity
```

## Extended Tools (Namespace: jira)

Enable extended JIRA tools:

```bash
captain add jira
```

Additional tools:

- Issue transitions (workflow state changes)
- Work logging
- Issue history
- Filter management
- Unlinking issues

## CLI Alternative

For quick queries without MCP:

```bash
# Open JIRA issue in browser
open "https://linkedin.atlassian.net/browse/ISSUE-123"
```

## Authentication

```bash
# Setup (one-time)
captain setup atlassian

# Check status
captain auth check

# Re-authenticate if expired
captain setup atlassian --clear
captain setup atlassian
```
