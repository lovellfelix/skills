# API PRD Template

Use this template for GrenadianBuzz API endpoint design and backend features.

## 1. Problem and Goal

- Problem statement:
- Target users/admins:
- Business outcome (user growth, engagement, revenue):
- Success metrics (measurable KPIs):

## 2. Scope

- In scope (specific endpoints, operations):
- Out of scope (what we're NOT building):
- Assumptions (data availability, third-party services):
- Constraints (timeline, auth requirements, SLOs):

## 3. Domain Model

Identify entities and relationships:

| Entity | Purpose | Key fields | Owner | Lifecycle |
|--------|---------|------------|-------|-----------|
|        |         |            |       | (draft/published/archived) |

**Example (Obituaries)**:
| Entity | Purpose | Key fields | Owner | Lifecycle |
|--------|---------|------------|-------|-----------|
| Obituary | Memorial content | name, dob, dod, bio, image_url, source | admin | published |
| Condolence | User tribute | user_id, text, reaction (🕯️/🙏) | user | active/removed |

## 4. API Contract Matrix

| Endpoint | Method | Auth | Request | Response | Errors | Notes |
|----------|--------|------|---------|----------|--------|-------|
|          |        |      |         |          |        |       |

**Common HTTP Status Codes**:
- 200 OK - Success
- 201 Created - Resource created
- 204 No Content - Success, no body
- 400 Bad Request - Invalid input
- 401 Unauthorized - Missing/invalid auth
- 403 Forbidden - Insufficient permissions
- 404 Not Found - Resource not found
- 409 Conflict - Duplicate key, state error
- 422 Unprocessable Entity - Validation error
- 429 Too Many Requests - Rate limit exceeded
- 500 Server Error - Internal error
- 503 Service Unavailable - Degraded mode

**Example (News Articles)**:
| Endpoint | Method | Auth | Request | Response | Errors | Notes |
|----------|--------|------|---------|----------|--------|-------|
| `/v2/news/articles` | GET | No | `?category=&source_id=&limit=20&cursor=` | `{ articles: [...], next_cursor: "..." }` | 400, 429 | Public feed, cursor pagination |
| `/v2/news/articles/:id` | GET | No | - | `{ id, title, content, image_url, status, comments_count, ... }` | 404 | Include moderation status |
| `/v2/news/articles` | POST | admin | `{ title, content, image_url, category_id, source_id }` | `{ id, created_at, ... }` | 400, 401, 403 | Requires admin role |
| `/v2/news/articles/:id` | PATCH | admin | `{ title?, content?, status? }` | `{ id, updated_at, ... }` | 400, 403, 404 | Audit trail logged |

## 5. Content Filtering and Sorting

For feed endpoints, support standard filters:

| Parameter | Type | Example | Notes |
|-----------|------|---------|-------|
| `category` | string | `news`, `events`, `obituaries` | Multiple values: `?category=news&category=events` |
| `source_id` | UUID | `550e8400-e29b-41d4-a716-446655440000` | Filter by news source |
| `date_from` | ISO 8601 | `2026-01-01` | Published date range |
| `date_to` | ISO 8601 | `2026-02-28` | Published date range |
| `limit` | int | `20` | Page size (default: 20, max: 100) |
| `cursor` | string | (opaque) | Cursor from previous response |
| `sort` | string | `published_at`, `trending`, `top_users` | Default: `published_at` DESC |

**Cursor Pagination Response**:
```json
{
  "articles": [...],
  "metadata": {
    "limit": 20,
    "has_more": true,
    "next_cursor": "eyJwb3NpdGlvbiI6IDEwMDB9"
  }
}
```

## 6. Engagement Endpoints

For content with user interactions, include:

- **Reactions**: 👍 ❤️ 🕯️ 💖 🌹 🙏
- **Comments**: Threaded, moderated
- **Saves**: User bookmarks
- **Shares**: Track social amplification

**Standard Engagement Paths**:
- `POST /v1/interactions` - Add reaction/like
- `DELETE /v1/interactions/:id` - Remove reaction
- `GET /v1/interactions/counts/:contentId` - Lightweight counts
- `POST /v1/comments` - Add comment
- `GET /v1/comments?parent_id=:contentId` - List comments

## 7. Moderation and Safety

Define moderation requirements early:

| Aspect | Definition |
|--------|-----------|
| **Moderation Status** | active, flagged, review_pending, approved, removed |
| **Flag Triggers** | spam, abuse, misinformation, explicit, metadata_error |
| **Review SLA** | 24 hours for flagged content |
| **Audit Trail** | Log reviewer, timestamp, action, rationale |
| **User Visibility** | Public: see `is_flagged` only; Admins: see full `moderation_status` |

**Moderation Endpoints** (admin-only):
- `GET /moderation/queue?status=flagged` - Review queue
- `PATCH /moderation/:contentId` - Update status and rationale
- `GET /moderation/:contentId/audit` - Audit trail
- `POST /moderation/:contentId/bulk-action` - Batch operations

## 8. Authentication and Authorization

- Auth strategy: JWT, OAuth, API key (specify which)
- Token expiry: (e.g., 1 day)
- Required claims in JWT: userId, roles (array), aud, iss
- Scopes or role levels: user, admin, moderator, premium
- Protected endpoints and role requirements

**Example**:
```
Auth Strategy: JWT (1-day expiry)
JWT Claims: { userId, email, roles: ["user"|"admin"|"moderator"], aud: "grenadianbuzz", iss: "feathers" }
Protected Endpoints:
  - POST /v2/articles (requires: admin)
  - PATCH /v2/articles/:id (requires: admin, owner)
  - POST /v1/interactions (requires: user)
Public Endpoints:
  - GET /v2/articles
  - GET /v1/interactions/counts/:contentId
```

## 9. Non-Functional Requirements

- Latency/SLA: (e.g., p50 <500ms, p99 <2s)
- Rate limits: per-user, per-IP, per-API-key
- Idempotency: which operations and key header (e.g., `Idempotency-Key`)
- Caching: TTL, cache-busting strategy (e.g., on publish)
- Observability: structured logs, trace IDs (X-Request-ID), metrics (prometheus)
- Error logging: what to log, PII-safe approach

**Example**:
```
Latency: p50 <500ms, p99 <2s (measured via X-Response-Time header)
Rate Limits:
  - Authenticated: 1000 req/min per user
  - Unauthenticated: 100 req/min per IP
Idempotency: POST /v2/articles?Idempotency-Key=<uuid>
Caching: GET /v2/articles cached 5 min (bust on publish)
Observability: Prometheus metrics, structured JSON logs, trace IDs in responses
```

## 10. Data Validation and Error Handling

- Required vs optional fields
- Validation rules (email format, URL validation, length limits)
- Error response schema
- Business logic errors (e.g., "Cannot delete published article")

**Example Validation**:
```json
Request (POST /v2/articles):
{
  "title": "...",           // Required, 3-500 chars
  "content": "...",         // Required, >50 chars
  "image_url": "...",       // Optional, valid URL if present
  "category_id": "...",     // Required, must exist
  "source_id": "..."        // Optional
}

Error Response (422):
{
  "code": "VALIDATION_ERROR",
  "message": "Validation failed",
  "errors": [
    { "field": "title", "message": "Too short (min 3)" },
    { "field": "image_url", "message": "Invalid URL format" }
  ]
}
```

## 11. Rollout and Migration Plan

- Backward compatibility strategy (versioning, feature flags)
- Migration steps for existing clients
- Release phases and rollback criteria
- Sunset timeline for deprecated versions (minimum 90 days notice)

**Example**:
```
Phase 1 (Day 1): Deploy v3 alongside v2, enable flag `use_v3_articles=false`
Phase 2 (Week 2): Enable flag for 10% of traffic, monitor metrics
Phase 3 (Week 4): 100% traffic to v3, document migration guide
Phase 4 (Month 3): Begin v2 deprecation notice to clients
Phase 5 (Month 6): Sunset v2, return 410 Gone
```

## 12. Analytics and Success Metrics

- Adoption metrics (API call volume, unique users)
- Engagement metrics (comment rate, reaction rate, bookmark rate)
- Performance metrics (latency, error rate, availability)
- Business impact (MAU growth, premium conversion, retention)

**Example**:
```
API Adoption:
  - Target: 50k API calls/day by Month 2
  - Metric: Request count by endpoint (Prometheus)
  
Engagement (Article Endpoints):
  - Target: 10% reaction rate, 5% comment rate
  - Metric: (sum of likes+comments / article views)
  
Performance:
  - SLO: p50 <500ms, p99 <2s, 99.5% availability
  - Metric: X-Response-Time header, Grafana dashboard

Business:
  - Target: 2% MAU increase week-over-week
  - Metric: DAU, MAU, retention (analytics service)
```

## 13. Testing Strategy

- Unit test coverage: (e.g., >80%)
- Integration tests: endpoint contracts, auth flows
- Scenario tests: happy path, error cases, edge cases
- Load testing: baseline latency at target volume

**Example Test Cases**:
```
Happy Path:
  1. GET /v2/articles?limit=20 → 200, articles array
  2. POST /v2/articles (admin auth) → 201, article with id
  3. POST /v1/interactions (user auth, idempotent) → 200, toggle reaction

Error Cases:
  1. GET /v2/articles?limit=500 → 400 (limit exceeds max)
  2. POST /v2/articles (no auth) → 401
  3. POST /v2/articles/:id (owner!=requester) → 403
  4. GET /v2/articles/:invalid_id → 404

Edge Cases:
  1. Concurrent reactions on same article (no race condition)
  2. Comment on removed article (403 or 410)
  3. Filter by non-existent category (200, empty array)
```

## 14. Documentation and Examples

- OpenAPI/Swagger spec excerpt
- Example request/response payloads (cURL, JavaScript)
- WebSocket channel definitions (if real-time)
- Webhook payload schema (if applicable)
