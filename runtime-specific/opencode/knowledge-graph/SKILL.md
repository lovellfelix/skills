---
name: knowledge-graph
description: Build and maintain a lightweight knowledge graph in the work knowledgebase. Use when connecting related work notes, capturing design decisions, or surfacing complex relationships across projects.
version: 0.1.1
portable: false
tags: [knowledge-graph, notes, memory, opencode]
---

What I do

* Link work notes into a navigable graph using `session-memory_link_nodes`
* Add structured learnings as node observations via `session-memory_upsert_node`
* Use `session-memory_query_nodes` to traverse and surface related context
* Keep the graph sparse and high-signal (avoid link spam)

When to use me

* After completing meaningful work (design decisions, incident learnings, runbook updates)
* When a topic feels fragmented across multiple notes
* When you want better retrieval: "show me everything related to X"

Rules

* Work only: store graph links in session-memory (not Apple Notes)
* Prefer canonical relation types used consistently:
  - `related_to`, `depends_on`, `implements`, `runbook_for`, `explains`, `decision_for`, `risk_for`, `example_of`
* Add 1-3 relations and 1-3 observations per session maximum
* Use `external_id` as the node identifier field (not `item_id`)

> **Note:** The knowledgebase MCP was removed in March 2026. All graph operations
> now go through the `session-memory` MCP. For full graph tracking workflows, see
> the `graph-tracker` skill.
