---
name: knowledge-graph
description: Build and maintain a lightweight knowledge graph in the work knowledgebase.
version: 0.1.0
portable: false
tags: [knowledge-graph, notes, memory, opencode]
---

What I do

* Link work notes into a navigable graph using `add_relation`
* Add structured learnings as `add_observation` entries
* Use `build_context` and `get_backlinks` to traverse and validate the graph
* Keep the graph sparse and high-signal (avoid link spam)

When to use me

* After completing meaningful work (design decisions, incident learnings, runbook updates)
* When a topic feels fragmented across multiple notes
* When you want better retrieval: "show me everything related to X"

Rules

* Work only: store graph links in the knowledgebase (not Apple Notes)
* Prefer canonical relation types used consistently:
  - `related_to`, `depends_on`, `implements`, `runbook_for`, `explains`, `decision_for`, `risk_for`, `example_of`
* Add 1-3 relations and 1-3 observations per session maximum
* Use idempotency keys for write tools when available to avoid duplicates
