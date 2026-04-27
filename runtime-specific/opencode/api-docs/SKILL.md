---
name: api-docs
description: "Use when building API clients, keeping API contracts in sync across projects, or querying endpoint details. Stores and queries Swagger/OpenAPI specs in SQLite for cross-project API reference."
version: 0.1.1
portable: false
tags: [api, openapi, swagger, docs, opencode]
---

# API Docs

Store, query, and sync Swagger/OpenAPI specs in SQLite for cross-project API reference.

## What I do

- Import Swagger/OpenAPI specs from files or URLs into SQLite database
- Query endpoints by path, method, tag, or full-text search
- Sync API docs when specs are updated (hash-based change detection)
- Provide type definitions and request/response schemas on demand
- Enable client-side development without copy-pasting API docs

## When to use

- When building clients that consume APIs with Swagger/OpenAPI specs
- To keep API documentation in sync across frontend/backend projects
- When you need to query specific endpoints or schema definitions
- Before making API changes to understand current contract

## Commands

- `/import-api <spec_id> <source>` - Import spec from file or URL
- `/sync-api <spec_id>` - Re-sync after API changes
- `/sync-api --all` - Sync all imported APIs
- `/list-apis` - List all imported API specs with metadata

## MCP Tools

> **Note:** Tools use the `mcp_` prefix in OpenCode.

- `mcp_store_api_spec` — Store full OpenAPI spec (JSON/YAML)
- `mcp_get_api_endpoints` — Query endpoints by path pattern, method, or tag
- `mcp_get_api_schema` — Get request/response schema for an endpoint
- `mcp_get_api_endpoint_detail` — Full endpoint details with parameters
- `mcp_list_api_specs` — List all stored API specs with versions
- `mcp_search_api_endpoints` — Full-text search across endpoints
- `mcp_delete_api_spec` — Remove outdated API spec

## Example workflow

```python
# Import a spec
mcp_store_api_spec(spec_id="user-service", spec_json=<openapi.json contents>)

# Query endpoints
mcp_get_api_endpoints(spec_id="user-service", path_pattern="/users%")

# Get a schema
mcp_get_api_schema(spec_id="user-service", schema_name="CreateUserRequest")

# Verify import
mcp_list_api_specs()  # confirm "user-service" in results
```

## Constraints

- Spec IDs must be unique across all imported APIs
- Large specs are stored as-is; consider filtering before import
- Hash-based sync only detects content changes; semantic changes require manual re-import