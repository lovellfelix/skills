---
name: release-notes
description: "Use when drafting or refining changelog entries and release notes from commits, PRs, or code changes."
metadata:
  version: 1.0.0
  portable: true
  tags: [release, changelog, version, documentation]
---

# Release Notes

Extract meaningful changes from commit history and PRs, categorize them, and generate user-friendly release notes.

## Change Categories

| Category | Description |
|----------|------------|
| Features | New capabilities |
| Fixes | Bug fixes |
| Breaking | Changes requiring user action |
| Deprecations | Features being removed |
| Performance | Optimizations |
| Security | Patches, CVE fixes |

## Changelog Format (Keep a Changelog)

```markdown
## [2.5.0] - 2024-03-20

### Added
- Batch export API for bulk operations

### Changed
- Minimum Node.js version bumped to 18.0.0

### Deprecated
- `/api/v1/export` endpoint (use `/api/v2/export`)

### Fixed
- Memory leak in event listener cleanup

### Security
- Updated dependencies to patch CVE-2024-1234
```

## User-Facing Release Notes

```markdown
## Version 2.5.0 (March 20, 2024)

### New Features
- **Batch API for exports**: Export up to 10,000 records in a single request

### Bug Fixes
- Fixed timezone handling in scheduled reports

### Breaking Changes
- Minimum Node.js version is now 18.0.0

### Migration Guide
See MIGRATION.md for upgrading from 2.4.x
```

## Best Practices

- **User-centric language**: write for users, not developers
- **Be specific**: "Fixed timeout issue" → "Fixed 30-second timeout on large exports"
- **Highlight impact**: help users quickly find relevant changes
- **Breaking changes first**: separate from bug fixes, include migration steps
- **Skip noise**: not every internal fix needs a mention; test with "would a paying customer care?"
- **Link to docs**: reference migration guides, CVEs, deprecation notices
- **Semantic versioning**: MAJOR.MINOR.PATCH

## Workflow

1. Extract changes: `git log v2.4.0..HEAD --oneline`
2. Categorize by type (features, fixes, breaking, etc.)
3. Assess user impact for each change
4. Write user-friendly descriptions
5. Generate changelog entry + release notes

## See Also

For the full release workflow (versioning, tagging, publishing), use the `release-skills` skill.
