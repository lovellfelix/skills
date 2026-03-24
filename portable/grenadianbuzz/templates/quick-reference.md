# GrenadianBuzz API Quick Reference

Fast reference card for API endpoint design, grounded in production patterns.

## Feature Checklist (Start Here)

When designing a new API for GrenadianBuzz, use this checklist to ensure completeness:

### Core Endpoint

- [ ] **GET** - Retrieve (with filters, pagination via $skip/$limit)
- [ ] **POST** - Create (with validation, return 201 + resource)
- [ ] **PATCH** - Update partial (not PUT)
- [ ] **DELETE** - Remove (return 204 No Content)

### Filters & Search

- [ ] Category filter (`?category=news`)
- [ ] Date range (`?from=2026-01-01&to=2026-02-28`)
- [ ] Status filter (`?status=published`)
- [ ] Offset pagination (`?$skip=0&$limit=50`)
- [ ] Sort options (`?$sort[published_at]=-1`)

### Engagement (if applicable)

- [ ] Reactions endpoint (`POST /v1/interactions`, types: flower, candle, heart, prayer, rose)
- [ ] Get interactions (`GET /v1/interactions?contentId=...&contentType=article`)
- [ ] Comments endpoint (`POST /v1/comments`, GET `/v1/comments?parent_id=...`)

### Moderation

- [ ] Include `is_flagged` in all content responses
- [ ] Include `moderation_status` enum in admin payloads
- [ ] Separate `/moderation/` endpoints (admin-only)
- [ ] Audit trail tracking

### Analytics

- [ ] View/engagement counts in payloads
- [ ] Aggregation endpoint (`?stats=events|trending|top`)
- [ ] Creator dashboard (if applicable)

### Authentication

- [ ] Choose auth: JWT, OAuth, API Key
- [ ] Define role requirements per endpoint
- [ ] Public vs protected endpoints clear

### Response Structure

- [ ] Single item: `{ "data": { ... } }`
- [ ] List: `{ "data": [...], "metadata": { "has_more", "next_cursor" } }`
- [ ] Error: `{ "name", "code", "message", "data" }`

### Error Handling

- [ ] Validation errors (422)
- [ ] Auth errors (401/403)
- [ ] Rate limit (429 with X-RateLimit-* headers)
- [ ] Not found (404)

---

## Endpoint Templates

### Read Endpoint (GET)

```
GET /v2/<resource>/:id
Authorization: <if required>

Response (200):
{
  "data": {
    "id": "<uuid>",
    "title": "...",
    "status": "published|draft|archived",
    "is_flagged": false,
    "<metric>_count": 0,
    "created_at": "2026-02-07T10:00:00Z",
    "updated_at": "2026-02-07T10:00:00Z"
  }
}
```

### List Endpoint (GET with Pagination)

```
GET /v2/<resource>?category=...&status=...&$limit=50&$skip=0&$sort[published_at]=-1
Authorization: <if required>

Response (200):
{
  "total": 1250,
  "limit": 50,
  "skip": 0,
  "data": [
    { "id": "...", "title": "...", ... },
    ...
  ]
}
```

### Create Endpoint (POST)

```
POST /v2/<resource>
Authorization: Bearer <token> (admin role)
Content-Type: application/json
Idempotency-Key: <uuid> (optional)

Request:
{
  "title": "...",
  "content": "...",
  "category_id": "<uuid>",
  "status": "draft|published"
}

Response (201):
{
  "data": {
    "id": "<new-uuid>",
    "title": "...",
    "created_at": "2026-02-07T10:00:00Z",
    ...
  }
}
```

### Update Endpoint (PATCH)

```
PATCH /v2/<resource>/:id
Authorization: Bearer <token> (admin role)
Content-Type: application/json

Request:
{
  "title": "...",
  "status": "published"
}

Response (200):
{
  "data": {
    "id": "<id>",
    "title": "...",
    "updated_at": "2026-02-07T11:00:00Z",
    ...
  }
}
```

