GrenadianBuzz CDN & Cache Policy

Purpose
- Define caching rules to balance performance and correctness for static assets, API responses, and media.

Scope
- Public website assets, app-updates, media (images/videos), API edge caching (read-only), and signed uploads.

Key Principles
- Cache by intent: static assets long TTL, user-specific content short or no-cache.
- Respect origin cache-control and use edge caching for public read-heavy endpoints.
- Use cache-busting via content hashes for static builds.

Recommended Rules
1. Static assets (JS/CSS/images built with hashes)
   - Cache-Control: public, max-age=31536000, immutable
   - CDN: aggressive edge TTL; origin revalidate not required

2. HTML pages (server-rendered landing pages)
   - Cache-Control: public, max-age=60, stale-while-revalidate=30
   - CDN: short TTL to enable fast content updates

3. API GET endpoints (public, read-only, immutable semantics)
   - Cache-Control: public, max-age=60 — only for endpoints explicitly marked cacheable
   - Use Cache-Key by path + query subset (ex: ?page, ?limit)

4. API responses with user-specific data
   - Cache-Control: private, no-store
   - CDN must not cache personal data unless signed URL or cache token present

5. Media (user-uploaded images/videos)
   - Use signed URLs for private content; CDN caches public media with long TTL
   - Invalidate on replace via new filename/content-hash

6. Authentication & Authorization
   - Do not cache responses that depend on Authorization headers unless a cache-key strategy is implemented and verified safe.

7. Purge & Invalidation
   - Prefer cache-busted filenames for predictable invalidation
   - Provide fast purge API for critical hotfixes; document purge runbook

8. Stale Content Handling
   - Use stale-while-revalidate for non-critical content to avoid origin spikes

Monitoring & Validation
- Track cache hit ratio and origin request rates per service.
- Alert when origin request rate increases unexpectedly after deploy.

Rollout Guidance
- Start conservative (short TTLs) for new or unknown endpoints and increase TTL after validation.
- Validate origin headers and ensure correct Vary/Cache-Control on production traffic.


Purge & Invalidation Runbook (examples)

When to purge
- Hotfix content change (e.g., bug in JS/CSS delivered from CDN)
- Security or legal takedown of content
- Correcting broken media after an upload/replace operation

General steps
1. Identify the minimal key(s) to purge (single object ideally).
2. Use cache-busted filename if deployed; if not, run the provider purge API for the specific path.
3. Verify origin returns updated content and CDN edge caches are refreshed (curl with no-cache header against multiple POPs).
4. Monitor origin request rate and error rates; roll back if unexpected spike or errors.

Cloudflare (example)
- Purge single URL via API:
  curl -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/purge_cache" \
    -H "Authorization: Bearer <API_TOKEN>" \
    -H "Content-Type: application/json" \
    --data '{"files":["https://www.example.com/static/app.js"]}'

- Purge by cache-tag (recommended for app deployments where you set `Cache-Tag` header):
  curl -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/purge_cache" \
    -H "Authorization: Bearer <API_TOKEN>" \
    -H "Content-Type: application/json" \
    --data '{"tags":["deploy-20260426"]}'

Fastly (example)
- Purge all (fast but aggressive):
  curl -X POST "https://api.fastly.com/service/<SERVICE_ID>/purge_all" \
    -H "Fastly-Key: <API_KEY>"

- Purge single URL by surrogate key (recommended):
  curl -X POST "https://api.fastly.com/service/<SERVICE_ID>/purge/<SURROGATE_KEY>" \
    -H "Fastly-Key: <API_KEY>"

- Purge single URL by soft purge (if supported):
  curl -X POST "https://api.fastly.com/purge/<URL-ENCODED>" \
    -H "Fastly-Key: <API_KEY>"

Cache key & header examples
- Recommended cache key composition for API read endpoints:
  - path
  - selected query params (explicit allowlist, e.g. page, limit, lang)
  - Accept-Language (only if localized variants exist)
  - a short `X-Cache-Token` header when using signed/public variants

- Examples of headers to exclude from keying (do NOT include):
  - Authorization
  - Cookie
  - Set-Cookie

- Example Cache-Key header strategy (Cloudflare Workers / Fastly VCL):
  - Key: "{{ host }}|{{ path }}|page={{ query.page }}|limit={{ query.limit }}|lang={{ header.Accept-Language }}"

- Example Vary header (for static assets):
  - Vary: Accept-Encoding

Verification commands
- Check edge content from multiple POPs (example using curl and Cloudflare trace):
  curl -H "Cache-Control: no-cache" -I https://www.example.com/static/app.js
  # Verify response headers: cf-cache-status / age / x-cache

- Check DNS & CDN config via provider CLIs (cloudflare, fastly) or provider consoles.

Notes
- Prefer surrogate-key / cache-tag patterns for safe bulk invalidation tied to deployments.
- Avoid global purges (purge_all) unless absolutely necessary; use targeted purge by URL or tag.
