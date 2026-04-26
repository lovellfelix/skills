# GrenadianBuzz Skill v0.4.0 Update Summary

**Version**: 0.4.0 | **Date**: 2026-04-26 | **Status**: Stable

## What Changed from v0.1.0

### Scope Expansion: From API-Only to Unified Product Skill

**v0.1.0 (grenadianbuzz-api)**
- Focused exclusively on REST API design and implementation
- Covered versioning, pagination, error handling, engagement endpoints
- Guided API contract-first design for backend-focused teams

**v0.4.0 (grenadianbuzz)** — NEW
- Expands scope to **all product surfaces**:
  - Backend API (REST, versioning, production patterns)
  - **Android app** (Kotlin, JetpackCompose, MVVM, offline-first, new!)
  - CLI tools (automation, admin operations, new context)
  - Dashboard (analytics, moderation, creator tools, new context)
  - Website (static site, CDN on Surge)
  - Newsletter strategy (diaspora engagement, segmentation, new!)
- Unified **cross-platform workflow**: clarify → scope → model → design → integrate → validate → rollout
- Integrated product and technical guidance for feature design spanning mobile, backend, and admin tooling

### New Content

#### 1. **Android Integration Guide** (NEW)
- **File**: `reference/grenadianbuzz-android-context.md` (~800 lines)
- **Coverage**:
  - Project structure: app/, admin/ (moderation variant), build.gradle with flavor dimensions
  - Retrofit API integration: data envelope wrapping, request/response models, error handling
  - JWT authentication: token caching (encrypted SharedPreferences), refresh logic, AuthInterceptor pattern
  - Network resilience: exponential backoff (100ms + jitter, 3 retries), handles spotty diaspora networks
  - Offline-first architecture: SQLite + Room for local Feed cache, cache eviction policy
  - Repository pattern: local + remote data sources, coherent error handling
  - JetpackCompose UI patterns: FeedScreen, ReactionBar, ArticleDetailScreen with offline fallback
  - Admin app variant: separate moderation queue interface (swipe-to-approve, SLA tracking)
  - Analytics: Firebase + custom event tracking (article_view, reaction_added, comment_added, newsletter_optin)
  - Build configuration and release checklist
  - Troubleshooting: crashes, offline cache, token expiry, moderation visibility, rate limiting
- **When to use**: Designing mobile-aware features, specifying Android endpoint consumers, planning app architecture

#### 2. **Expanded Workflow** (UPDATED)
- **File**: `SKILL.md` (lines 46–120)
- **Changes**:
  - Added explicit multi-surface steps: clarify which surfaces are involved, define bounded scope per platform
  - Integrated mobile-first data model validation (offline cache requirements, bandwidth constraints)
  - Added design phase covering API, mobile UI, CLI, and dashboard concurrently
  - Integration checklist now covers API + Android networking, offline behavior, analytics sync
  - Validation expanded to mobile-specific testing (JetpackCompose previews, offline scenarios, token refresh)
  - Rollout includes mobile app versioning and phased user rollout
- **Benefit**: Feature designs now consider all surfaces from day one, reducing rework and integration friction

#### 3. **Android-Specific Domain Context** (UPDATED in SKILL.md)
- **New section**: "Android Architecture & Offline-First" (lines 180–220)
- **Content**:
  - MVVM + Repository pattern expected for all mobile features
  - Offline-first design requirement: local cache mirrors remote state
  - JWT token refresh on auth failure (no session cookies)
  - Exponential backoff for retries on unreliable diaspora networks
  - Firebase Analytics as standard (not optional)
  - Admin app variant architecture (same backend, separate app variant)
- **Benefit**: Aligns with real Android codebase structure; guides feature designers on mobile constraints

#### 4. **Newsletter Strategy Section** (NEW in SKILL.md)
- **New section**: "Newsletter & Engagement Strategy" (lines 221–240)
- **Content**:
  - Diaspora segmentation: geography, subscription tier, engagement level
  - Newsletter cadence and content types (digest, event alerts, trending)
  - Compliance: CAN-SPAM, GDPR, CASL, unsubscribe workflows
  - Metrics: open rate, click-through rate, unsubscribe rate, subscriber churn
  - Integration with app analytics (newsletter_optin event, source attribution)
- **Benefit**: Bridges product strategy (retention, growth) with implementation (API, email service, analytics)

### Preserved Content (Backward Compatible)

All v0.1.0 (grenadianbuzz-api) resources remain unchanged and fully available:

| File | Lines | Status | Purpose |
|------|-------|--------|---------|
| `reference/grenadianbuzz-api-patterns.md` | 823 | ✓ Included | API design patterns, versioning, error handling, real examples |
| `reference/grenadianbuzz-domain-checklist.md` | 126 | ✓ Included | 39+ service design validations across content, engagement, safety, analytics |
| `templates/api-prd-template.md` | 264 | ✓ Included | 14-section comprehensive PRD template for API features |
| `templates/quick-reference.md` | 487 | ✓ Included | API design checklist, endpoint templates, pagination, engagement patterns |

### Unchanged Design Decisions

All core GrenadianBuzz patterns remain stable:

- **Reaction emojis**: 👍 ❤️ 🕯️ 💖 🌹 🙏
- **Geographic segments**: USA 45%, Canada 20%, UK 15%, Caribbean 8%, other
- **Subscription tiers**: free, premium ($4.99/mo), family ($9.99/mo)
- **Moderation lifecycle**: active → flagged → review_pending → approved/removed
- **Pagination**: cursor-based, opaque encoding
- **API versioning**: /v1, /v2, /v3 with 90-day deprecation window
- **Personal-only activation**: `personal_machine_only: true` (no secrets exposed)
- **Portability**: Templates and patterns reusable for other projects

### Metadata Updates

**manifest.json** (v0.4.0):
- **Name**: `grenadianbuzz` (was: `grenadianbuzz-api`)
- **Tags added**: `mobile`, `android`, `frontend`, `newsletter`, `architecture`
- **Entrypoint**: `SKILL.md` (unchanged)
- **Portability**: `true` (unchanged)
- **Adapters**: OpenCode, Cursor, Claude (all supported)

**SKILL.md frontmatter** (v0.4.0):
- **Version**: 0.4.0 (was: 0.1.0)
- **Description**: Unified product and engineering skill across all surfaces
- **Tags**: Added `product`, `mobile`, `android`, `frontend`

## Consolidation Update

All GrenadianBuzz materials are now consolidated under the canonical package:

- `skills/portable/grenadianbuzz/`

The following deep guides were merged into the canonical package:

- `reference/grenadianbuzz-cli-guide.md`
- `reference/grenadianbuzz-dashboard-guide.md`
- `reference/grenadianbuzz-website-guide.md`
- `INDEX.md` (navigation guide)

## Compatibility

`skills/portable/grenadianbuzz-api/` is now a thin compatibility shim:

- Keeps `manifest.json` and `SKILL.md` for backward compatibility.
- Points users to `skills/portable/grenadianbuzz/` for all active references.
- Preserves `personal_machine_only: true` behavior.

## Canonical Structure

```
skills/portable/grenadianbuzz/
├── SKILL.md
├── INDEX.md
├── manifest.json
├── UPDATE_SUMMARY.md
├── reference/
│   ├── grenadianbuzz-android-context.md
│   ├── grenadianbuzz-api-patterns.md
│   ├── grenadianbuzz-cli-guide.md
│   ├── grenadianbuzz-dashboard-guide.md
│   ├── grenadianbuzz-domain-checklist.md
│   └── grenadianbuzz-website-guide.md
└── templates/
    ├── api-prd-template.md
    └── quick-reference.md
```
