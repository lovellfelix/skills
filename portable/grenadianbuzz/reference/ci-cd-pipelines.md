CI/CD Pipeline Guidance

Purpose
- Define recommended CI/CD structure, gating, and deployment strategies for GrenadianBuzz services.

Pipeline Stages
1. PR Validation
   - Lint, unit tests, static analysis, dependency scan, and contract checks (OpenAPI/Pact).
   - Minimal fast feedback: run only fast suites on PRs.

2. Build & Artifact
   - Create immutable artifacts (Docker images, wheels, APKs) with content-hash tags.
   - Store artifacts in a registry with provenance metadata.

3. Integration & Acceptance
   - Run integration tests against test environment using prebuilt artifacts.
   - Run contract and API compatibility tests.

4. Canary/Canary Rollout
   - Deploy to a small percentage of traffic (canary) first; monitor SLOs and error budgets.
   - Automatic rollback on breach of predefined thresholds.

5. Full Rollout
   - Gradual increase to 100% after canary success; verify replication across regions.

Gatekeeping
- Require passing security scans and contract tests before deployment to staging/production.
- Manual approval for database migrations that are non-backward compatible.

Feature Flags & Migrations
- Use feature flags for behavioral changes; ensure DB migrations are backward compatible.
- Prefer expand-then-contract migration patterns.

Secrets & Credentials
- Use secrets manager; restrict access by pipeline role and environment.
- Avoid injecting long-lived credentials into ephemeral runners without approval.

Testing & Validation
- Promote artifacts between environments instead of rebuilding in each stage to ensure parity.
- Run smoke and playwright smoke tests post-deploy automatically.

Rollback Strategy
- Blue/green or rolling with canary rollback on SLO breach.
- Keep easy path to rollback artifacts and database state where possible.

Observability Integration
- Each deploy should create a deploy marker with metadata (git sha, author, changelog).
- Monitor key SLOs and business KPIs during rollout window.