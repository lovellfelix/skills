---
name: grenadianbuzz-api
description: API design and PRD workflow for GrenadianBuzz products.
version: 0.1.0
portable: true
tags: [api, openapi, prd, product, grenadianbuzz]
---

# GrenadianBuzz API Skill

## What this skill does

- Turns rough product ideas into a practical API PRD.
- Produces API-first specifications with OpenAPI-ready contracts.
- Keeps scope clear for mobile app, admin tools, and partner integrations.

## Use when

- You need to design or refine a GrenadianBuzz API endpoint set.
- You are writing a PRD that includes backend contracts and data models.
- You need to align product requirements, API behavior, and rollout gates.

## Do not use when

- The task is only UI styling with no API or data contract changes.
- You already have approved contracts and only need implementation.

## Inputs expected

- Product goal and user persona.
- Existing entities/endpoints (if any).
- Required business rules, compliance constraints, and timeline.

## Workflow

1. Clarify objective, users, and business outcomes.
2. Define bounded scope and explicit non-goals.
3. Model entities and relationships with clear ownership.
4. Design endpoint contracts (request, response, errors, auth).
5. Add acceptance criteria with measurable API behavior.
6. Add rollout plan, observability, and backward compatibility notes.

## Core patterns

- API-first: contract and error model before implementation details.
- PRD to API traceability: each requirement maps to endpoint behavior.
- Safe evolution: versioning, deprecation windows, idempotency where needed.
- Operational readiness: logs, metrics, and alert thresholds are defined early.

## GrenadianBuzz domain defaults

- Model content-first workflows (stories, posts, media, reactions, comments).
- Include audience segments and regional context when defining filters.
- Prioritize feed latency, moderation controls, and creator analytics outputs.
- Treat trust and safety requirements as first-class API constraints.

## Output structure

- PRD summary with goals, constraints, and success metrics.
- Entity model table and state transitions.
- Endpoint matrix with auth, payloads, and failure modes.
- OpenAPI draft sections and example JSON payloads.
- Rollout checklist with migration and monitoring plan.

## Examples and reference

- See `templates/api-prd-template.md` for a reusable draft template.
- See `reference/grenadianbuzz-domain-checklist.md` for domain checks.
