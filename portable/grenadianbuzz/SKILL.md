---
name: grenadianbuzz
description: Use when working on GrenadianBuzz features, architecture, or operational tasks across any surface (API, Android app, CLI, website, dashboard, CDN, newsletter).
version: 0.4.0
portable: false
personal_machine_only: true
tags: [grenadianbuzz, product, mobile, api, backend, frontend, architecture]
---

# GrenadianBuzz Product & Engineering Skill

Integrated product and technical guidance across all GrenadianBuzz surfaces. Turns product ideas into coherent feature designs spanning mobile, backend, and admin tooling with API-first specifications.

## Use when

- Designing a feature across multiple surfaces (API + Android + dashboard).
- Specifying Android endpoint consumers or mobile-specific payload shapes.
- Planning API changes that affect mobile clients, CLI, or admin tools.
- Aligning product requirements with mobile architecture and backend contracts.
- Designing newsletter or engagement strategy for diaspora segments.

## Do not use when

- Task is only UI styling with no API or data contract changes.
- Approved contracts exist and only implementation is needed.
- Task is purely mobile-only with no backend integration.

## Inputs expected

- Product goal and user persona (diaspora segment, engagement type, creator/user focus).
- Existing entities/endpoints (if any).
- Required platforms: API, Android, CLI, dashboard, website (specify which).
- Business rules, compliance constraints, timeline.

## Workflow

1. **Clarify objective** — Which surfaces are involved? What's the user journey end-to-end?
2. **Define bounded scope** — Specific endpoints, mobile screens, CLI commands, admin features.
3. **Model entities and relationships** — Shared across all surfaces with clear ownership.
4. **Design contracts** — API payloads, mobile request/response, error modes.
5. **Plan surface integration** — How does Android consume the API? CLI command structure? Dashboard analytics?
6. **Add acceptance criteria** — Measurable behavior across platforms.
7. **Add rollout and monitoring** — Backward compatibility, feature flags for mobile, analytics hooks.

## Core patterns

- **API-First**: REST contracts before implementation. Mobile clients drive payload shapes. `/v1`, `/v2`, `/v3` with 90-day deprecation windows.
- **Mobile-Aware Payloads**: Minimize JSON size (diaspora on slower networks). Support summary vs full representations. Idempotency keys for mutations.
- **Cross-Platform Consistency**: Identical error responses across API, Android SDK, CLI. Auth JWT format shared.
- **Trust & Safety**: Moderation workflows `flag → review → approved/removed`. Audit trails on all moderation actions. Explicit `is_flagged`, `moderation_status` in payloads.
- **Diaspora-Aware**: Timezone-aware notifications (UTC-5 to UTC+0). Segments: USA 45%, Canada 20%, UK 15%, Caribbean 8%, other.

## Output structure

- Product spec with goals, constraints, success metrics.
- Entity model and state transitions (API, mobile, CLI contexts).
- API endpoint matrix with auth, payloads, failure modes.
- Mobile integration guide (API consumption, screen designs, error handling).
- CLI command specification (if applicable).
- Analytics and event schema.
- OpenAPI draft sections and example JSON payloads.
- Rollout checklist with backward compatibility, feature flags, monitoring.

## Reference files

| File | Use for |
|------|---------|
| `templates/quick-reference.md` | Fast checklist and examples for API design |
| `templates/api-prd-template.md` | Comprehensive PRD template (14 sections) |
| `reference/grenadianbuzz-api-patterns.md` | Production patterns, versioning, moderation, engagement |
| `reference/grenadianbuzz-domain-checklist.md` | Design validations across surfaces |
| `reference/grenadianbuzz-android-context.md` | Kotlin, JetpackCompose, API integration, offline-first |
| `reference/grenadianbuzz-cli-guide.md` | Command patterns, admin workflows, automation scripts |
| `reference/grenadianbuzz-dashboard-guide.md` | Moderation, analytics, creator tooling |
| `reference/grenadianbuzz-website-guide.md` | Public pages, SEO/accessibility, engagement patterns |
| `INDEX.md` | Start-here map for API, Android, CLI, dashboard, and website |

## Personal Machine Activation

This skill is personal-machine-only and stays disabled unless explicitly allowlisted.

- Add `grenadianbuzz` to `~/.personal-machine-skills.txt` (one skill name per line).
- Re-run your runtime link sync after updating the allowlist.
