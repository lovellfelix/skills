---
name: grenadianbuzz
description: Unified product and engineering skill for GrenadianBuzz across all surfaces (API, Android app, CLI, website, dashboard, CDN).
version: 0.2.0
portable: true
tags: [grenadianbuzz, product, mobile, api, backend, frontend, architecture]
---

# GrenadianBuzz Product & Engineering Skill

## What this skill does

- Provides integrated product and technical guidance across **all GrenadianBuzz surfaces**:
  - Backend API (REST, versioned, production-grounded)
  - Android app (Kotlin, JetpackCompose, architecture)
  - CLI tools (automation, admin operations)
  - Dashboard (analytics, moderation, creator tools)
  - Website (static site, CDN on Surge)
  - Newsletter strategy (diaspora engagement, segmentation)
- Turns product ideas into **coherent feature designs** spanning mobile, backend, and admin tooling.
- Produces **API-first specifications** with mobile-native integration patterns.
- Keeps scope clear for diaspora audience, trust & safety, and engagement.

## Use when

- You need to design a feature **across multiple surfaces** (e.g., API + Android + dashboard).
- You're specifying an **Android endpoint consumer** or mobile-specific payload shape.
- You're planning **API changes** that affect mobile clients, CLI, or admin tools.
- You need to align **product requirements** with mobile architecture, backend contracts, and operational needs.
- You're designing **newsletter or engagement strategy** targeting diaspora segments.

## Do not use when

- The task is only UI styling with no API or data contract changes.
- You already have approved contracts and only need implementation.
- Task is purely mobile-only with no backend integration.

## Inputs expected

- Product goal and user persona (diaspora segment, engagement type, creator/user focus).
- Existing entities/endpoints (if any).
- Required platforms: API, Android, CLI, dashboard, website (specify which).
- Business rules, compliance constraints, timeline.
- Geographic/audience context (diaspora spread, time zones, subscription tiers).

## Workflow

1. **Clarify objective**: Which surfaces are involved? What's the user journey end-to-end?
2. **Define bounded scope**: Specific endpoints, mobile screens, CLI commands, admin features.
3. **Model entities and relationships**: Shared across all surfaces with clear ownership.
4. **Design contracts**: API payloads, mobile request/response, error modes.
5. **Plan surface integration**: How does Android consume the API? CLI command structure? Dashboard analytics?
6. **Add acceptance criteria**: Measurable behavior across platforms.
7. **Add rollout and monitoring**: Backward compatibility, feature flags for mobile, analytics hooks.

## Core patterns

### API-First Design
- REST contracts first, implementation details second.
- Mobile clients drive payload shapes (minimize network traffic).
- Cursor-based pagination for feed stability (not offset/limit).
- Versioning: /v1, /v2, /v3 with 90+ day deprecation windows.

### Mobile-Aware Payloads
- Minimize JSON size (diaspora users often on slower networks).
- Support both full and summary representations (list vs detail).
- Include cache hints (HTTP ETag, Last-Modified).
- Idempotency keys for mutations (Android app reliability over spotty connectivity).

### Cross-Platform Consistency
- Error responses identical across API, Android SDK, CLI.
- Auth token format shared (JWT with exp, roles).
- Moderation status visible to all surfaces (is_flagged, moderation_status for admins).
- Analytics events consistent (same names and schemas).

### Trust & Safety First
- Moderation workflows: flag → review → approved/removed.
- Audit trails for all moderation actions.
- Explicit moderation status in payloads (is_flagged, moderation_status).
- Separate /moderation endpoints for admin operations (Android admin app and web dashboard).
- Rate limiting and anti-abuse checks (especially for mobile).

### Diaspora-Aware
- Timezone-aware notifications (diaspora spread globally: UTC-5 to UTC+0).
- Geographic segments: USA (45%), Canada (20%), UK (15%), Caribbean neighbors (8%), other.
- Subscription tiers: free, premium ($4.99/mo), family ($9.99/mo).
- Feed personalization: location, interest, language, subscription tier.
- Newsletter segmentation: cultural, news, radio, obituaries, events.

