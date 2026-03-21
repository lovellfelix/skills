---
name: release-notes
description: Draft and refine changelog and release notes from commits, PRs, and changes.
version: 0.1.0
portable: true
tags: [release, changelog, version, notes, documentation]
---

# Release Notes Skill

## What I Do

* Extract meaningful changes from commit history and pull requests
* Categorize changes (features, fixes, breaking changes, deprecations)
* Generate user-friendly release notes and changelog entries
* Highlight migration requirements or breaking changes
* Create structured version release summaries

## When to Use Me

* Before shipping a new version or release
* When drafting release announcements or blog posts
* To organize CHANGELOG.md updates
* When communicating changes to users or customers
* To ensure release notes are clear and complete

## How I Work

### 1. Change Extraction & Categorization

I identify and organize changes from git history:

* **Features**: New capabilities (e.g., "Add batch export API")
* **Fixes**: Bug fixes (e.g., "Fix memory leak in event handler")
* **Breaking Changes**: Changes that require user action
* **Deprecations**: Features being removed or changed
* **Performance**: Optimization or efficiency improvements
* **Security**: Security patches or vulnerability fixes
* **Documentation**: Docs updates (usually excluded from user notes)

### 2. User Impact Assessment

I evaluate what users need to know:

* Does this require code changes? (Breaking change)
* Is migration needed? (Deprecation path)
* Is this just a bug fix? (Usually non-critical)
* Is this a security fix? (Highlight urgency)
* Will users see behavioral changes? (Document clearly)

### 3. Release Notes Generation

I create clear, customer-focused release notes:

```
## Version 2.5.0 (March 20, 2024)

### New Features
- **Batch API for exports**: Export up to 10,000 records in a single request
- **Custom fields in webhooks**: Webhooks now include user-defined metadata

### Bug Fixes
- Fixed timezone handling in scheduled reports
- Corrected pagination offset in list endpoints

### Breaking Changes
- Deprecated `/api/v1/export` endpoint (use `/api/v2/export` instead)
- Minimum Node.js version is now 18.0.0

### Migration Guide
See MIGRATION.md for upgrading from 2.4.x
```

### 4. Changelog Entry Format

I maintain consistent CHANGELOG.md entries following standard conventions:

```markdown
## [2.5.0] - 2024-03-20

### Added
- Batch export API for bulk operations
- Custom fields support in webhook payloads

### Changed
- Minimum Node.js version bumped to 18.0.0
- API response timeout increased to 30s

### Deprecated
- `/api/v1/export` endpoint (use `/api/v2/export`)

### Fixed
- Memory leak in event listener cleanup
- Timezone offset calculation

### Security
- Updated dependencies to patch CVE-2024-1234
```

### 5. Version Summary

I extract key information from changes:

* Major/minor/patch justification
* High-level summary (1-2 sentences)
* Key user-facing changes
* Links to documentation or migration guides

## Usage Examples

### Generate Release Notes from Commits

```
Skill: release-notes
Input: Commit log from last release (git log v2.4.0..HEAD)
Output: Categorized changes with user-friendly descriptions
```

### Create Changelog Entry

```
Skill: release-notes
Input: List of PRs merged, commit messages
Output: CHANGELOG.md compatible entry
```

### Highlight Breaking Changes

```
Skill: release-notes
Input: API changes, deprecated endpoints, config changes
Output: Migration guide with upgrade instructions
```

### Announce Release

```
Skill: release-notes
Input: Release notes, version, release date
Output: Marketing-friendly announcement for blog/email
```

## Best Practices

* **User-centric language**: Write for users, not developers
* **Highlight impact**: Help users quickly find relevant changes
* **Be specific**: "Fixed timeout issue" → "Fixed 30-second timeout on large exports"
* **Include links**: Point to docs, migration guides, deprecation notices
* **Version consistently**: Use semantic versioning (MAJOR.MINOR.PATCH)
* **Separate concerns**: Breaking changes above bug fixes
* **Provide examples**: Show how to use new features or migrate old code
* **Link dependencies**: Reference security CVEs, GitHub issues

## Practical Examples

### From Commits to Release Notes
You have 24 commits since v1.5.0:
```
Input: git log v1.5.0..HEAD --oneline
Output: Grouped features, fixes, breaking changes with user language
```

### Migration Guide for Breaking Change
You're removing an API endpoint in v2.0:
```
Input: Old endpoint /api/users/export, new endpoint /api/batch/export
Output: Step-by-step migration example, deprecation timeline, side-by-side code
```

### Security Release Urgency
You patched CVE-2024-1234 affecting auth:
```
Input: CVE details, affected versions, patch version, workaround if delayed
Output: Release notes emphasizing urgency, clear upgrade path
```

### Feature Announcement for Marketing
You built a new dashboard that saves users 5 hours/week:
```
Input: Feature details, time savings, use cases
Output: Benefit-first announcement ready for blog post or email
```

## Troubleshooting

**"My commits are a mess; I can't write good release notes"**
Look at PRs instead of commits. PR titles are usually more coherent.
If still messy, ask yourself: "What did the user experience change?" Not every commit merits mention.

**"Breaking change—how do I not panic users?"**
Lead with the benefit or necessity. Provide migration path upfront.
Example: "We upgraded auth to OpenID for better security. See migration guide → for 15-minute update."

**"How much detail do release notes need?"**
Write two versions: one for users (what changed, why, impact), one for devs (technical details, config changes).
Let users link to the technical version if they need it.

**"Should I mention every bug fix?"**
No. List the important ones. Cosmetic or internal fixes go in CHANGELOG only.
Test your rule: would this fix matter to a paying customer?

## Common Sections

* **New Features**: Ordered by user impact
* **Bug Fixes**: Most important first
* **Breaking Changes**: Always clear about impact and migration
* **Deprecations**: Timeline for removal
* **Performance**: Quantifiable improvements
* **Security**: CVE references, upgrade urgency
* **Contributors**: Attribution for community contributions
* **Links**: Documentation, migration guide, known issues

## Output Formats

* **User-facing (Email/Blog)**: Casual, benefit-focused
* **Technical (GitHub)**: Precise, technical detail
* **CHANGELOG.md**: Consistent format, all changes
* **Migration Guide**: Step-by-step upgrade instructions
