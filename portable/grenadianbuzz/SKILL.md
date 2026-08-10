---
name: grenadianbuzz
description: Use when working on GrenadianBuzz features, architecture, or operational tasks across any surface (API, Android app, CLI, website, dashboard, docs).
metadata:
  version: 0.7.0
  portable: true
  personal_machine_only: true
  tags: [grenadianbuzz, product, mobile, api, backend, frontend, architecture]
---

# GrenadianBuzz Product & Engineering Skill

---

## Authoritative Roadmap

The single source of truth for current planning is **`docs/ROADMAP.md`** in the workspace (`~/projects/grenadianbuzz/docs/ROADMAP.md`). When in doubt about priority, sequence, or what's superseded, read it first. This skill provides background context; ROADMAP.md provides the active plan.

Five docs are explicitly superseded and bannered (do not use for current planning): `IMPLEMENTATION_ROADMAP.md`, `IMPLEMENTATION_CHECKLIST.md`, `ASSESSMENT_AND_PLAN.md`, `INTEGRATION_COMPLETE.md`, `CROSS_REPO_INTEGRATION.md`.

Three PRDs were archived 2026-05-09 to `docs/prd/_archive/`: `PROJECT_PRD.md`, `WEBSITE_PRD.md`, `WEBSITE_PRD_SUMMARY.md`. Live PRDs are: `GRENADIAN_BUZZ_PRD.md` (master), `AI_NEWSLETTER_PRD.md`, `CLI_PRD.md`, `MONETIZATION_PRD.md`.

---

## Live Repo Issue/PR Snapshot (base 2026-05-09; deltas to 2026-05-14)

