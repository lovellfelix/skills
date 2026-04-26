API Contract Testing Guide

Purpose
- Ensure API changes do not break clients (Android, web, CLI) using contract testing and integration verification.

Approaches
1. Consumer-driven contract tests
   - Use Pact or similar: each consumer defines expected contract; provider verifies against consumer pacts.

2. Contract as tests
   - Generate provider tests from OpenAPI spec (e.g., Dredd, Postman tests) and run in CI against staging.

3. Contract validation in CI
   - Fail PRs if OpenAPI changes are incompatible (breaking changes) without version bump.
   - Use automated diffing tools to detect removed fields, changed types, or status code changes.

4. Contract testing matrix
   - Unit-level: schema validations for each response model.
   - Integration-level: mock consumer tests and provider verification.
   - End-to-end: smoke against staging with test accounts.

Best Practices
- Version APIs (v1, v2) and preserve backward compatibility within deprecation windows.
- Document breaking changes in PR description and link to migration guidance.
- Keep API examples in OpenAPI and Postman collections up-to-date.

CI Integration
- Run contract verification step post-merge to staging; block production deploy on failed contracts.

Rollback Criteria
- If clients start failing contract checks in production, revert the provider change or deploy consumer fixes with feature flags.