## GrenadianBuzz Domain Defaults

### Content Model
- Articles/news from RSS feeds, news sources, and manual submissions
- Obituary listings with search and biographical metadata
- Radio stations (streaming metadata, geolocation bypass)
- Cultural events (Carnival, Independence Day, religious observances)
- User-generated content: comments, reactions, saved items, subscriptions

### Engagement & Analytics
- Interaction types: likes (👍), love (❤️), seasonal reactions (🕯️ 💖 🌹 🙏)
- Comment threads on articles, obituaries, and events
- Engagement metrics: view counts, comment counts, shares
- Near-real-time trending and top-users aggregation
- Moderation status tracking (review, approved, flagged, removed)

### User & Audience Segments
- Geographic segments: USA (45%), Canada (20%), UK (15%), Caribbean neighbors (8%), other
- Time-zone aware notifications (diaspora spread globally)
- Subscription tiers: free (basic), premium ($4.99/mo), family ($9.99/mo)
- Role-based access: user, admin, moderator, premium, creator
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

### Android App Specifics
- **Language**: Kotlin with JetpackCompose
- **Target**: Diaspora audience on Android 10+
- **Architecture**: MVVM with offline-first capability
- **API Consumer**: REST client with exponential backoff for spotty connectivity
- **Auth**: JWT tokens cached locally with refresh logic
- **Storage**: SQLite for local cache, warm offline feed
- **Analytics**: Firebase Analytics + custom event tracking
- **Moderation Admin Tool**: Separate admin variant of app with moderation queue interface

### CLI Tool Context
- Purpose: Admin operations, bulk content management, moderation queue processing
- Auth: API key or JWT token
- Output: JSON, CSV export options
- Commands: articles, events, obituaries, moderation, users, subscriptions, analytics
- Safety: Rate limited, audit logged

### Dashboard (Web)
- Analytics views: Creator insights, subscriber trends, engagement metrics
- Moderation queue: Flag review workflow, bulk actions
- Content management: Create/edit/publish articles, manage events
- Subscription management: User upgrades, churn analysis
- Newsletter builder: Segment targeting, A/B testing
- Geography: Map views of audience distribution, time-zone aware scheduling

### Website
- Static site hosted on Surge CDN
- Marketing, documentation, about page
- Link to Android app store listings
- Newsletter signup
- API documentation (OpenAPI/Swagger)

### Newsletter Strategy
- **Frequency**: 1-2x per week to diaspora
- **Segments**: by category (news, events, obituaries), geography, subscription tier
- **Engagement**: Personalized based on past reads, interests
- **Content**: Article summaries, upcoming events, featured creators, community highlights
- **Compliance**: CAN-SPAM, GDPR (explicit consent), unsubscribe links
- **Metrics**: Open rate, click rate, unsubscribe rate, conversion to app

## Output structure

- **Product spec** with goals, constraints, success metrics.
- **Entity model** and state transitions (API, mobile, CLI contexts).
- **API endpoint matrix** with auth, payloads, failure modes.
- **Mobile integration guide** (API consumption, screen designs, error handling).
- **CLI command specification** (if applicable).
- **Dashboard views** (if applicable).
- **Analytics and event schema**.
- **OpenAPI draft** sections and example JSON payloads.
- **Rollout checklist** with backward compatibility, feature flags, monitoring.

## Examples and reference

