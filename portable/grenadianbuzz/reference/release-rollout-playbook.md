Release & Rollout Playbook

Purpose
- Step-by-step guide for safely releasing features to production with observability and rollback controls.

Pre-release
- Confirm acceptance criteria, security checklist, and contract tests are green.
- Ensure feature flags exist and default to off for risky features.
- Create release note with list of commits, migration steps, and owner contacts.

Deploy Steps
1. Build immutable artifact and tag with semantic version + git sha.
2. Deploy to staging; run full integration and smoke suites (unit, e2e, playwright, dashboard smoke).
3. Start canary: route 1-5% traffic to new version.
4. Monitor for 30 minutes (or defined window): availability, error rate, latency, business KPIs.
5. If no regressions, increase to 25%, then 50%, then 100% with monitoring windows at each step.

Rollback Criteria
- Availability drops > X% or error rate increases beyond threshold.
- Business KPI regressions (e.g., publish rate drop) correlated with deploy.
- If rollback is triggered, revert to prior artifact and mark incident; run postmortem.

Post-release
- Verify metrics have stabilized and error budget is unaffected.
- Remove temporary canary configs and update release notes.
- Postmortem any incidents and close follow-ups.

Communication
- Notify stakeholders at start, canary pass/fail, and full rollout complete.
- Provide rollback status and next steps in case of failure.

Owner
- Release owner (typically engineering lead) coordinates deploy, monitoring, and rollback decisions.