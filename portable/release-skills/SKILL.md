---
name: release-skills
description: Universal release workflow. Auto-detects version files and changelogs. Supports Node.js, Python, Rust, Claude Plugin, and generic projects. Use when user says "release", "发布", "new version", "bump version", "push", "推送".
---

# Release Skills

Universal release workflow supporting any project type with multi-language changelog.

## Quick Start

Just run `/release-skills` - auto-detects your project configuration.

## Supported Projects

| Project Type | Version File | Auto-Detected |
|--------------|--------------|---------------|
| Node.js | package.json | ✓ |
| Python | pyproject.toml | ✓ |
| Rust | Cargo.toml | ✓ |
| Claude Plugin | marketplace.json | ✓ |
| Generic | VERSION / version.txt | ✓ |

## Options

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview changes without executing |
| `--major` | Force major version bump |
| `--minor` | Force minor version bump |
| `--patch` | Force patch version bump |

## Workflow

### Step 1: Detect Project Configuration

1. Check for `.releaserc.yml` (optional config override)
2. Auto-detect version file by scanning (priority order):
   - `package.json` (Node.js)
   - `pyproject.toml` (Python)
   - `Cargo.toml` (Rust)
   - `marketplace.json` or `.claude-plugin/marketplace.json` (Claude Plugin)

   Note: some projects keep a local development stub at `.claude-plugin/marketplace.json`. For releases the tooling expects the production-ready `marketplace.json` at the repository root. If both exist the root `marketplace.json` will be preferred; if only a local stub is present treat it as draft metadata and ensure the final metadata is committed to the repo root before publishing.
   - `VERSION` or `version.txt` (Generic)
3. Scan for changelog files using glob patterns:
   - `CHANGELOG*.md`
   - `HISTORY*.md`
   - `CHANGES*.md`
4. Identify language of each changelog by filename suffix
5. Display detected configuration

(omitted: language detection, analysis, generation steps — full details in docs/release-guidelines.md)

## Checklist (Critical Artifacts)

Before publishing, ensure the following artifacts exist and are up-to-date:
- tools/release/* scripts committed (publish-npm.sh, publish-pypi.sh, publish-cargo.sh, checksum-sign.sh, github-release.sh, create-pr.sh)
- .github/workflows/release.yml configured for tag and manual dispatch
- handoff/release-notes.md (or handoff/release-note-template.md) present and filled
- CHANGELOG*.md updated for all supported languages (or follow-up translation PRs created)
- SBOM artifacts generated (sbom/spdx.json, sbom/cyclonedx.json) or pipeline step configured to generate them
- GPG/public signing keys available (or sigstore/KMS configured)
- CI secrets for registries configured: NPM_TOKEN, PYPI_API_TOKEN, CARGO_REGISTRY_TOKEN, GITHUB_TOKEN
- Rollback plan section added to handoff/release-notes.md

## Publish Steps (high-level)

1. Generate multi-language changelogs from commits since last tag (see docs/release-guidelines.md)
2. Generate SBOMs and run vulnerability scanners
3. Produce checksums and sign artifacts (tools/release/checksum-sign.sh)
4. Update version files and commit per-package/module where applicable
5. Create release PR (tools/release/create-pr.sh) with templates/pr-release-template.md as the body
6. Merge PR after approvals and CI green
7. Tag and push the release tag (vX.Y.Z)
8. CI or local runner executes publish scripts and creates GitHub release (tools/release/github-release.sh)

## Pre-release and Gating

- Pre-releases (alpha/beta/rc) MUST be marked as pre-release in GitHub and use a distinct tag (e.g., `v1.2.0-rc.1`).
- Require human approval (reviewer) for any release matching one of the following gates:
  - Major version bump
  - Breaking changes detected
  - New native binary or installer added
  - High/critical security findings from vulnerability scans
- For gated releases, create a release PR and use protected branches with required approvers.

## Credentials & Secrets

- Store publish tokens in CI secrets (GitHub Actions Secrets or vault). Do NOT hardcode tokens in scripts.
- NPM: NPM_TOKEN
- PyPI: TWINE_USERNAME and TWINE_PASSWORD (or TWINE_PASSWORD as API token)
- Cargo: CARGO_REGISTRY_TOKEN
- GitHub: GITHUB_TOKEN (for release creation and uploads)
- GPG signing: prefer project-managed keys (.keys/) or org key manager. Consider sigstore/tuf/KMS for long-lived production use.

## Monorepo Handling

- Prefer independent per-package releases when packages are independently versioned.
- CI must compute changed packages and run publish only for packages with detected changes.
- Root release should summarize per-package releases and link to per-package tags.
- Use conventional per-package changelogs under each package; the root CHANGELOG.md contains an aggregated summary.

## Rollback Strategy

- Document rollback steps in handoff/release-notes.md. Minimum elements:
  - how to redeploy previous artifact (tag and location)
  - database migration rollback steps (if applicable)
  - contact person / on-call escalation channel
- For registry rollbacks (npm/pypi/cargo): publish a new patch that reverts the change rather than deleting published versions, unless deletion is explicitly approved.

## SBOM & Scanning

- Generate SBOMs as part of release step (see docs/release-guidelines.md)
- Run container and dependency scanners; fail gates on critical vulns unless security owner approves.

## PR and GitHub Release Automation

- Use tools/release/create-pr.sh to build a release PR from template templates/pr-release-template.md
- Use tools/release/github-release.sh to create the GitHub release and upload artifacts and SBOMs.
- CI workflow (.github/workflows/release.yml) should run on tag push and optionally on manual dispatch. It should publish to registries using restricted credentials.

## Handoff / Release Note Templates

- handoff/release-note-template.md is provided; copy into handoff/release-notes.md and fill before creating the release PR.
- Include SBOM links, scan results, and rollback owner in the handoff notes.

## Changelog Translation Handling

- English changelog is canonical; translations are best-effort and should be reviewed by native speakers. If translations are not ready, ship the English entry and open follow-up PRs for translations.
- Always record contributor attribution `(by @username)` in all changelog languages.

## Examples & Utilities

Scripts are intentionally small and opinionated. They expect CI to inject credentials and run from repository root. Use `--dry-run` flags to validate behavior without side-effects.


Status: success