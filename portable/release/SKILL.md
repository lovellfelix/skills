---
name: release
description: "Use when cutting a release, bumping a semver version, tagging, writing changelog entries or user-facing release notes from commits/PRs, or publishing to npm, PyPI, crates.io, GitHub Releases, or a Claude plugin marketplace."
metadata:
  version: 2.0.1
  portable: true
  tags: [release, versioning, semver, changelog, release-notes, publishing, sbom]
---

# Release

Cut a release safely: decide the version, write notes people can act on, publish through CI with a rollback path.

`tools/release/`, `templates/`, `handoff/`, `docs/release-guidelines.md`, and `.github/workflows/release.yml` in this skill directory are **starter templates**. Copy them into the target repo only when it has no release tooling. If the repo already has release scripts, a release workflow, `release-please`, `changesets`, `semantic-release`, or `git-cliff` config, use that instead.

## 1. Detect

- Version file, first match: `package.json`, `pyproject.toml`, `Cargo.toml`, `marketplace.json` (root wins over a `.claude-plugin/marketplace.json` draft stub), `VERSION`/`version.txt`.
- Changelogs: `CHANGELOG*.md`, `HISTORY*.md`, `CHANGES*.md`. Filename suffix = language (`CHANGELOG.zh.md`). English is canonical.
- Existing release automation (above) and the last tag: `git describe --tags --abbrev=0`.

## 2. Decide the version

```bash
git log "$(git describe --tags --abbrev=0)"..HEAD --oneline
```

- Breaking change → major, new capability → minor, fixes only → patch. Pre-1.0: breaking → minor.
- If the repo uses Conventional Commits, read the type prefixes. Otherwise classify from subjects and merged PRs; do not assume the prefixes exist.
- Pre-releases use a distinct tag (`v1.2.0-rc.1`) and are marked pre-release on GitHub.
- Honor an explicit `--major/--minor/--patch` from the user. `--dry-run` means show the plan and diffs only.

## 3. Write the changelog and release notes

Two audiences, two artifacts.

**Changelog** (Keep a Changelog, for maintainers):

```markdown
## [2.5.0] - 2026-03-20

### Added
- Batch export API for bulk operations (#412)

### Changed
- Minimum Node.js version is now 18.0.0

### Deprecated
- `/api/v1/export` (use `/api/v2/export`)

### Fixed
- Memory leak in event listener cleanup (#418)

### Security
- Bump `xml-parser` to patch CVE-2026-1234
```

**Release notes** (for users): breaking changes and migration steps first, then new features, then fixes.

- Write for the user, not the developer: "Fixed 30-second timeout on large exports", not "Fixed timeout issue".
- Skip internal noise. Test: would a user notice or care?
- Link migration guides, CVEs, deprecation notices. Credit contributors `(by @user)`.
- Translations are best-effort: ship English, open follow-up PRs for other languages (`tools/release/create-translation-pr.sh`).

`tools/release/gen-changelog.sh` drafts from git (uses `git-cliff` when installed). Always edit the draft; never ship raw commit subjects.

## 4. Bump, PR, tag

1. Write the new version to the version file(s); in a monorepo, only packages with changes.
2. Commit the bump and changelog together, in the repo's commit style (check `git log --oneline -10`).
3. Open a release PR (`tools/release/create-pr.sh` with `templates/pr-release-template.md`). Merge after CI is green and approvals are in.
4. Tag the merge commit `vX.Y.Z` and push the tag. CI publishes.

**Human approval required** before tagging when any apply: major bump, breaking change, new native binary or installer, or HIGH/CRITICAL scan finding.

## 5. Publish (CI, not a laptop)

- Registry tokens live in CI secrets only: `NPM_TOKEN`, `TWINE_PASSWORD` (PyPI API token, username `__token__`), `CARGO_REGISTRY_TOKEN`, `GITHUB_TOKEN`. Never in scripts or prompts.
- Supply chain, where the project ships artifacts: SBOM (`generate-sbom.sh`), vulnerability scan (`run-scans.sh`, fails on HIGH/CRITICAL), checksums and signatures (`checksum-sign.sh`; prefer sigstore/KMS over long-lived GPG keys).
- GitHub release with notes and assets: `github-release.sh`. Per-registry: `publish-npm.sh`, `publish-pypi.sh`, `publish-cargo.sh`, `publish-claude.sh`; monorepos: `monorepo-publish.sh`. The publish scripts, `monorepo-publish.sh`, `rollback-deploy.sh`, and `create-translation-pr.sh` accept `--dry-run`; `github-release.sh` (use `--draft` instead), `create-pr.sh`, and the SBOM/scan/sign scripts do not.

## 6. Rollback

Before tagging, write down in the release PR or `handoff/release-notes.md`:

- Previous good tag and where its artifact lives.
- Database/schema rollback steps, if any.
- Owner and escalation channel.

Registry rollback = publish a new patch that reverts. Do not unpublish/yank unless explicitly approved. Deploy rollback helper: `rollback-deploy.sh`.

## Done when

- [ ] Version bumped consistently in every version file
- [ ] Changelog and user-facing notes written, breaking changes first with migration steps
- [ ] Release PR merged with green CI; gated releases approved
- [ ] Tag pushed; registry and GitHub release published
- [ ] Rollback plan recorded