### Delete Endpoint (DELETE)

```
DELETE /v2/<resource>/:id
Authorization: Bearer <token> (admin role)

Response (204): No Content
```

---

## Reaction Engagement Pattern

For articles, events, or posts supporting reactions:

### Add Reaction (Like or Reaction Type)

```
POST /v1/interactions
Authorization: Bearer <token>

{
  "contentId": "<uuid>",
  "contentType": "article|event|obituary|comment",
  "interactionType": "like|reaction",
  "reactionType": "flower|candle|heart|prayer|rose"  // Only if interactionType=reaction
}

Response (201):
{
  "_id": "<interaction-id>",
  "contentId": "<uuid>",
  "contentType": "article",
  "interactionType": "reaction",
  "reactionType": "heart",
  "userId": "<user-id>",
  "userName": "diaspora_user",
  "userAvatar": "...",
  "createdAt": "2026-02-07T10:00:00Z"
}
```

### Get Interactions List

```
GET /v1/interactions?contentId=<id>&contentType=article&limit=50

Response (200):
{
  "total": 71,
  "limit": 50,
  "skip": 0,
  "data": [
    {
      "_id": "<interaction-id>",
      "contentId": "<id>",
      "contentType": "article",
      "interactionType": "reaction",
      "reactionType": "heart",
      "userId": "<user-id>",
      "userName": "diaspora_user",
      "userAvatar": "...",
      "createdAt": "2026-02-07T10:00:00Z"
    },
    ...
  ]
}
```

---

## Moderation Pattern

For content requiring human review:

### Moderation Statuses

```
active          - Published, no issues
flagged         - Awaiting review (auto-flagged or user-reported)
review_pending  - Admin assigned, in progress
approved        - Reviewed and cleared
removed         - Removed per policy
needs_revision  - Author needs to fix, then resubmit
```

### Include in Content Payloads

```json
{
  "id": "<uuid>",
  "title": "...",
  "is_flagged": false,                    // Safe default, always include
  "moderation_status": "active",          // Full status (admin-only payload)
  "moderation_reason": "...",             // Why flagged (admin-only)
  "reviewed_at": "2026-02-07T11:00:00Z"  // Timestamp of review
}
```

### Admin Moderation Endpoints

```
GET /moderation/queue?status=flagged&limit=50
  → List pending reviews

GET /moderation/<resource>/<id>
  → View specific item with full metadata

PATCH /moderation/<resource>/<id>
  → Update status and add reviewer notes
  {
    "moderation_status": "approved|removed",
    "reviewer_notes": "..."
  }

GET /moderation/<resource>/<id>/audit
  → View audit trail of all actions
```

---

## Filter & Sort Examples

### Standard Filters

| Filter | Endpoint | Values |
|--------|----------|--------|
| `category` | Articles, Events | news, events, radio, obituaries, cultural |
| `status` | Any content | published, draft, archived, removed |
| `source_id` | Articles | `<uuid>` of news source |
| `date_from` | Any time-based | `2026-01-01` (ISO 8601) |
| `date_to` | Any time-based | `2026-02-28` (ISO 8601) |
| `is_flagged` | Content | `true`, `false` |

### Standard Sorts

| Sort | Use Case | Note |
|------|----------|------|
| `published_at` | Reverse chronological (default) | Newest first |
| `trending` | Engagement-based | Last 24-48h interactions |
| `top_users` | Leaderboard | Top creators/contributors |
| `comments_count` | Discussion threads | Most discussed |
| `engagement_rate` | Quality signal | Interactions / views |

---

## Response Headers

### Standard Response Headers

```
X-Request-ID: 550e8400-e29b-41d4-a716-446655440000
  → Unique request ID for tracing

X-Response-Time: 245ms
  → Latency measurement

X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1707391200
  → Rate limit state

Deprecation: true
Sunset: Wed, 01 May 2026 00:00:00 GMT
Link: </v2/articles>; rel="successor-version"
  → Deprecation notice (on legacy endpoints)

Cache-Control: public, max-age=300
  → Cache directive for GET responses
```

