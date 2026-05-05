---
name: grenadianbuzz
description: Use when working on GrenadianBuzz features, architecture, or operational tasks across any surface (API, Android app, CLI, website, dashboard, docs).
version: 0.5.0
portable: true
personal_machine_only: true
tags: [grenadianbuzz, product, mobile, api, backend, frontend, architecture]
---

# GrenadianBuzz Product & Engineering Skill

---
## Live Repo Issue/PR Snapshot (as of 2026-05-03)

- **grenadianbuzz-android**: 40 open issues / 17 open PRs _(high PR traffic, significant issue tech debt; prioritize grounding in PR/issue reality)
- **grenadianbuzz.cli**: 18 open issues / 0 open PRs _(highest-impact pipeline/automation work, but *no* open PRs; Tier-1 work requires opening/maintaining reviewable PRs)_
- **api.grenadianbuzz.com**: 4 open issues / 4 open PRs _(critical for newsletter support, low issue/PR volume but high impact for CLI work)_
- **dashboard.grenadianbuzz.com**: 1 open issue / 4 open PRs _(only maintenance-level work, minimal new product feature velocity)_
- **grenadianbuzz.com**: 1 open issue / 5 open PRs _(site is in maintenance, not a focus except for bug/security/update work)_

### Routing Guidance & Repo Reality

- **Reality checks**: Always verify roadmap/priority against these live counts; any non-trivial work should map to open issues/PRs.
- **Prioritization**: Highest-impact engineering is the CLI newsletter pipeline (with corresponding API/Android dependencies); tier assignment and sequence should correspond directly to open issue/PR inventory.
- **Sequencing signals**: CLI has *zero* open PRs (need to raise work for leader/PR review); Android has many open PRs (*review bottlenecks can slow delivery*), API has key newsletter-support PRs, dashboard/website are maintenance-only—avoid roadmap expansion unless strictly necessary (e.g., inventory/tasks change).

---
Integrated product and technical guidance across GrenadianBuzz surfaces. API-first specifications and multi-surface feature coordination.

## Use when

- Designing features across multiple surfaces (API + Android + dashboard).
- Specifying Android endpoint consumers or mobile payload shapes.
- Planning API changes affecting mobile, CLI, or admin tools.
- Aligning product requirements with mobile architecture and backend contracts.
- Designing newsletter or diaspora engagement strategy.
- Prioritizing work across repos or coordinating multi-surface sprints.
- Verifying PRD/roadmap claims against actual repo/issue state.

## Workspace & Surfaces

GrenadianBuzz spans 7 product surfaces across 4 repositories:

| Surface | Repo | Type | Status |
|---------|------|------|--------|
| **Android App** | `grenadianbuzz-android` | Mobile (Kotlin, Compose) | Active |
| **API** | `api.grenadianbuzz.com` | Backend (FeathersJS, Node.js) | Production, active deprecation |
| **CLI** | `grenadianbuzz.cli` | Tooling (Python 3.8+) | Growth phase |
| **Dashboard** | `grenadianbuzz` (`web/dashboard`) | Admin (React, TailwindCSS) | Maintenance |
| **Website** | `grenadianbuzz` (`web/grenadianbuzz.com`) | Public (Nuxt/Vue) | Stable |
| **Docs** | `grenadianbuzz` (`docs/`) | Reference (Markdown, OpenAPI) | Living |
| **PRD** | `grenadianbuzz` (`docs/prd/`) | Planning (Markdown) | Source of truth |

## Canonical Issue Clusters

High-signal work grouped by surface and dependency. **Source of truth**: GitHub issues; canonical mapping only.

### Android App (`grenadianbuzz-android`)

| Issue | Scope | Status | Notes |
|-------|-------|--------|-------|
| **#254** | Google Sign-In implementation | Queued | Auth foundation |
| **#282** | Realm → Room database migration | Queued | Persistence foundation |
| **#287** | Testing & instrumentation expansion | Queued | Prerequisite for stability |
| **#255, #253** | Android 15 status bar issues | Open | OS compatibility |
| **Android #293** | UI redesign — cultural identity & engagement | Planned | Depends on Android #287, #282 complete |

**Recommended sequencing**: Android #254 → #282 → #287 → #255/#253 → #293.

### CLI (`grenadianbuzz.cli`)

| Issue Range | Scope | Status | Notes |
|-------------|-------|--------|-------|
| **#50–59** | AI newsletter pipeline (epic) | Active | Business value: monetization, engagement |
| **#48** | Metrics aggregation & reporting | Planned | Observability post-pipeline |
| **#47** | Environment variables documentation | Planned | Ops readiness |
| **#46** | Operational runbook | Planned | Runbook + recovery |
| **#49** | Dependency maintenance | Ongoing | Hygiene |

**Recommended sequencing**: #50–59 → #48 → #47/#46 → #49 (continuous).

### API (`api.grenadianbuzz.com`)

| Issue | Scope | Status | Notes |
|-------|-------|--------|-------|
| **API #293** | Deprecation warnings (v2→v3 migration) | Open | Backward compatibility |
| **#307** | Trending endpoint parameters | Planning | Engagement optimization |
| **#308** | Email template: `email-ai-newsletter.pug` | Blocked | Coordinate with CLI #50–59 |

