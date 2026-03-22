---
name: api-docs
description: Store, query, and sync Swagger/OpenAPI specs in SQLite for cross-project API reference.
version: 0.1.1
portable: false
tags: [api, openapi, swagger, docs, opencode]
---

What I do

* Import Swagger/OpenAPI specs from files or URLs into SQLite database
* Query endpoints by path, method, tag, or full-text search
* Sync API docs when specs are updated (hash-based change detection)
* Provide type definitions and request/response schemas on demand
* Enable client-side development without copy-pasting API docs

When to use me

* When building clients that consume APIs with Swagger/OpenAPI specs
* To keep API documentation in sync across frontend/backend projects
* When you need to query specific endpoints or schema definitions
* Before making API changes to understand current contract

Commands

* `/import-api <spec_id> <source>` - Import spec from file or URL
* `/sync-api <spec_id>` - Re-sync after API changes
* `/sync-api --all` - Sync all imported APIs
* `/list-apis` - List all imported API specs with metadata

MCP Tools

> **Note:** All tools are accessed via the `session-memory` MCP namespace.
> In OpenCode, prefix each tool name with `session-memory_`, for example:
> `session-memory_store_api_spec`, `session-memory_get_api_endpoints`.

* `session-memory_store_api_spec` - Store full OpenAPI spec (JSON/YAML)
* `session-memory_get_api_endpoints` - Query endpoints by path pattern, method, or tag
* `session-memory_get_api_schema` - Get request/response schema for an endpoint
* `session-memory_get_api_endpoint_detail` - Full endpoint details with parameters
* `session-memory_list_api_specs` - List all stored API specs with versions
* `session-memory_search_api_endpoints` - Full-text search across endpoints
* `session-memory_delete_api_spec` - Remove outdated API spec

Example workflow

```bash
# Import APIs from your projects
/import-api user-service ./backend/openapi.json
/import-api billing-api https://billing.example.com/swagger.json

# Query when building client
session-memory_get_api_endpoints --spec_id "user-service" --path_pattern "/users%"
session-memory_get_api_schema --spec_id "user-service" --schema_name "CreateUserRequest"

# After API changes, sync to pick up updates
/sync-api --all
```