---

## Error Response Examples

### Validation Error (422)

```json
{
  "name": "UnprocessableEntity",
  "code": 422,
  "message": "Validation failed",
  "data": {
    "fields": {
      "title": "Title is required",
      "image_url": "Must be a valid URL",
      "category_id": "Category not found"
    }
  }
}
```

### Auth Error (401)

```json
{
  "name": "NotAuthenticated",
  "code": 401,
  "message": "Authentication required"
}
```

### Permission Error (403)

```json
{
  "name": "Forbidden",
  "code": 403,
  "message": "Admin role required"
}
```

### Rate Limit (429)

```
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1707391200

{
  "name": "TooManyRequests",
  "code": 429,
  "message": "Rate limit exceeded (1000 requests/min)"
}
```

### Not Found (404)

```json
{
  "name": "NotFound",
  "code": 404,
  "message": "Article not found"
}
```

---

## Testing Checklist

Before deploying a new endpoint:

- [ ] Happy path: Create → Read → Update → Delete
- [ ] Pagination: First page, middle pages, last page, cursor stability
- [ ] Filters: Apply single filter, multiple filters, no results
- [ ] Auth: No auth (401), wrong role (403), valid token (200)
- [ ] Validation: Missing required fields (422), invalid format (400)
- [ ] Rate limiting: Exceed limit, observe headers
- [ ] Moderation: Flagged content excluded from public endpoints
- [ ] Concurrency: Simultaneous requests, no race conditions
- [ ] Idempotency: POST with same Idempotency-Key returns same result
- [ ] Performance: Latency < SLO (typically <500ms p50, <2s p99)

---

## Code Examples

### JavaScript (fetch)

```javascript
// Get articles with filter
const articles = await fetch('/v2/articles?category=news&$limit=50')
  .then(r => r.json())
  .then(res => res.data);

// Post reaction
await fetch('/v1/interactions', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    contentId: articleId,
    contentType: 'article',
    interactionType: 'reaction',
    reactionType: 'heart'
  })
});

// Get interactions list
const interactions = await fetch(`/v1/interactions?contentId=${articleId}&contentType=article`)
  .then(r => r.json())
  .then(res => res.data);
```

### Python (requests)

```python
import requests

# Get articles
resp = requests.get('/v2/articles', params={'category': 'news', '$limit': 50})
articles = resp.json()['data']

# Post reaction
resp = requests.post('/v1/interactions',
  headers={'Authorization': f'Bearer {token}'},
  json={
    'contentId': article_id,
    'contentType': 'article',
    'interactionType': 'reaction',
    'reactionType': 'heart'
  }
)

# Get interactions list
resp = requests.get(f'/v1/interactions?contentId={article_id}&contentType=article')
interactions = resp.json()['data']
```

### cURL

```bash
# Get articles
curl 'https://api.grenadianbuzz.com/v2/articles?category=news&$limit=50'

# Post reaction (requires auth)
curl -X POST 'https://api.grenadianbuzz.com/v1/interactions' \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "contentId": "<article-id>",
    "contentType": "article",
    "interactionType": "reaction",
    "reactionType": "heart"
  }'

# Get interactions list
curl 'https://api.grenadianbuzz.com/v1/interactions?contentId=<article-id>&contentType=article'
```

---

## Activation & Portability

This skill remains **portable** (reusable for any project) while **grounded in GrenadianBuzz domain**:

- **Portable**: Templates, patterns, and examples apply to any API project
- **Grounded**: GrenadianBuzz specifics (reactions, moderation, analytics, diaspora context) inform defaults and best practices
- **Safe**: Personal machine only; no secrets or overly specific internal details

Use the quick reference when designing endpoints; refer to full templates and domain checklist for comprehensive PRDs.
