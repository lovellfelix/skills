# Memory Record Patterns

These examples show high-signal records that remain useful across sessions.

## Workflow decision record

```json
{
  "context_key": "project:dotfiles:decision:path-layout",
  "context_type": "decision",
  "context_value": "Chose stateless token validation to avoid shared session cache. Next: add expiry drift tests.",
  "metadata": {
    "owner": "backend",
    "confidence": "high",
    "project_path": "~/.agents/memory/projects/dotfiles/decisions.md"
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
    "status": "waiting",
    "project_path": "~/.agents/memory/projects/dotfiles/current.md"
  }
}
```

## Handoff record

```json
{
  "context_key": "handoff:dotfiles:20260320164500-memory-wave",
  "context_type": "handoff",
  "context_value": "Completed middleware refactor and unit coverage. Pending: integration tests + docs update. Resume with: make test-integration-auth.",
  "metadata": {
    "related": ["project:dotfiles:decision:path-layout", "blocker:staging-secrets"],
    "handoff_path": "~/.agents/memory/handoffs/2026/03/20260320164500-dotfiles-memory-wave.md",
    "project_current_path": "~/.agents/memory/projects/dotfiles/current.md",
    "promoted_summary_path": "~/.agents/memory/promoted/20260320164000-opencode-2026-03-20.md"
  }
}
```

## People profile record

```json
{
  "context_key": "people:profile:alex-jordan",
  "context_type": "people_profile",
  "context_value": "Preferred communication is concise async updates with action items. Works in platform team and owns staging secrets approvals.",
  "metadata": {
    "source": "~/.agents/memory/people/profiles/alex-jordan.md",
    "sensitivity": "low",
    "consent": "work-context-only"
  }
}
```

## People links record

```json
{
  "context_key": "people:links:alex-jordan",
  "context_type": "people_link_bundle",
  "context_value": "- meeting:weekly-platform-sync (session-memory key: event:2026-03-20:weekly-platform-sync)\n- task:staging-secrets-approval (session-memory key: task:platform:staging-secrets)",
  "metadata": {
    "source": "~/.agents/memory/people/links/alex-jordan.md",
    "link_targets": ["event", "task", "project"],
    "local_only": true
  }
}
```
