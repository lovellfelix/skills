Acceptance Criteria Template

Purpose
- Provide a concise, testable list of conditions that must be true for a story or feature to be accepted.

Format
- Given <precondition>
- When <action>
- Then <observable outcome>

Example
- Given a logged-in user with a verified email
- When they publish a new post with an image
- Then the post appears in their feed within 30 seconds and the image displays correctly on mobile and web.

Checklist
- Functional: end-to-end behavior satisfied (API + Android + Dashboard)
- Non-functional: latency, error rate, size limits
- Security & privacy: PII handling and auth enforced
- Observability: metrics, logs, traces instrumented
- Rollout: feature flag present and can be toggled per environment

Notes
- Keep criteria small and measurable. Avoid subjective language.