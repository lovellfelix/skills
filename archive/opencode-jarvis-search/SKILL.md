---
name: jarvis-search
description: Use this skill to search LinkedIn codebases with Jarvis from OpenCode.
metadata:
  version: 0.1.0
  portable: false
  tags: [jarvis, code-search, linkedin, opencode, work]
---

# Jarvis Code Search Skill

Use this skill when you need to search LinkedIn's codebase using Jarvis code search.

## Work Machine Activation

- This is a work-machine-only skill.
- It is linked only when the local work-machine flag file exists: `~/.work-env-skills`.
- The runtime linker can use a custom flag path via `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`.

## When to Use

- Searching for code patterns across LinkedIn's monorepo
- Finding files by name, content, or language
- Downloading matching files for local analysis
- Exploring how APIs or libraries are used across the codebase

## CLI Tool: `files-matching`

### Syntax

```bash
files-matching [OPTIONS] "QUERY" /path/to/destination
```

### Query Syntax

| Pattern | Description | Example |
|---------|-------------|---------|
| `filename:NAME` | Search by filename | `filename:build.gradle` |
| `repo:REPO` | Search within repository | `repo:voyager-ios` |
| `lang:LANGUAGE` | Filter by language | `lang:python` |
| `path:PATH` | Search by file path | `path:src/main` |
| Free text | Search file contents | `import pandas` |

Queries can be combined:

```bash
files-matching "filename:build.gradle repo:my-multiproduct" /tmp/results
files-matching "lang:python import tensorflow" /tmp/tf-examples
```

### Options

| Option | Description |
|--------|-------------|
| `-c, --clean` | Delete destination before download |
| `-f, --force` | Force delete without confirmation |
| `--dv-group <group>` | DataVault group for auth |

### Examples

```bash
# Find all Dockerfiles
files-matching "filename:Dockerfile" /tmp/dockerfiles

# Find Python files using a specific library
files-matching "lang:python from linkedin.ml import" /tmp/ml-examples

# Clean destination and force overwrite
files-matching -c -f "filename:config.yaml" /tmp/configs
```

## Captain MCP Integration

If the `captain` MCP server is enabled, you can also use the `unified_context_search` tool for semantic search across:

- Jarvis code search
- Confluence/Wiki
- JIRA issues

Run `captain setup search` to configure all integrations.

## Authentication

- Requires valid TrustBridge/DataVault credentials
- Run `captain setup jarvis` to configure authentication
- Check status with `captain auth check`
