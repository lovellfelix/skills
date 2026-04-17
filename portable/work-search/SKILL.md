---
name: work-search
description: Search internal work systems (JIRA, Confluence, code, Slack, wiki, Google Docs) using captain's unified_context_search and domain-specific tools via the env_mcp tool. Use when the user asks about internal docs, tickets, code in other repos, team wikis, Slack discussions, or any LinkedIn internal knowledge.
---

# Work Search — Internal Knowledge via Captain

Search across LinkedIn internal systems using captain MCP server tools through the `env_mcp` Pi tool.

## When to Use

- Questions about internal systems, services, or architecture
- Looking up JIRA tickets, Confluence pages, or Google Docs
- Searching code in other repositories (Jarvis code search)
- Finding Slack discussions or internal documentation
- Any query about LinkedIn engineering tools, processes, or best practices

## Prerequisites

- Captain MCP server must be enabled: check with `/mcp`
- Auth must be current: check with `/mcp auth`, fix with `/mcp setup`

## How to Search

### 1. Unified Context Search (best for general questions)

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
