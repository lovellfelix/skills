# GrenadianBuzz API Patterns & Real-World Examples

**Reference for API/PRD design based on production GrenadianBuzz backend (39+ services, FeathersJS v4.5, URL versioning)**

---

## Table of Contents

1. [Versioning Strategy](#versioning-strategy)
2. [Standard Response Formats](#standard-response-formats)
3. [Error Handling](#error-handling)
4. [Pagination & Cursors](#pagination--cursors)
5. [Engagement Endpoints](#engagement-endpoints)
6. [Moderation Workflows](#moderation-workflows)
7. [Analytics Aggregation](#analytics-aggregation)
8. [Authentication Strategies](#authentication-strategies)
9. [Real API Examples](#real-api-examples)
10. [Deprecation & Migration](#deprecation--migration)

---

## Versioning Strategy

GrenadianBuzz uses **URL-based versioning** with three active versions:

### Version Timeline

| Version | Status | Endpoint | Timeline |
|---------|--------|----------|----------|
| Legacy | Deprecated | `/uploads`, `/emails`, `/users`, `/settings` | Migrate to v2/v3 |
| v1 | Stable | `/v1/analytics`, `/v1/comments`, `/v1/interactions` | Long-term support |
| v2 | Current | `/v2/articles`, `/v2/emails`, `/v2/uploads` | Preferred for new features |
| v3 | Latest | `/v3/articles`, `/v3/emails` | Newest implementations |

### Rules

- **New features** always go to the latest version
- **Bug fixes** and security patches applied to all active versions
- **Minimum 90-day deprecation window** before sunset
- **Unversioned endpoints** (legacy) can be phased out faster with migration tooling

### Migration Example

When upgrading from v1 to v2 articles API:

```bash
# Before: clients use v1
GET /v1/news/feeds

# Transition (3 months): v2 available, v1 still works
GET /v2/news/feeds  # New clients move here
GET /v1/news/feeds  # Old clients still work

# After deprecation: v1 returns 410 Gone
GET /v1/news/feeds  # 410 Gone with migration link in header
Location: /v2/news/feeds
```

---

## Standard Response Formats

### Success Response (Implicit)

FeathersJS wraps responses in a data envelope by default:

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Grenada Independence Day Celebration",
    "content": "...",
    "published_at": "2026-02-07T10:00:00Z",
    "status": "published",
    "is_flagged": false,
    "comments_count": 12,
    "like_count": 45,
    "created_at": "2026-02-07T10:00:00Z",
    "updated_at": "2026-02-07T10:00:00Z"
  }
}
```

### List Response with Pagination

```json
{
  "data": [
    { "id": "...", "title": "...", ... },
    { "id": "...", "title": "...", ... }
  ],
  "total": 1250,
  "limit": 20,
  "skip": 0,
  "metadata": {
    "has_more": true,
    "next_cursor": "eyJwb3NpdGlvbiI6IDIwfQ=="
  }
}
```

### Minimal Response (No Body)

Status 204 No Content (used for DELETE operations):

```
HTTP/1.1 204 No Content
```

---

## Error Handling

### Error Response Schema

```json
{
  "name": "BadRequest",
  "code": 400,
  "className": "bad-request",
  "message": "Invalid input",
  "data": {
    "fields": {
      "title": "Title is required",
      "image_url": "Must be a valid URL"
    }
  },
  "errors": []
}
```

### Common Error Codes

| Code | Scenario | Example Message |
|------|----------|-----------------|
| 400 | Validation error | "Title must be 3-500 characters" |
| 401 | Missing/invalid auth | "Authentication required" |
| 403 | Insufficient permissions | "Admin role required" |
| 404 | Resource not found | "Article not found" |
| 409 | Conflict | "Article with source_url already exists" |
| 422 | Unprocessable | "Cannot delete published article" |
| 429 | Rate limit | "Rate limit: 1000 requests/min exceeded" |
| 500 | Server error | "Internal server error" |
| 503 | Service degraded | "Database connection timeout" |

### Rate Limit Headers

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1707304800
```

---

## Pagination & Cursors

### Cursor Strategy

GrenadianBuzz uses **opaque cursor pagination** for feed stability (not offset/limit):

```
Request:
GET /v2/articles?limit=20&cursor=eyJwb3NpdGlvbiI6IDEwMDB9

Response:
{
  "data": [...],
  "metadata": {
    "limit": 20,
    "has_more": true,
    "next_cursor": "eyJwb3NpdGlvbiI6IDEwMjB9"
  }
}
```

### Why Cursors?

| Approach | Pros | Cons | GrenadianBuzz Use |
|----------|------|------|-------------------|
| **Offset/Limit** | Simple to implement | Unstable with new inserts (duplicate/skip items) | Legacy only |
| **Cursor** | Stable ordering, handles mutations | Clients can't jump to page 5 | Feed APIs (v2/v3 articles) |
| **Keyset Pagination** | Scalable, efficient | Complex implementation | Future optimization |

### Implementation Detail

Cursor encodes `{ published_at, id }` pair:

```javascript
// Encoding
const cursor = Buffer.from(JSON.stringify({
  published_at: "2026-02-07T10:00:00Z",
  id: "550e8400-..."
})).toString('base64');

// Decoding
const decoded = JSON.parse(Buffer.from(cursor, 'base64').toString());
```

---

## Engagement Endpoints

### Reaction System

Emoji reactions available: 👍 ❤️ 🕯️ 💖 🌹 🙏

#### Add Reaction (Idempotent Toggle)

```
POST /v1/interactions
Content-Type: application/json
Authorization: Bearer <jwt>

{
  "content_id": "550e8400-e29b-41d4-a716-446655440000",
  "content_type": "article",
  "reaction": "👍"
}

Response (201 Created or 200 OK if toggling):
{
  "id": "interaction-123",
  "user_id": "user-456",
  "reaction": "👍",
  "created_at": "2026-02-07T10:00:00Z"
}
```

#### Get Reaction Counts (Lightweight)

```
GET /v1/interactions/counts/550e8400-e29b-41d4-a716-446655440000

Response (200):
{
  "content_id": "550e8400-e29b-41d4-a716-446655440000",
  "reaction_counts": {
    "👍": 45,
    "❤️": 12,
    "🕯️": 8,
    "💖": 3,
    "🌹": 1,
    "🙏": 2
  },
  "total_interactions": 71,
  "user_reaction": "👍"  // If authenticated
}
```

#### List All Reactions on Content

```
GET /v1/interactions?content_id=...&content_type=article&limit=50

Response:
{
  "data": [
    {
      "id": "...",
      "user_id": "...",
      "user": {
        "id": "...",
        "username": "diaspora_user",
        "avatar_url": "..."
      },
      "reaction": "👍",
      "created_at": "2026-02-07T10:00:00Z"
    },
    ...
  ],
  "metadata": { "has_more": true, "next_cursor": "..." }
}
```

### Comments Endpoint

```
POST /v1/comments
Authorization: Bearer <jwt>

{
  "parent_id": "550e8400-e29b-41d4-a716-446655440000",
  "parent_type": "article",
  "text": "Great article about Carnival preparations!",
  "reply_to_user_id": "user-456"  // Optional, for threaded replies
}

Response (201):
{
  "id": "comment-789",
  "user_id": "...",
  "user": { "id": "...", "username": "..." },
  "text": "...",
  "created_at": "2026-02-07T10:00:00Z",
  "moderation_status": "active",
  "replies_count": 0
}
```

#### Get Comment Thread

```
GET /v1/comments?parent_id=...&parent_type=article&limit=20

Response:
{
  "data": [
    {
      "id": "...",
      "user": { "username": "..." },
      "text": "Great article!",
      "replies_count": 3,
      "moderation_status": "active",
      "created_at": "2026-02-07T10:00:00Z"
    },
    ...
  ],
  "metadata": { "has_more": true }
}
```

---

## Moderation Workflows

### Moderation Status Lifecycle

```
Article Created
    ↓
    ├─→ Auto-flagged? (spam filters, regex)
    │   ↓
    │   Review Pending (24h SLA)
    │   ├─→ Approved → Published
    │   ├─→ Removed → (visible to admins only)
    │   └─→ Needs Revision → Reviewer adds notes
    │
    └─→ Published
        ├─→ User reports content
        │   ↓
        │   Flagged → Review Pending
        │
        └─→ Moderator manually flags
            ↓
            Review Pending → Approved or Removed
```

### Moderation Queue (Admin Only)

```
GET /moderation/queue?status=flagged&limit=50
Authorization: Bearer <admin_jwt>

Response:
{
  "data": [
    {
      "id": "article-123",
      "type": "article",
      "title": "...",
      "content_preview": "...",
      "moderation_status": "flagged",
      "flag_reason": "suspected_spam",
      "flagged_at": "2026-02-07T10:00:00Z",
      "flagged_by": "user-456",
      "reviewer_notes": null,
      "assigned_to": null
    },
    ...
  ]
}
```

### Moderate Content (Update Status)

```
PATCH /moderation/article-123
Authorization: Bearer <admin_jwt>

{
  "moderation_status": "approved",
  "reviewer_notes": "Content is legitimate; user complaint was unfounded."
}

Response (200):
{
  "id": "article-123",
  "moderation_status": "approved",
  "reviewed_by": "admin-user-id",
  "reviewed_at": "2026-02-07T11:00:00Z",
  "reviewer_notes": "..."
}
```

### Audit Trail (Admin Only)

```
GET /moderation/article-123/audit
Authorization: Bearer <admin_jwt>

Response:
{
  "data": [
    {
      "timestamp": "2026-02-07T10:05:00Z",
      "action": "flagged",
      "actor_id": "user-456",
      "actor_type": "user",
      "reason": "suspected_spam",
      "notes": null
    },
    {
      "timestamp": "2026-02-07T10:30:00Z",
      "action": "moderation_status_change",
      "actor_id": "admin-user-id",
      "actor_type": "admin",
      "old_status": "flagged",
      "new_status": "approved",
      "notes": "Content is legitimate..."
    }
  ]
}
```

---

## Analytics Aggregation

### Multi-Stat Endpoint

GrenadianBuzz Analytics API supports aggregation modes:

```
GET /v1/analytics?stats=events
GET /v1/analytics?stats=daily
GET /v1/analytics?stats=monthly
GET /v1/analytics?stats=trending
GET /v1/analytics?stats=top
```

### Events Aggregation

```
GET /v1/analytics?stats=events&from=2026-02-01&to=2026-02-28

Response:
{
  "data": {
    "total_events": 1250000,
    "by_event_type": {
      "view": 750000,
      "read": 350000,
      "comment": 75000,
      "like": 60000,
      "share": 15000
    },
    "by_content_type": {
      "article": 900000,
      "event": 200000,
      "obituary": 150000
    }
  }
}
```

### Trending Content

```
GET /v1/analytics?stats=trending&limit=10

Response:
{
  "data": [
    {
      "rank": 1,
      "content_id": "article-550e8400",
      "title": "Grenada Carnival 2026 Lineup Announced",
      "content_type": "article",
      "score": 450,  // Interaction score
      "views_24h": 5000,
      "interactions_24h": 450,
      "growth_rate": 1.2  // 20% growth vs yesterday
    },
    ...
  ]
}
```

### Top Users (Leaderboard)

```
GET /v1/users/top?limit=10&metric=articles_published

Response:
{
  "data": [
    {
      "rank": 1,
      "user_id": "user-123",
      "username": "grenada_news_hub",
      "avatar_url": "...",
      "metric_value": 245,  // articles_published count
      "followers": 12000,
      "engagement_score": 8500
    },
    ...
  ]
}
```

### Creator Dashboard Analytics

```
GET /v1/creators/user-123/analytics?from=2026-02-01&to=2026-02-28

Response:
{
  "data": {
    "articles_published": 12,
    "total_views": 45000,
    "total_interactions": 3200,
    "avg_engagement_rate": 0.071,  // 7.1%
    "top_articles": [
      {
        "id": "...",
        "title": "...",
        "views": 8500,
        "interactions": 650
      },
      ...
    ],
    "daily_activity": [
      { "date": "2026-02-01", "views": 1200, "interactions": 85 },
      ...
    ]
  }
}
```

---

## Authentication Strategies

### 1. JWT (Bearer Token)

```
POST /authentication
Content-Type: application/json

{
  "strategy": "jwt",
  "accessToken": "eyJhbGc..."
}

Response (200):
{
  "accessToken": "eyJhbGc...",
  "user": {
    "id": "user-123",
    "email": "user@example.com",
    "roles": ["user", "premium"],
    "name": "John Doe"
  }
}
```

**JWT Payload**:
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "roles": ["user", "admin"],
  "iat": 1707304800,
  "exp": 1707391200,  // 1 day
  "aud": "grenadianbuzz.com",
  "iss": "feathers",
  "sub": "anonymous",
  "jti": "unique-token-id"
}
```

### 2. Local (Email/Password)

```
POST /authentication
Content-Type: application/json

{
  "strategy": "local",
  "email": "user@example.com",
  "password": "secure_password_123"
}

Response (200):
{
  "accessToken": "eyJhbGc...",
  "user": { ... }
}
```

### 3. OAuth (Google)

```
POST /authentication
Content-Type: application/json

{
  "strategy": "google-token",
  "access_token": "ya29.a0AfH6SMB..."
}

Response (200):
{
  "accessToken": "eyJhbGc...",
  "user": { ... }
}
```

### 4. API Key

```
POST /authentication
Content-Type: application/json

{
  "strategy": "apiKey",
  "token": "sk_live_4eC39HqLyjWDarhtT..."
}

OR

GET /v2/articles?token=sk_live_4eC39HqLyjWDarhtT...

OR

GET /v2/articles
X-API-Key: sk_live_4eC39HqLyjWDarhtT...
```

---

## Real API Examples

### Example 1: Create and Publish Article

```bash
# 1. Admin authenticates
curl -X POST https://api.grenadianbuzz.com/authentication \
  -H "Content-Type: application/json" \
  -d '{
    "strategy": "local",
    "email": "admin@grenadianbuzz.com",
    "password": "secure_password"
  }'

# Response
{
  "accessToken": "eyJhbGc...",
  "user": { "id": "admin-123", "roles": ["admin"] }
}

# 2. Create article
curl -X POST https://api.grenadianbuzz.com/v2/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGc..." \
  -d '{
    "title": "Grenada Independence Celebration 2026",
    "content": "This year marks another year of independence...",
    "image_url": "https://example.com/image.jpg",
    "category_id": "cat-news",
    "source_id": "source-grenada-news",
    "status": "published"
  }'

# Response
{
  "data": {
    "id": "article-550e8400",
    "title": "Grenada Independence Celebration 2026",
    "status": "published",
    "is_flagged": false,
    "created_at": "2026-02-07T10:00:00Z",
    "comments_count": 0,
    "like_count": 0
  }
}
```

### Example 2: User Engagement Flow

```bash
# 1. User reads article
curl https://api.grenadianbuzz.com/v2/articles/article-550e8400 \
  -H "Authorization: Bearer user-token"

# 2. User reacts with ❤️ (like)
curl -X POST https://api.grenadianbuzz.com/v1/interactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer user-token" \
  -d '{
    "content_id": "article-550e8400",
    "content_type": "article",
    "reaction": "❤️"
  }'

# 3. User leaves comment
curl -X POST https://api.grenadianbuzz.com/v1/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer user-token" \
  -d '{
    "parent_id": "article-550e8400",
    "parent_type": "article",
    "text": "Wonderful coverage of our independence! Thank you for keeping us connected."
  }'

# 4. Get comment thread with counts
curl "https://api.grenadianbuzz.com/v1/comments?parent_id=article-550e8400&limit=10" \
  -H "Authorization: Bearer user-token"
```

### Example 3: Moderation Workflow

```bash
# 1. Admin views flagged content queue
curl https://api.grenadianbuzz.com/moderation/queue?status=flagged \
  -H "Authorization: Bearer admin-token"

# 2. Admin reviews article in detail
curl https://api.grenadianbuzz.com/moderation/article-550e8400 \
  -H "Authorization: Bearer admin-token"

# 3. Admin approves content
curl -X PATCH https://api.grenadianbuzz.com/moderation/article-550e8400 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer admin-token" \
  -d '{
    "moderation_status": "approved",
    "reviewer_notes": "Content is legitimate; no policy violations."
  }'

# 4. View audit trail
curl https://api.grenadianbuzz.com/moderation/article-550e8400/audit \
  -H "Authorization: Bearer admin-token"
```

### Example 4: Feed with Filters and Pagination

```bash
# Get articles from News category, limit 20, default sorting (newest first)
curl "https://api.grenadianbuzz.com/v2/articles?category=news&limit=20" \
  -H "Authorization: Bearer user-token"

# Response
{
  "data": [...],
  "metadata": {
    "limit": 20,
    "has_more": true,
    "next_cursor": "eyJwb3NpdGlvbiI6IDIwfQ=="
  }
}

# Get next page using cursor
curl "https://api.grenadianbuzz.com/v2/articles?category=news&limit=20&cursor=eyJwb3NpdGlvbiI6IDIwfQ==" \
  -H "Authorization: Bearer user-token"

# Get trending articles (sort by engagement, not recency)
curl "https://api.grenadianbuzz.com/v2/articles?sort=trending&limit=10"
```

---

## Deprecation & Migration

### Deprecation Notice (v1 → v2)

When sunset planning:

1. **Announce** (Month 1): Blog post, email to API users
2. **Deprecation Header** (Month 1): Add to v1 responses
   ```
   Deprecation: true
   Sunset: Wed, 01 May 2026 00:00:00 GMT
   Link: </v2/articles>; rel="successor-version"
   ```
3. **Migration Guide** (Ongoing): Document changes, provide examples
4. **Support Phase** (Months 1-3): Monitor usage, fix bugs in both versions
5. **Sunset** (Month 4): Stop accepting v1, return 410 Gone

### Example Migration Guide: v1 to v2 Articles

| Aspect | v1 | v2 | Change |
|--------|----|----|--------|
| Endpoint | `/v1/news/feeds` | `/v2/articles` | Path renamed |
| Pagination | `?skip=0&limit=20` | `?cursor=&limit=20` | Cursor-based |
| Field | `feed_id` | `source_id` | Renamed |
| Field | `published` | `published_at` | ISO 8601 format |
| Response | Single object | Array in `.data` | Envelope structure |

### Client Migration Example

```javascript
// Before (v1)
const articles = await fetch('/v1/news/feeds?skip=0&limit=20')
  .then(r => r.json())
  .then(res => res.articles);

// After (v2)
const articles = await fetch('/v2/articles?limit=20')
  .then(r => r.json())
  .then(res => res.data);
```

---

## Additional Resources

- **Production API Endpoint Review**: See `API_ENDPOINT_REVIEW.md`
- **Domain Checklist**: See `grenadianbuzz-domain-checklist.md`
- **Data Models**: Refer to GrenadianBuzz project `docs/architecture/DATA_MODELS.md`
- **Full PRD**: GrenadianBuzz project `docs/prd/PROJECT_PRD.md`
