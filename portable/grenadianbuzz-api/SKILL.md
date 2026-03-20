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

### Content Model
- Articles/news from RSS feeds, news sources, and manual submissions
- Obituary listings with search and biographical metadata
- Radio stations (streaming metadata, geolocation bypass)
- Cultural events (Carnival, Independence Day, religious observances)
- User-generated content: comments, reactions, saved items, subscriptions

### Engagement & Analytics
- Interaction types: likes (👍), love (❤️), seasonal reactions (🕯️ 💖 🌹)
- Comment threads on articles, obituaries, and events
- Engagement metrics: view counts, comment counts, shares
- Near-real-time trending and top-users aggregation
- Moderation status tracking (review, approved, flagged, removed)

### User & Audience Segments
- Geographic segments: USA (45%), Canada (20%), UK (15%), Caribbean neighbors (8%), other
- Time-zone aware notifications (diaspora spread globally)
- Subscription tiers: free (basic), premium ($4.99/mo), family ($9.99/mo)
- Role-based access: user, admin, moderator, premium
- Content creator profiles with analytics dashboards

### Trust & Safety First
- Moderation workflows: flag → review → approved/removed
- Audit trails for moderation actions
- Explicit moderation status in payloads (is_flagged, moderation_status)
- Separate /moderation endpoints for admin operations
- Rate limiting and anti-abuse checks

### Feed & Discovery
- Personalized feed for authenticated users (/v1/users/feed)
- Public explore feed for discovery
- Cursor-based pagination for stability
- Sorting: published_at, trending, top_users
- Filtering: category, source, date range, sentiment

## Output structure

- PRD summary with goals, constraints, and success metrics.
- Entity model table and state transitions.
- Endpoint matrix with auth, payloads, and failure modes.
- OpenAPI draft sections and example JSON payloads.
- Rollout checklist with migration and monitoring plan.

## Examples and reference

- **Quick Start**: `templates/quick-reference.md` - Fast checklist and examples
- **Full Template**: `templates/api-prd-template.md` - Comprehensive PRD template with 14 sections
- **Domain Checklist**: `reference/grenadianbuzz-domain-checklist.md` - Domain-specific design validations
- **API Patterns**: `reference/grenadianbuzz-api-patterns.md` - Real production patterns, versioning, moderation, engagement

## Practical Examples

### New Creator Analytics Dashboard API
Your product team wants to launch creator insights:
```
Input: "Creators want to see follower growth trends and top posts"
Output: PRD with /creators/{id}/analytics endpoint, 
        time-range filters, response schema, 
        moderation gate (hide banned creators), 
        success metric (adoption in 2 weeks)
```

### Feed Personalization Enhancement
You're adding audience segment filtering:
```
Input: Mobile app needs to support "women 18-25 in US" segment definition
Output: Endpoint design /feed?segment_id=X with audience targeting rules,
        deprecated flat-feed fallback, metrics (CTR improvement),
        safety checks (prevent PII leakage)
```

### Content Moderation Workflow API
You need an admin tool to manage flagged content:
```
Input: Moderators need to bulk review, approve, or remove flagged posts
Output: /moderation/queue endpoint with filtering, batch actions,
        audit trail, role-based access, alert thresholds
```

### Partner Integration Webhook Events
Third-party apps need near-real-time content notifications:
```
Input: Partners want to react to new posts or comments
Output: Webhook contracts with signed payloads, retry strategy,
        sandbox vs. production, rate limits, test harness
```

## Troubleshooting

**"I'm designing an endpoint but don't know all the business rules yet"**
List them as "TBD pending legal/product review". Mark sections with confidence
levels (e.g., "High confidence" vs. "Needs validation"). Share the draft early
to get feedback, don't wait for perfection.

**"How do I balance API simplicity with GrenadianBuzz domain complexity?"**
Start simple: one filter, one sort option. Add flexibility only if two
customers actually ask for it. APIs are easier to expand than contract.

**"Should I include moderation in the API design itself?"**
Yes. Design it as a first-class concern, not an afterthought. Examples:
- Exclude banned creators from /feed by default
- Return is_flagged in post payloads
- Separate /moderation endpoints for admins

**"We need this API next week; do I really need an RFC?"**
A 1-page PRD (goal, entities, 4-5 endpoints, auth model) takes 2 hours.
It saves 10 hours of implementation rework. Always worth it.
