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
| `templates/acceptance-criteria.md` | Story-level, testable acceptance criteria template |
| `templates/openapi-spec-template.yaml` | OpenAPI 3 template for drafting and CI validation |
| `templates/postman-collection.json` | Starter Postman collection for manual API exploration |
| `templates/playwright-smoke.spec.ts` | Playwright smoke test starter for web smoke checks |
| `templates/email-deliverability-playbook.md` | Runbook for diagnosing email deliverability issues |
| `reference/grenadianbuzz-api-patterns.md` | Production patterns, versioning, moderation, engagement |
| `reference/grenadianbuzz-domain-checklist.md` | Design validations across surfaces |
| `reference/grenadianbuzz-android-context.md` | Kotlin, JetpackCompose, API integration, offline-first |
| `reference/grenadianbuzz-android-test-matrix.md` | Device/OS/test-type matrix and release criteria for Android |
| `reference/grenadianbuzz-cli-guide.md` | Command patterns, admin workflows, automation scripts |
| `reference/grenadianbuzz-dashboard-guide.md` | Moderation, analytics, creator tooling |
| `reference/grenadianbuzz-dashboard-testing.md` | Dashboard accuracy, freshness, access, and performance tests |
| `reference/grenadianbuzz-website-guide.md` | Public pages, SEO/accessibility, engagement patterns |
| `reference/grenadianbuzz-security-checklist.md` | Security sign-off checklist for features and releases |
| `reference/grenadianbuzz-cdn-cache-policy.md` | CDN caching rules and invalidation guidance |
| `reference/grenadianbuzz-observability-slos.md` | SLOs, SLIs, alerting and dashboard guidance for ops |
| `reference/api-contract-tests.md` | Contract testing approaches, CI integration, and rollback criteria |
| `reference/ci-cd-pipelines.md` | CI/CD stages, gating, canary strategy, and artifact handling |
| `reference/release-rollout-playbook.md` | Step-by-step release and rollback playbook |
| `INDEX.md` | Start-here map for API, Android, CLI, dashboard, and website |

### How to use these artifacts
- Templates live under `templates/` and are intended to be copied into feature PRs or story descriptions (OpenAPI, Playwright, Postman, acceptance criteria).
- `reference/` files are guidance and runbooks for engineering and SRE during design, CI, and release.
- Include links to relevant templates in PR descriptions (OpenAPI or acceptance criteria) and attach checklist items from `reference/grenadianbuzz-security-checklist.md` and `reference/release-rollout-playbook.md` before approving production deploys.

Onboarding note — templates and placeholders
- Many templates include placeholders (e.g. `YOUR_API_URL`, `YOUR_API_CLIENT_KEY`, `{{OWNER}}`, `<PROJECT_NAME>`). Replace these with real values before using or copying into a PR. For quick convenience, here is a small example (example ONLY — do not commit secrets) for `~/.config/gbuzz/config.yaml`:

```yaml
API_URL: "https://api.grenadianbuzz.com"
# WARNING: replace with your real client key. Use environment variables or a secrets manager in CI. Do NOT commit secrets to git.
API_CLIENT_KEY: "YOUR_API_CLIENT_KEY"
HTTP_TIMEOUT: 30
```

This pattern applies to PRD, OpenAPI, and newsletter templates — fill title, owner, and environment values before publishing.

## Personal Machine Activation

This skill is personal-machine-only and stays disabled unless explicitly allowlisted.

- Add `grenadianbuzz` to `~/.personal-machine-skills.txt` (one skill name per line).
- Re-run your runtime link sync after updating the allowlist. Example command (placeholder — replace with your environment-specific command):

```
# Example runtime sync commands; pick the one that matches your setup or replace with your environment's command
pi runtime link sync
# or
./scripts/runtime-sync.sh
```

If you use a different runtime manager, run the equivalent "link sync" operation for your environment.
