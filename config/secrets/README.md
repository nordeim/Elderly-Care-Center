# Secrets Management Guidelines

This document outlines how secrets (API keys, database credentials, certificates) are provisioned and accessed for the Elderly Daycare Platform. It supports the compliance requirements detailed in `docs/compliance/privacy-assessment.md` and the operational standards defined in `Project Requirements Document v2.md` §7.

## 1. Secret Storage Strategy

- **Primary Store:** HashiCorp Vault (self-hosted or managed) with AWS KMS/GCP KMS integration for auto-unseal.
- **Bootstrap Secrets:** Minimal set (Vault root token, initial admin credentials) stored in an encrypted password manager accessible to the Security Lead and Product Owner.
- **Application Secrets:**
  - Stored in Vault KV v2 engine under paths:
    - `secret/data/app/<env>/database`
    - `secret/data/app/<env>/stripe`
    - `secret/data/app/<env>/mail`
    - `secret/data/app/<env>/sms`
  - Access via short-lived tokens scoped per service account.

## 2. Access Controls

- **Roles & Policies:**
  - `role/devops` — full access to CI/CD integration paths.
  - `role/backend` — read-only access to runtime application secrets.
  - `role/security` — management capabilities for secret rotation.
- **Authentication Methods:** GitHub OIDC or cloud IAM federation for CI; user login via SSO/MFA.
- **Audit Logging:** Vault audit device forwards to centralized logging; reviewed weekly by Security Lead.

## 3. Rotation & Lifecycle

- **Rotation Cadence:**
  - Database credentials: quarterly.
  - API keys (Stripe, SES, Twilio): quarterly or upon suspicion of compromise.
  - Encryption keys: annually with envelope encryption updates.
- **Process:** Update secret in Vault → trigger automation to restart dependent services via deployment pipeline → confirm via smoke tests.
- **Revocation:** Revoke tokens immediately upon offboarding or detected misuse.

## 4. Local Development

- Developers do **not** receive production secrets.
- Local `.env` files populated via `ops/scripts/bootstrap-dev.sh`, which fetches development secrets from Vault using scoped tokens.
- Developers must store `.env` in OS keychain; `.env` is gitignored.

## 5. CI/CD Integration

- GitHub Actions obtains short-lived Vault tokens via OIDC.
- Workflow injects secrets into job environment at runtime only; no secrets persisted in logs or artifacts.
- Secret scanning (TruffleHog/GitLeaks) runs on every PR; findings triaged by Security Lead.

## 6. Incident Response

- Compromise suspected → execute `docs/security/secrets-rotation.md` playbook (to be authored).
- Notify stakeholders, rotate affected credentials, perform post-incident review.

## 7. Pending Tasks

- Implement Terraform module for Vault setup (`ops/terraform/modules/vault/`).
- Author `docs/security/secrets-rotation.md` in Phase B.
- Configure automated alerting for Vault audit anomalies.