**Recommended sequencing**: API #293 → #307 → #308 (coordinate with CLI).

### Dashboard & Website

| Surface | Status | Notes |
|---------|--------|-------|
| **Dashboard** | Maintenance | Renovate tracked; no active features |
| **Website** | Stable | Not a blocker for engagement/revenue |

## Multi-Surface Sequencing & Prioritization

When coordinating work across surfaces:

1. **Phase 1: Auth & Deprecation** (Android #254, API #293, CLI #50–59 setup)
   - Auth foundation enables all platform features
   - Deprecation warnings enable v2→v3 migration
   - Newsletter pipeline business value justifies early investment

2. **Phase 2: Persistence & Testing** (Android #282, #287, API #307)
   - Persistence foundation stabilizes mobile data handling
   - Test suite enables future stability and UI work
   - Trending tuning improves engagement

3. **Phase 3: Stability & Integration** (Android #255/#253, API #308, CLI #48)
   - OS compatibility fixes isolated; low dependency impact
   - Newsletter template finalizes CLI+API integration
   - Metrics tracking establishes observability baseline

4. **Phase 4: Enhancement** (Android #293, CLI #47/#46)
   - UI redesign deferred until foundation stable
   - Runbooks and env docs finalize ops readiness

## Execution Guidance

### PRD vs. Repo State Reconciliation

**Verify PRD claims**:
1. Check GitHub issue tracker — claims should reference open/in-progress issues
2. Validate surface coverage — if PRD claims an endpoint exists:
   - OpenAPI definition in `docs/` or API source
   - Integration tests pass in CI
   - Dashboard/Android consumers integrated and tested
3. Timeline claims — cross-check against issue milestones and PR activity
4. Deprecation timeline — match against API versioning strategy

**Red flags** (investigate if found):
- Issue marked closed but feature not in any surface (sync gap)
- PRD timeline doesn't match issue milestone (misalignment)
- API deprecation deadline passed but endpoint still active (enforcement gap)
- Android feature flagged "done" but dashboard/CLI not updated (incomplete integration)

### Validation Gates

Before shipping work across surfaces, validate:

- ✅ **API contract** — OpenAPI updated, example payloads, error cases documented
- ✅ **Android integration** — Retrofit models match API, error handling, offline-first tested
- ✅ **CLI consistency** — Commands follow existing patterns, help text, tests passing
- ✅ **Dashboard/Website** — UI consistent with design system, mobile-responsive, feature flags if needed
- ✅ **Docs** — API guide updated, examples work, architecture implications noted
- ✅ **Backward compatibility** — Deprecation warnings (if removing), migration path clear
- ✅ **Rollout readiness** — Feature flags for mobile, canary strategy, monitoring hooks

## Workflow

1. **Clarify scope** — Which surfaces involved? What's the user journey end-to-end?
2. **Bound the issue** — Specific endpoints, screens, CLI commands, admin features
3. **Model entities & relationships** — Shared across all surfaces with clear ownership
4. **Design contracts** — API payloads, mobile request/response, error modes
5. **Plan surface integration** — How does Android consume the API? CLI command structure? Dashboard analytics?
6. **Define acceptance criteria** — Measurable behavior across platforms
7. **Add rollout & monitoring** — Backward compatibility, feature flags, analytics hooks

## Core Patterns

- **API-First**: REST contracts before implementation. `/v1`, `/v2`, `/v3` with 90-day deprecation windows.
- **Mobile-Aware Payloads**: Minimize JSON size (diaspora on slower networks). Summary vs full representations. Idempotency keys for mutations.
- **Cross-Platform Consistency**: Identical error responses across API, Android SDK, CLI. Shared JWT format.
- **Trust & Safety**: Moderation workflows `flag → review → approved/removed`. Audit trails on all actions. Explicit `is_flagged`, `moderation_status` in payloads.
- **Diaspora-Aware**: Timezone-aware notifications (UTC-5 to UTC+0). Segments: USA 45%, Canada 20%, UK 15%, Caribbean 8%, other 12%.

## Reference Files

| File | Use for |
|------|---------|
| `templates/quick-reference.md` | API design checklist |
| `templates/api-prd-template.md` | Comprehensive PRD template (14 sections) |
| `templates/acceptance-criteria.md` | Testable story-level acceptance criteria |
| `templates/openapi-spec-template.yaml` | OpenAPI 3 draft starter |
| `templates/postman-collection.json` | Manual API exploration |
| `reference/grenadianbuzz-api-patterns.md` | Production patterns, versioning, moderation |
| `reference/grenadianbuzz-android-context.md` | Kotlin, Compose, API integration, offline-first |
| `reference/grenadianbuzz-cli-guide.md` | Command patterns, admin workflows, scripts |
| `reference/grenadianbuzz-dashboard-guide.md` | Moderation, analytics, creator tools |
| `reference/release-rollout-playbook.md` | Step-by-step release and rollback |
| `INDEX.md` | Start-here map for all surfaces |

## Personal Machine Activation

This skill is personal-machine-only. Add `grenadianbuzz` to `~/.personal-machine-skills.txt` (one per line) and re-run your environment's link sync command.

---

**Version**: 0.5.0  
**Last Updated**: May 3, 2026  
**Audience**: Engineers, product leads