- **Quick Start**: `templates/quick-reference.md` - Fast checklist and examples for API design
- **Full API Template**: `templates/api-prd-template.md` - Comprehensive PRD template with 14 sections
- **API Patterns**: `reference/grenadianbuzz-api-patterns.md` - Production patterns, versioning, moderation, engagement
- **Domain Checklist**: `reference/grenadianbuzz-domain-checklist.md` - Design validations across surfaces
- **Android Guide**: `reference/grenadianbuzz-android-context.md` - Kotlin, JetpackCompose, API integration, offline-first patterns
- **CLI Guide**: `reference/grenadianbuzz-cli-guide.md` - Command patterns, admin workflows, automation scripts
- **Dashboard Guide**: `reference/grenadianbuzz-dashboard-guide.md` - Moderation, analytics, creator tooling, responsive layouts
- **Website Guide**: `reference/grenadianbuzz-website-guide.md` - Public pages, SEO/accessibility, engagement patterns
- **Navigation Index**: `INDEX.md` - Start-here map for API, Android, CLI, dashboard, and website

## Practical Examples

### New Feature: Event Reminders (API + Android)
Your product team wants push notifications for upcoming cultural events:
```
Input: "Users want reminders for Carnival and Independence Day events"
Output: 
- PRD with /v2/events/{id}/reminders endpoint
- Mobile screen: notification preferences, permission handling
- Payload: light weight (event ID, title, time delta)
- Analytics: notification delivery rate, open rate
- Rollout: Feature flag for staged deployment
```

### Creator Analytics Dashboard (API + Web Dashboard)
Creators want to see follower growth trends and top posts:
```
Input: "Creators need insights into audience engagement"
Output: 
- PRD with /v2/creators/{id}/analytics endpoint
- Time-range filters, response schema
- Dashboard views: growth chart, top articles, engagement rate
- Moderation gate: hide banned creators
- Success metric: adoption in 2 weeks
```

### Moderation Workflow (API + Android Admin App + Dashboard)
Admin team needs efficient flagged content review:
```
Input: "Moderators need to bulk review, approve, or remove flagged posts"
Output: 
- /moderation/queue endpoint with filtering, batch actions
- Admin app interface: swipe-to-approve gestures
- Audit trail, role-based access
- CLI command: moderation process --status=flagged --limit=50
- Dashboard: moderation dashboard with SLA tracking
```

### Newsletter A/B Test (API + Email Service)
Marketing wants to test subject lines targeting diaspora:
```
Input: "Newsletter open rates are declining; test segmentation"
Output: 
- /v2/newsletters endpoint with segment targeting
- API: campaign creation, A/B split, tracking pixel hooks
- Segments: geography, subscription tier, engagement level
- Metrics: open rate, click rate, conversion
- Compliance: unsubscribe tracking, consent verification
```

## Personal Machine Activation

- This is a personal-machine-only skill and stays disabled unless explicitly allowlisted.
- Add `grenadianbuzz` to `~/.config/opencode/personal-machine-skills.txt` (one skill name per line).
- Re-run your runtime link sync after updating the allowlist.

## Troubleshooting

**"I'm designing a feature but need to span API + Android + CLI"**
Start with the API contract first (smallest, mobile-friendly payloads). Then design Android screens around those payloads. CLI mirrors API structure. Dashboard reads same endpoints with admin roles.

**"How do I balance API simplicity with cross-platform needs?"**
Design for the most constrained platform first (mobile on slow networks). Then add richness for web/dashboard. Use response summary vs full representations.

**"Should moderation be visible to Android users?"**
Yes. User-facing apps show `is_flagged` boolean (content hidden if true). Admin Android app shows full `moderation_status` enum and review UI. Web dashboard shows audit trail.

**"We need this feature next week; do I really need a full spec?"**
A 1-page PRD (goal, entities, 4-5 endpoints, platforms) takes 2 hours. It saves 10 hours of implementation rework. Always worth it.

**"How do I version the Android API client?"**
Android client should target the latest stable API version (/v2 or /v3). Implement graceful degradation for missing fields. Use feature flags for server-side functionality rollout.

**"Our diaspora users are on spotty networks. What do we do?"**
Minimize payload sizes, support etag/conditional requests, implement local SQLite cache, use exponential backoff for retries, and provide offline-first critical features (reading cached articles).