- **grenadianbuzz-android**: 40 open issues / ~15 open PRs — Compose pile-up triaged 2026-05-09: #296/#298 closed, #301 canonical, #300 awaiting author. _Deltas: Draft PR #302 (Android, #254 Google Sign-In) opened 2026-05-13; Draft PRs #305 (Room P1) + #308 (Room P2) opened 2026-05-13/14._
- **grenadianbuzz.cli**: 18 open issues / ~1 open PRs — newsletter epic #50–59 authored as issues. _Delta 2026-05-10: Draft PR #62 (fetcher, #51) opened on `feat/newsletter-fetcher`. #52/#53 still need PRs._
- **api.grenadianbuzz.com**: 4 open issues / 4 open PRs — critical inflight: PR #278 PocketBase adapter (draft, needs explicit go/no-go), PR #277 Pug→Mustache migration (proceed to merge), PR #302 FCM newsletter notifications.
- **dashboard.grenadianbuzz.com**: 1 open issue / 4 open PRs — Nuxt rewrite inflight (PR #71/#75). Otherwise maintenance.
- **grenadianbuzz.com**: 1 open issue / 5 open PRs — Renovate / Jekyll bumps only.

### Routing Guidance & Critical Decisions

- **Tier 1**: AI Newsletter pipeline (CLI #50–59 + **#48 metrics, promoted to Tier 1** + API #307/#308 + PR #302). The single product bet for 2026.
- **Tier 2**: Android foundation (#254 → #282 → #287 → #255/#253). No UI redesign (#293) until done.
- **Tier 3**: inflight migrations (Compose #301, PocketBase #278, Mustache #277, Nuxt #71). Rule: no new migration starts until ≥2 of these merge.
- **Tier 4**: maintenance — website, dashboard post-Nuxt, Android `Backlog` label, KMM (#268 — out of scope for 2026).
- **Mustache is the email standard** (decided 2026-05-09): all new templates in Mustache; PR #277 bridges existing Pug. Issue #308 template name is `email-ai-newsletter.mustache`, not `.pug`. Do not author in Pug.
- **Cron timezone bug** (critical): `"0 8 * * 1"` in `gbuzz/task.py` = 03:00–04:00 EST — unusable. Must be **`"0 13 * * 1"`** (09:00 EST). Fix before any production enable.
- Re-verify live counts every 2 weeks via `gh issue/pr list`; if any count changes >20%, revisit tier ordering.

### Newsletter Live Prerequisites (no GitHub issues yet — file before CLI #59 closes)

1. **Subscriber list** — import or build opt-in list before first send.
2. **Email auth** — SPF, DKIM, DMARC on `grenadianbuzz.com`; without this, Gmail/Outlook deliverability is broken.
3. **Staging dry run** — full pipeline against ≥10 real addresses; verify render in Gmail/Apple Mail/Outlook web.
4. **Cron timezone fix** — change to `"0 13 * * 1"` and confirm in staging before production enable.

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

| Surface         | Repo                                      | Type                          | Status                         |
| --------------- | ----------------------------------------- | ----------------------------- | ------------------------------ |
| **Android App** | `grenadianbuzz-android`                   | Mobile (Kotlin, Compose)      | Active                         |
| **API**         | `api.grenadianbuzz.com`                   | Backend (FeathersJS, Node.js) | Production, active deprecation |
| **CLI**         | `grenadianbuzz.cli`                       | Tooling (Python 3.8+)         | Growth phase                   |
| **Dashboard**   | `grenadianbuzz` (`web/dashboard`)         | Admin (React, TailwindCSS)    | Maintenance                    |
| **Website**     | `grenadianbuzz` (`web/grenadianbuzz.com`) | Public (Nuxt/Vue)             | Stable                         |
| **Docs**        | `grenadianbuzz` (`docs/`)                 | Reference (Markdown, OpenAPI) | Living                         |
| **PRD**         | `grenadianbuzz` (`docs/prd/`)             | Planning (Markdown)           | Source of truth                |

## Canonical Issue Clusters

High-signal work grouped by surface and dependency. **Source of truth**: GitHub issues; canonical mapping only.

### Android App (`grenadianbuzz-android`)

| Issue            | Scope                                        | Status    | Notes                                                                             |
| ---------------- | -------------------------------------------- | --------- | --------------------------------------------------------------------------------- |
| **#254**         | Google Sign-In implementation                | Draft PR  | Android PR #302 open 2026-05-13; needs Google Cloud Console OAuth config          |
| **#282**         | Realm → Room database migration              | Draft PRs | PR #305 (P1: empty DB + flag) + PR #308 (P2: AuditTrailRepository, -120 LOC) open |
| **#287**         | Testing & instrumentation expansion          | PR needed | Draft PR needed; gates all remaining Tier 2 items                                 |
| **#255, #253**   | Android 15 status bar issues                 | Open      | OS compatibility                                                                  |
| **Android #293** | UI redesign — cultural identity & engagement | Blocked   | Explicitly blocked behind Tier 2 completion                                       |

**Recommended sequencing**: Android #254 (unblock OAuth config) → #282 (PRs open, need review) → #287 (open PR) → #255/#253 → #293.

### CLI (`grenadianbuzz.cli`)

| Issue Range | Scope                               | Status      | Notes                                                               |
| ----------- | ----------------------------------- | ----------- | ------------------------------------------------------------------- |
| **#51**     | `newsletter/fetcher.py`             | In progress | Draft PR #62 open on `feat/newsletter-fetcher`; depends on API #307 |
| **#52**     | `newsletter/ai_client.py`           | PR needed   | Needs draft PR this sprint                                          |
| **#53**     | `newsletter/generator.py`           | PR needed   | Needs draft PR this sprint                                          |
| **#54–59**  | notifier, commands, task, tests     | Queued      | Can start in parallel with #52/#53                                  |
| **#48**     | Metrics aggregation & reporting     | **Tier 1**  | Promoted — exit criteria require metrics before newsletter is live  |
| **#46**     | Operational runbook                 | Planned     | Runbook + recovery                                                  |
| **#47**     | Environment variables documentation | Planned     | Ops readiness                                                       |
| **#49**     | Dependency maintenance              | Ongoing     | Hygiene (Tier 4)                                                    |

**Recommended sequencing**: #51 (inflight) → #52/#53 (this sprint) → #54–59 → #48 → subscriber list + email auth + staging dry run → production.

### API (`api.grenadianbuzz.com`)

| Issue        | Scope                                          | Status   | Notes                                                         |
| ------------ | ---------------------------------------------- | -------- | ------------------------------------------------------------- |
| **API #293** | Deprecation warnings (v2→v3 migration)         | Open     | Backward compatibility                                        |
| **#307**     | `/v1/trending` `date`+`last` params            | Planning | Unblocks CLI #51 (fetcher)                                    |
| **#308**     | Email template: `email-ai-newsletter.mustache` | Active   | Mustache format (decided 2026-05-09); coordinate with CLI #58 |

**Note on API #308**: template name is `email-ai-newsletter.mustache`, not `.pug`. Mustache is the project standard for all new email templates. See PR #277 for Pug→Mustache migration of existing templates.

**Recommended sequencing**: #307 (unblocks CLI) → #308 (coordinate with CLI #58) → API #293 (opportunistically).

### Dashboard & Website

| Surface       | Status      | Notes                                |
| ------------- | ----------- | ------------------------------------ |
| **Dashboard** | Maintenance | Renovate tracked; no active features |
| **Website**   | Stable      | Not a blocker for engagement/revenue |

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

| File                                         | Use for                                         |
| -------------------------------------------- | ----------------------------------------------- |
| `templates/quick-reference.md`               | API design checklist                            |
| `templates/api-prd-template.md`              | Comprehensive PRD template (14 sections)        |
| `templates/acceptance-criteria.md`           | Testable story-level acceptance criteria        |
| `templates/openapi-spec-template.yaml`       | OpenAPI 3 draft starter                         |
| `templates/postman-collection.json`          | Manual API exploration                          |
| `reference/grenadianbuzz-api-patterns.md`    | Production patterns, versioning, moderation     |
| `reference/grenadianbuzz-android-context.md` | Kotlin, Compose, API integration, offline-first |
| `reference/grenadianbuzz-cli-guide.md`       | Command patterns, admin workflows, scripts      |
| `reference/grenadianbuzz-dashboard-guide.md` | Moderation, analytics, creator tools            |
| `reference/release-rollout-playbook.md`      | Step-by-step release and rollback               |
| `INDEX.md`                                   | Start-here map for all surfaces                 |

## Personal Machine Activation

This skill is personal-machine only.

- Linked automatically when `~/.overlay/local/.enabled` is absent (no allowlist to maintain).

---

**Version**: 0.7.0  
**Last Updated**: May 20, 2026  
**Audience**: Engineers, product leads  
**Wiki**: `~/llm-wiki/notes/projects/grenadianbuzz.md` — live project synthesis with tier state and key decisions
