# Release Guidelines

This document contains guidance for changelog translation handling, SBOM and scanning recommendations, and other release hardening best practices.

Changelog & Translation Handling
--------------------------------
- Keep the English changelog (CHANGELOG.md) as the canonical source of truth. Other languages are localized summaries and MUST include contributor attributions in the format `(by @username)`.
- Workflow to update translations:
  1. Generate/enrich English changelog automatically from commits since last tag.
  2. Create a draft translation entry (machine-assisted or human) and open a PR for native speakers to review.
  3. For monorepos: update per-package changelog files under each package directory and the root CHANGELOG.md with a summary.
- Always include the VERSION and date (YYYY-MM-DD) at the top of each changelog entry.
- If translations lag, ship with an English-first release and schedule translation follow-ups; mark them as follow-up PRs.

SBOM & Scanning Recommendations
-------------------------------
- Generate an SBOM for every release. Recommended formats:
  - SPDX JSON
  - CycloneDX (XML/JSON)
- Suggested tooling:
  - syft (https://github.com/anchore/syft)
  - cyclonedx-cli (https://github.com/CycloneDX/cyclonedx-cli)
- Minimal SBOM pipeline step:
  1. Run syft to produce sbom/spdx.json and sbom/cyclonedx.json
  2. Attach SBOM artifacts to the GitHub release
  3. Store SBOM in a canonical artifact store (S3, internal blob)

- Run vulnerability scanners as part of the release pipeline. Recommended scanners:
  - Trivy (container and filesystem scanning)
  - Snyk (optional commercial product, good for IaC and deps)
  - OSS-Fuzz (for native C/C++ projects)

- Policy recommendations:
  - Block a release when a critical or high severity issue is introduced in direct dependencies unless explicitly approved by security owner.
  - Record scan results and triage decisions in the handoff/release-notes.md.

Signing & Checksums
-------------------
- Produce checksums for binary artifacts (sha256) and sign artifacts with a project GPG key.
- Store public GPG keys in repo under .keys/ or in user/org key management system.
- Prefer CI-managed ephemeral signing tokens where possible (AWS KMS sign, sigstore) over long-lived private keys.

Monorepo Handling
-----------------
- Per-package releases: prefer independent package tagging (package-name@vX.Y.Z) and per-package changelogs.
- Root-level release: add a root release summarizing all packages and list per-package release tags.
- CI: ensure the pipeline maps changed packages to publish steps and avoids republishing unchanged packages.

Note: change detection that compares against origin/main requires a full fetch in CI. In GitHub Actions ensure actions/checkout@v4 is configured with `fetch-depth: 0` so refs like origin/main are available to the runner. Without a full fetch change-detection tools may be unable to compare against the default branch and either fail or fall back to HEAD.

Rollback Guidance
-----------------
- Provide a short rollback plan in handoff/release-notes.md including:
  - How to re-deploy previous artifact (links to previous tag/artifact)
  - DB or migration rollbacks (if applicable)
  - Who to call (pager/Slack channel) and escalation path
- For package registry rollbacks (npm/pypi/cargo): publish a new patch version that reverts the change. Do not delete published artifacts from registries unless absolutely necessary and approved by security/OSS owners.

Credentials & Gating
-------------------
- Keep publish credentials in repository secrets (GH Actions Secrets or external vault).
- Enforce branch protection on release branches/tags (signed commits, required reviews when needed).
- Require human approval for releases that:
  - Contain a breaking change
  - Bump major version
  - Introduce new native binaries or installers

Audit & Compliance
------------------
- Keep an audit trail of who executed the release (CI actor or username), the artifacts produced, and SBOM/scan results.
- Store release artifacts for at least 90 days by default.

