---
name: work-search
description: Search internal work systems (JIRA, Confluence, code, Slack, wiki, Google Docs) using Captain via Pi-safe tools such as work_context_search and env_mcp. Use when the user asks about internal docs, tickets, code in other repos, team wikis, Slack discussions, or any LinkedIn internal knowledge.
version: 0.1.0
portable: true
tags: [captain, jarvis, jira, confluence, google, slack, work, portable]
---

# Work Search — Internal Knowledge via Captain

One-line summary: Canonical skill for local-first, Captain-second internal work discovery across JIRA, Confluence, Slack, Google Docs, and cross-repo code.

Search across LinkedIn internal systems using captain MCP server tools through the `env_mcp` Pi tool.

## Canonical vs overlap

- Use this skill as the **canonical** entry for Captain-backed work discovery.
- `captain-work-search` is kept as a compatibility alias for existing prompts; both should route to the same local-first, Captain-second policy.

## When to Use

- Questions about internal systems, services, or architecture
- Looking up JIRA tickets, Confluence pages, or Google Docs
- Searching code in other repositories (Jarvis code search)
- Finding Slack discussions or internal documentation
- Any query about LinkedIn engineering tools, processes, or best practices

## Work Machine Activation

- This is a work-machine-only skill.
- It is linked only when the local work-machine flag file exists: `~/.work-env-skills`.
- The runtime linker can use a custom flag path via `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`.

## Prerequisites

- Captain MCP server must be enabled: check with `/mcp`
- Auth must be current: check with `/mcp auth`, fix with `/mcp setup`
- Prefer repo-local search and `work_knowledgebase` before Captain
- When adapting LinkedIn Claude plugin workflows into Pi/shared skills, inspect local plugin docs first with `work_skill_reference`

## How to Search

### 1. Unified Context Search (best for general questions)

Prefer the Pi wrapper first:

```
work_context_search query="<natural language question>"
```

Raw Captain path when you need exact MCP arguments:

```
env_mcp action=call server=captain toolName=unified_context_search argumentsJson={"query": "<natural language question>"}
```

This searches across **all sources**: wiki, JIRA, code (Jarvis), Slack, and semantic code. Let captain decide which sources to query.

To narrow by source:
```
argumentsJson={"query": "<question>", "sources": ["wiki"]}
argumentsJson={"query": "<question>", "sources": ["jira"]}
argumentsJson={"query": "<question>", "sources": ["jarvis"]}
argumentsJson={"query": "<question>", "sources": ["slack"]}
```

### 2. JIRA (tickets, issues, sprints)

- **Search issues**: `toolName=search_jira_issues` with `argumentsJson={"jql": "project = PROJ AND status = Open"}`
- **Get issue**: `toolName=get_jira_issue` with `argumentsJson={"issue_key": "PROJ-123"}`
- **Create issue**: `toolName=create_jira_issue` (requires user confirmation)

### 3. Confluence (wiki pages)

- **Search**: `toolName=search_confluence_content` with `argumentsJson={"query": "topic"}`
- **Read page**: `toolName=get_confluence_page` with `argumentsJson={"page_id": "123456"}`

### 4. Code Search (Jarvis)

- **Search code**: `toolName=jarvis_codesearch` with `argumentsJson={"query": "f:*.java AND m:getUser"}`
- **Get file**: `toolName=jarvis_get_file` with `argumentsJson={"scm": "github", "repo": "repo-name", "filepath": "path/to/file.java"}`

### 5. Google Docs/Sheets

- **Search Drive**: `toolName=search_google_drive` with `argumentsJson={"query": "name contains 'design doc'"}`
- **Read doc**: `toolName=read_google_docs_document` with `argumentsJson={"document_id": "doc-id"}`

## Auth Errors

If you get auth errors, tell the user to run `/mcp setup` or `/mcp setup <service>` (e.g., `/mcp setup glean`, `/mcp setup atlassian`).

## Tool Discovery

If unsure which tool to use:
```
env_mcp action=list_tools server=captain
```

## Pi preference order

1. Search the current repository
2. Use `work_knowledgebase` for notes, runbooks, and prior work context
3. Use `work_skill_reference` when the task is about LinkedIn Claude plugins, work skills, or adapting existing internal workflows
4. Use `work_context_search` for common Captain-backed work lookup
5. Fall back to raw `env_mcp` calls when you need exact Captain tools or arguments

## Work skill adaptation flow

When the user asks how an internal workflow already works in Claude or LinkedIn plugins:

1. `work_skill_reference action=list_skills plugin="<plugin-name>"`
2. `work_skill_reference action=search query="<topic>" plugin="<plugin-name>"`
3. `work_skill_reference action=read identifier="<result path>"`
4. Adapt the workflow into Pi-safe tools such as `work_knowledgebase`, `work_context_search`, and `env_mcp`
