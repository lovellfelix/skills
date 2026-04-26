Dashboard Testing Guide

Purpose
- Ensure dashboards (moderation, analytics, creator tools) are accurate, performant, and useful for product and ops.

Test Types
1. Data Accuracy
   - Verify dimensions and metrics (e.g., publishes, flags, approvals) match source-of-truth (events store/warehouse).
   - Test aggregation windows (UTC vs local timezone) and attribution logic.

2. Latency & Freshness
   - Validate how quickly events surface in dashboards (near-real-time vs hourly batches).
   - Alert if dashboard lag exceeds SLA (e.g., 5 minutes for moderation streams).

3. Access Control
   - Verify role-based visibility for sensitive metrics (PII counts, revenue).
   - Ensure API keys and embedded dashboards respect auth.

4. Visual & UX Tests
   - Smoke test for rendering (no missing charts) across supported browsers.
   - Test filter and drilldown flows for common queries.

5. Load & Performance
   - Load test dashboard queries that hit the warehouse or analytic endpoints to ensure they stay within quotas.

6. Regression & Snapshot Tests
   - Capture screenshots of critical dashboards for visual regression.
   - Automated checks for chart presence and basic counts.

7. Alerting Integration
   - Validate that alerts are firing for top-line trends (drops or spikes) and have correct runbooks.

Acceptance Criteria
- Key KPIs match warehouse within tolerance (+/- 1-3%).
- Dashboards render in <2s for common queries; complex queries <10s.
- Role-based access validated for at least one user per role.

Owner & Cadence
- Dashboard owner maintains tests; run daily smoke checks with post-deploy validation.