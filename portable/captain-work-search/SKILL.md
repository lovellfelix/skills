---
name: captain-work-search
description: Use Captain for work-domain search across JIRA, Confluence, Google surfaces, and Jarvis code search after checking local repo and work notes first. Best for Pi-safe guidance on when and how to use Captain as a fallback.
version: 0.1.0
portable: true
tags: [captain, jarvis, jira, confluence, google, work, portable]
---

# Captain Work Search

Use Captain for work-domain search only after checking the local repository, repo-native tools, and work notes first.

## Work Machine Activation

- This is a work-machine-only skill.
- It is linked only when the local work-machine flag file exists: `~/.work-env-skills`.
- The runtime linker can use a custom flag path via `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`.

## Use when

- You need internal work context not present in the current repository.
- You need JIRA, Confluence, Google Docs/Drive, Slack, or Jarvis code search.
- You need to search across multiple internal sources and do not know the exact home yet.
- You want a Pi-safe decision rule for Captain vs local search.
- You want to adapt an existing LinkedIn Claude plugin workflow into Pi/shared work skills.

## Do not use when

- The answer is likely in the current repository.
- The answer is likely in local work notes or runbooks.
- The task is mutating external systems and the user has not asked for that explicitly.
- A domain-specific local skill or playbook already covers the task better.

## Decision order

1. Search the current repository first.
2. Search work notes and runbooks second.
3. Use Captain third, as a fallback.
4. Keep Captain read-oriented unless the user explicitly wants a write action.

## What Captain is good for

- **JIRA**: issue lookup, filters, board/sprint context.
- **Confluence**: wiki search and page reads.
- **Google surfaces**: Docs, Sheets, Drive.
- **Jarvis**: internal code search across other repositories.
- **Unified search**: one query across code, wiki, JIRA, Slack, and docs.

## Recommended search patterns

### 1) General work question

Use unified search when the right source is unclear.

Examples:
- architecture question spanning docs and code
- "where is this owned"
- "has anyone discussed this before"

Good pattern:
- start broad with unified context search
- narrow to a source only after you know where the signal is

### 2) JIRA or Confluence question

Use source-specific search when the source is obvious.

Examples:
- specific issue key or project triage
- known wiki page or runbook lookup

#### JIRA patterns

Use JIRA-specific lookup when you need:
- a ticket by key
- issue lists via JQL
- comments, history, blockers, or sprint context

Preferred progression:
1. if you have an issue key, read the exact issue
2. if you do not have a key, search with JQL or unified search scoped to JIRA
3. only use write actions after explicit user intent

Typical JIRA reads:
- search issues: `search_jira_issues`
- get exact issue: `get_jira_issue`
- get comments: `get_jira_issue_comments`
- inspect links, subtasks, or history when needed via other Captain JIRA tools

In Pi, common paths are:
- `work_context_search query="<question>" sources=["jira"]`
- `env_mcp action=call server=captain toolName=search_jira_issues argumentsJson={"jql":"project = PROJ AND status != Done"}`
- `env_mcp action=call server=captain toolName=get_jira_issue argumentsJson={"issue_key":"PROJ-123"}`

Safe default:
- keep JIRA usage read-only unless the user explicitly asks to create, edit, comment, transition, or link issues

### 3) Jarvis code search

Use Jarvis when the code is likely outside the current repo.

Start with:
- natural-language or simple term search via unified search scoped to Jarvis
- direct Jarvis syntax only when you need precision

Prefer this progression:
1. broad Jarvis search
2. refine by repository, file type, class, method, or path
3. fetch an exact file only after identifying a strong match

Useful Jarvis filters:
- `reponame:` repository filter
- `filetype:` language or extension filter
- `f:` filename filter
- `p:` filepath filter
- `c:` class declaration
- `m:` method declaration
- `code:` source text
- `cu:` class usage

## Pi-safe runtime notes

### In Pi

Use this order:
1. repo search tools
2. `work_knowledgebase`
3. `work_skill_reference` when the question is about existing LinkedIn Claude plugin skills or workflows
4. `work_context_search`
5. `env_mcp`

Pi-specific rules:
- prefer local skills, playbooks, and repo-native tools first
- treat Captain as fallback-only
- if the exact Captain tool name is unclear, list tools first
- mutating Captain actions require explicit user intent and confirmation
- do not ask for tokens or craft auth headers manually

Typical Pi flow:
- `work_skill_reference action=list_skills plugin="nimbus-agent"`
- `work_skill_reference action=search query="jira workflow" plugin="linkedin-dev-workflow"`
- `work_context_search query="<question>"`
- `work_context_search query="<question>" sources=["jira"]`
- `work_context_search query="<question>" sources=["jarvis"]`
- `env_mcp action=list_tools server=captain`
- `env_mcp action=call server=captain toolName=... argumentsJson=...`

### In Claude/OpenCode-like runtimes

Equivalent Captain calls may appear as direct MCP tools such as:
- `unified_context_search`
- `jarvis_codesearch`
- `jarvis_get_file`
- `search_jira_issues`
- `search_confluence_content`
- Google Docs/Drive tools

The policy stays the same:
- local first
- Captain second
- writes only with explicit intent

## Query strategy

### Unified search first when source is unclear

Best for:
- service ownership questions
- migration context
- previous design decisions
- "find all context on X"

### JIRA-specific search when ticket state is the target

Best for:
- bug or task lookup by key
- board or sprint triage
- finding related issues by JQL
- checking assignee, status, comments, or issue history

### Jarvis-specific search when code is the target

Best for:
- implementation examples in other repos
- method/class discovery
- finding config or data model patterns
- comparing how multiple teams solve the same problem

### Exact file retrieval only after narrowing

Use exact file fetch only when you already know:
- repository
- scm
- filepath

## Safety and auth

- Treat Captain auth as host-managed runtime setup.
- If auth is missing, direct the user to the runtime's Captain setup flow.
- Prefer read-only workflows by default.
- Ask before creating, updating, commenting, or deleting anything external.

## Good outcomes

- You searched local sources before Captain.
- You used unified search when the source was unclear.
- You used JIRA-specific reads when ticket state or workflow context was the target.
- You used Jarvis only when repo-local search was insufficient.
- You narrowed from broad search to precise file retrieval.
- You kept external actions read-only unless the user explicitly wanted mutation.
