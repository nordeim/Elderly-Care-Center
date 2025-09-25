# CI Quality Gates — Phase A Bootstrap

This document defines the minimum continuous integration gates required before expanding to full coverage in later phases. It aligns with `Project Requirements Document v2.md` §11 and the execution plan's Phase A deliverables.

## 1. Pipeline Stages

1. **Lint & Formatting**
   - PHP CodeSniffer (PSR-12) on `app/`, `tests/`.
   - Laravel Pint/Tailwind linting (planned Phase B) — track in backlog.
2. **Unit Smoke Tests**
   - PHPUnit `Unit` suite runner with `--stop-on-failure` (non-blocking in bootstrap, blocking by Phase B).
3. **Static Analysis**
   - PHPStan level 5 analysis for `app/` namespace.
4. **Security Scans**
   - Composer audit (to be enabled once private packages resolved).
   - Git secret scanning via TruffleHog (`--fail`).
5. **Artifact Handling**
   - No artifacts generated during bootstrap; plan integration tests in later phases.

## 2. Quality Gate Policy (Phase A)

- Pipeline must succeed before merging into `main`.
- Failures are blocking except:
  - PHPUnit smoke tests may warn (exit 0 with message) until tests are implemented; log issue in backlog.
- Any failure requires resolution or documented exception approved by Product Owner and Lead Developer.

## 3. Roadmap to Phase B

- Add Laravel Pint formatting step.
- Convert PHPUnit smoke tests to blocking once baseline suite exists.
- Introduce PHP-CS-Fixer for legacy code (if needed).
- Integrate composer audit and npm audit.
- Publish coverage reports to `docs/testing/coverage-summary.md`.

## 4. Ownership & Maintenance

- DevOps/Observability Engineer maintains workflow definitions.
- QA Lead monitors gate effectiveness and reports drift.
- Security Lead reviews secret scan alerts and vulnerability reports.

## 5. Incident Response

- Pipeline failure → triage within 4 business hours.
- Document root cause in issue tracker; update this policy if new gate types introduced.
