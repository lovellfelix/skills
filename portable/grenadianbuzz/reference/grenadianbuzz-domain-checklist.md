# GrenadianBuzz Domain Checklist

Use this checklist when designing product APIs for GrenadianBuzz. Covers 39+ production services.

## Content and Feed

- [ ] Define ordering semantics: published_at (default), trending, top_users
- [ ] Clarify pagination strategy: cursor-based for feed stability (not offset)
- [ ] Capture media metadata: image_url, content type, reading_time_minutes
- [ ] Support multi-version endpoints: /v1/, /v2/, /v3/ with deprecation path
- [ ] Define article status: published, draft, archived, featured
- [ ] Filter by category (news, events, radio, obituaries, cultural)
- [ ] Filter by source (RSS feeds, manual, scraped, partnerships)
- [ ] Include language field (default: en, support future localization)

## Engagement and Reactions

- [ ] Define reactions: 👍 (like), ❤️ (love), 🕯️ (remembrance), 💖 (support), 🌹 (tribute), 🙏 (condolence)
- [ ] Specify idempotent behavior: POST same reaction = toggle (not duplicate)
- [ ] Include anti-abuse and rate-limit responses (429 Too Many Requests)
- [ ] Support comment threads on articles, obituaries, and events
- [ ] Include comment moderation status in responses
- [ ] Track engagement counts in content payloads: comment_count, like_count, share_count
- [ ] Provide /interactions/counts/{contentId} for lightweight read
- [ ] Support interaction filtering: by type, date range, user

## Trust and Safety (First-Class)

- [ ] Define moderation status enum: active, flagged, review_pending, approved, removed
- [ ] Include is_flagged boolean in all content responses (user-facing safe default)
- [ ] Emit audit events for every moderation action
- [ ] Separate /moderation endpoints (admin-only) from content endpoints
- [ ] Support bulk moderation actions for efficiency
- [ ] Return moderation rationale in admin payloads (optional, for transparency)
- [ ] Define role-based access: user, admin, moderator (different visibility)
- [ ] Exclude banned/removed content from public /feed and /explore endpoints

## Analytics and Creator Signals

- [ ] Define event naming: view, read, comment, share, like, subscribe
- [ ] Distinguish near-real-time (< 1 min) vs delayed metrics (batch, hourly)
- [ ] Include data freshness expectations in API docs
- [ ] Support analytics aggregation: stats=events, stats=daily, stats=monthly, stats=trending, stats=top
- [ ] Provide creator dashboard endpoints: /creators/{id}/analytics
- [ ] Track user engagement signals: MAU, DAU, session duration, articles read per user
- [ ] Support time-range filters: ?from=2026-01-01&to=2026-02-01

## Reliability and Performance

- [ ] Define SLOs: read latency <500ms, write latency <1s, availability 99.5%
- [ ] Capture fallback behavior for downstream failures (degraded mode)
- [ ] Include versioning and deprecation policy in PRD (minimum 90-day notice)
- [ ] Support graceful degradation: missing image → default placeholder
- [ ] Document rate limits: per-user, per-IP, per-API-key
- [ ] Implement request logging and tracing (X-Request-ID header)

## Geographic and Regional Context

- [ ] Support timezone-aware notifications (diaspora across +UTC-5 to +UTC+0)
- [ ] Define regional content filters: Grenada vs diaspora markets
- [ ] Support location-based queries for events and radio stations
- [ ] Include country field in user profiles for segmentation
- [ ] Handle daylight saving time transitions in scheduled content

## Authentication and Authorization

- [ ] Support multiple auth strategies: JWT, local (email/password), OAuth (Google, Facebook), API key
- [ ] Define JWT payload: userId, email, roles, exp (1 day), aud, iss
- [ ] Scope API endpoints by role: public, user, admin, moderator
- [ ] Require auth for: user profile, subscriptions, saved items, interactions
- [ ] Public access for: articles, events, radio stations, obituary listings
- [ ] Document token refresh and expiry handling

## Subscription and Monetization

- [ ] Include subscription_status in user payloads: free, premium, family, enterprise
- [ ] Gate premium features in endpoint responses (permission model)
- [ ] Support subscription lifecycle: active, cancelled, expired, on_hold
- [ ] Track payment metadata: payment_date, next_billing_date, churn_risk
- [ ] Provide subscription management endpoints: upgrade, downgrade, cancel

## Schema and Data Quality

- [ ] Use UUID for all primary keys
- [ ] Include created_at, updated_at, deleted_at timestamps
- [ ] Enforce NOT NULL on critical fields: title, content, published_at
- [ ] Use ENUM for status fields (not free-text strings)
- [ ] Validate email format, URLs, and date ranges on input
- [ ] Provide clear error messages for validation failures

## Webhooks and Integrations

- [ ] If implementing webhooks: support events like new_article, moderation_action, subscription_change
- [ ] Sign webhook payloads with HMAC-SHA256
- [ ] Implement webhook retry strategy: exponential backoff, max 3 attempts
- [ ] Provide webhook test harness and sandbox environment
- [ ] Document webhook payload schema and event types

## Example Application (Obituaries)

Obituary API illustrates domain convergence:
- Content model: burial notice, biographical data, tributes
- Engagement: save, share, condolence reactions (🕯️ 🙏)
- Audience: genealogy research, diaspora remembrance
- Moderation: auto-flag sensitive content, manual review
- Search: full-text name/date range, geographic filter
- Analytics: views per obituary, trending deceased
- Endpoint: /v2/obituaries/listing with cursor pagination

## Example Application (Events)

Event API for cultural engagement:
- Content: Carnival, Independence Day, religious holidays, local festivals
- Filtering: date range, category (cultural, sports, news), location
- Engagement: RSVP, comments, sharing, calendar sync
- Notifications: advance warning (7 days), event day reminder
- Analytics: RSVP counts, notification open rate
- Schema: title, date, time, location (GPS), image, description, host

## Version Deprecation Process

1. **Release v(n+1)** with documentation of changes
2. **Notify users** 90 days before sunset
3. **Monitor v(n) usage** via metrics
4. **Support phase**: accept requests, route to v(n+1) with shim if possible
5. **Sunset**: return 410 Gone after deprecation window
