# Release PR - Template

Title: chore(release): v{{VERSION}}

Body:

## Summary

Release v{{VERSION}} - {{DATE}}

## Changes

- Generated changelogs (see CHANGELOG*.md)
- Version bump in {{VERSION_FILE}}

## Release notes

See handoff/release-notes.md

## Checklist
- [ ] Version file updated
- [ ] Changelog updated for all supported languages
- [ ] SBOM generated and uploaded to artifact store
- [ ] Tests green
- [ ] CI publish secrets configured
- [ ] Rollback plan documented in handoff/release-notes.md
