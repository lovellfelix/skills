# Memory Record Patterns

These examples show high-signal records that remain useful across sessions.

## Workflow decision record

```json
{
  "context_key": "task:auth-middleware",
  "context_type": "decision",
  "context_value": "Chose stateless token validation to avoid shared session cache. Next: add expiry drift tests.",
  "metadata": {
    "owner": "backend",
    "confidence": "high"
  }
}
```

## Blocker record

```json
{
  "context_key": "blocker:staging-secrets",
  "context_type": "blocker",
  "context_value": "Cannot run staging integration tests until secrets are provisioned by platform. Next: re-run test suite after handoff from platform.",
  "metadata": {
    "owner": "platform",
    "status": "waiting"
  }
}
```

## Handoff record

```json
{
  "context_key": "handoff:2026-03-20-auth",
  "context_type": "handoff",
  "context_value": "Completed middleware refactor and unit coverage. Pending: integration tests + docs update. Resume with: make test-integration-auth.",
  "metadata": {
    "related": ["task:auth-middleware", "blocker:staging-secrets"]
  }
}
```
