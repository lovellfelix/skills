---
name: google-docs
description: Use this skill when reading, writing, or searching Google Docs, Sheets, and Drive files from OpenCode.
version: 0.1.0
portable: false
tags: [google-docs, google-sheets, google-drive, opencode, work]
---

# Google Docs Skill

Use this skill when reading, writing, or searching Google Docs, Sheets, and Drive files.

## Work Machine Activation

- This is a work-machine-only skill.
- It is linked only when the local work-machine flag file exists: `~/.work-env-skills`.
- The runtime linker can use a custom flag path via `SKILL_WORK_MACHINE_FLAG_FILE=/path/to/flag`.

## Prerequisites

- Captain MCP server must be enabled (work laptop with `~/.work-env-skills` signal file)
- Run `captain setup google` to configure authentication
- Check status: `captain auth check`

## Available MCP Tools

### Google Docs

| Tool | Description |
|------|-------------|
| `read_google_docs_document` | Read content from a Google Doc |
| `write_to_google_docs_document` | Write content with multiple operations |
| `create_google_docs_document` | Create a new Google Doc |
| `search_google_docs_text` | Search for text and return matching positions |
| `read_google_docs_comments` | Read comments from a document |
| `add_google_docs_comment` | Add a comment to a document |
| `reply_to_google_docs_comment` | Reply to an existing comment |
| `insert_local_image_to_google_doc` | Append a local image to the doc |

### Google Sheets

| Tool | Description |
|------|-------------|
| `read_google_sheets_by_id` | Read content from a spreadsheet |
| `write_google_sheets_by_id` | Write values to a spreadsheet |
| `create_google_sheets_spreadsheet` | Create a new spreadsheet |
| `list_google_sheets_tabs` | List all sheets (tabs) with gid, title, index |

### Google Drive

| Tool | Description |
|------|-------------|
| `search_google_drive` | Search for files and folders |
| `move_google_drive_file` | Move file/folder to different location |

## Document IDs

Extract document ID from URL:

```text
Google Doc:   https://docs.google.com/document/d/DOCUMENT_ID/edit
Google Sheet: https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit
```

The ID is the long alphanumeric string between `/d/` and `/edit`.

## Workflow Examples

### Read a design doc for context

```text
1. search_google_drive - Find doc by name/keyword
2. read_google_docs_document - Get full content
3. Use content for context in coding task
```

### Update a project tracker

```text
1. read_google_sheets_by_id - Get current data
2. write_google_sheets_by_id - Update cells with new status
```

### Review and comment on a doc

```text
1. read_google_docs_document - Read content
2. read_google_docs_comments - See existing discussion
3. add_google_docs_comment - Add feedback on specific section
```

### Create meeting notes

```text
1. create_google_docs_document - Create new doc with title
2. write_to_google_docs_document - Add structure (headings, bullets)
```

## Access Levels

Setup options:

```bash
# Full read/write access (default)
captain setup google

# Read-only access (safer)
captain setup google --read

# Clear and re-authenticate
captain setup google --clear
captain setup google
```

## Extended Tools (Namespace: google.slides)

Enable Google Slides tools:

```bash
captain add google.slides
```

## Authentication

```bash
# Setup (opens browser for OAuth)
captain setup google

# Check status
captain auth check

# Troubleshooting
captain setup google --clear
captain setup google
```

## Tips

- Document IDs are stable - bookmark them for frequently accessed docs
- Use `search_google_drive` to find docs by name rather than hardcoding IDs
- Comments are tied to text ranges - use `search_google_docs_text` to find the right position
- Sheets operations work on ranges like `A1:B10` or named ranges
