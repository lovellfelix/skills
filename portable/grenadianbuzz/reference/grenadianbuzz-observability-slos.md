GrenadianBuzz Observability & SLOs

Purpose
- Define service-level objectives, monitoring, and alerting guidance for production services.

SLOs (Suggested)
- Availability (HTTP 2xx/3xx) — 99.9% monthly for core API surface
- Latency — 95th percentile < 300ms for API read endpoints; 95th < 800ms for write endpoints
- Error budget — Track per-service; alert when monthly error budget consumption > 50%

Key Metrics
- Availability (% successful requests)
- Latency percentiles (p50, p95, p99)
- Error rate (4xx, 5xx separate)
- Saturation: CPU, memory, queue length
- Throughput: requests/sec, events/sec
- Business metrics: signups/day, publishes/day, retention

Tracing & Logs
- Distributed tracing enabled for request flows (sampled).
- Correlate request ID across frontend, backend, and worker queues.
- Structured logs with severity and trace ids; use centralized logging (e.g., Loki/Datadog).

Alerting Guidelines
- Use three-tier alerts:
  1. P1 — Service down or P99 latency very high (on-call immediately)
  2. P2 — Error budget consumption > threshold, degraded latency
  3. P3 — Non-urgent operational issues (increasing origin traffic, elevated 4xx)
- Alert on symptoms, not just thresholds; include runbook link and rollback criteria.

Dashboards
- Overview dashboard: service availability, latency p95/p99, error rate, traffic trend.
- Per-endpoint heatmap for latency and errors.
- Business KPI dashboard (daily MAU, DAU, retention) for product team.

SLI Definition Examples
- Availability SLI: ratio of successful requests (2xx/3xx) to total requests for /v1/* endpoints over a rolling 28-day window.
- Latency SLI: fraction of requests with latency < 300ms for read endpoints measured at API gateway.

Runbooks
- Link runbook for: degrade gracefully, increase capacity, rollback deploy, CDN purge, DB failover.

Postmortem & Blameless Practices
- Capture timeline, impact, RCA, mitigation, and action items.
- Track follow-ups and assign owners; verify fixes in subsequent releases.