GrenadianBuzz Security Checklist

Purpose
- High-level security checklist for feature design, infra, and release readiness.

Application
- Use during design reviews, PRs, and release sign-off for any backend, API, or mobile change.

Checklist
1. Authentication & Authorization
   - Ensure endpoints enforce auth (JWT) and validate scopes/roles.
   - Principle of least privilege for service accounts and CI tokens.
   - Rotate long-lived keys and use short-lived tokens for infra automation.

2. Data Protection
   - Encrypt PII at rest and in transit (TLS 1.2+).
   - Limit PII in logs; use redaction for sensitive fields (email, SSN, tokens).
   - Use environment-specific secrets stores (Vault/Secrets Manager) — never commit secrets.

3. Input Validation & Output Encoding
   - Validate and schema-check all API inputs (Zod/JSON Schema or OpenAPI validation).
   - Sanitize outputs rendered in web/mobile UI to prevent XSS.

4. Rate Limiting & Abuse Controls
   - Apply global and per-endpoint rate limits; protect write endpoints strongly.
   - Implement pattern detection for spam/abuse (bursting, new accounts, repeated flags).

5. Dependency Hygiene
   - Dependabot or automated dependency scanning enabled.
   - Vulnerabilities triaged within SLA (e.g., critical within 24h).

6. CI/CD & Build Security
   - Prevent PRs from running on secrets-enabled runners without approval.
   - Signed build artifacts and reproducible builds where feasible.

7. Platform & Infrastructure
   - Network segmentation between public-facing and internal services.
   - Use IAM roles for services; avoid embedding credentials in images.

8. Logging & Forensics
   - Structured logs with request IDs and correlation ids.
   - Retention and access controls for audit logs.

9. Privacy & Compliance
   - Data minimization: collect only necessary user data.
   - Data deletion and export flows validated before launch (GDPR/CCPA readiness).

10. Penetration & Threat Modeling
   - Perform threat modeling for new attack surfaces and record mitigation decisions.
   - Run periodic pentests for major releases.

Sign-off
- Security owner approves before production rollout. Document approval in release notes.