# Understanding Project Requirements

Purpose: capture a concise, verifiable understanding of the Elderly Daycare Platform project as described in the provided artifacts (`Project Requirements Document v2.md`, `README.md`, `PAD_condensed.md`, `comprehensive_codebase_completion_execution_plan.md`), and lay out a practical validation and execution checklist so technical and product stakeholders can quickly confirm alignment.

## 1 — Executive summary (my understanding)

- Mission: deliver a trust-first, accessible web platform for elderly daycare centres that drives discovery and bookings while prioritising accessibility, privacy, and operational resilience.
- Key user groups: family caregivers, elderly clients, centre admins/caregivers, referral agencies.
- Core features (phased): public discovery pages, booking flow, admin booking management, media pipeline (HLS + captions), caregiver accounts & notifications, payments/analytics, and launch hardening.
- Non-functional targets: WCAG 2.1 AA, booking p95 < 2.5s, API p95 < 300ms, availability ≥ 99.9%, strong observability, and secure-by-default architecture.

## 2 — Contract: what success looks like

Inputs
- Codebase in repository (Laravel 12, PHP 8.4, Tailwind, Livewire, Vite). 
- Environment: Docker-based local dev, CI pipeline, migrations and seeders.
- Stakeholders: Product Owner, Lead Developer, QA, Security, DevOps.

Outputs
- Working staging deployment of each phase's vertical slice.
- Acceptance artefacts: automated tests (unit/feature/Dusk), accessibility reports, performance test results, runbooks, and user-validation reports.

Error modes / constraints
- Missing or incomplete legal/compliance constraints for PHI/GDPR may block features that store sensitive data.
- Media pipeline and object storage credentials required before publishing video-based trust content.

Success criteria (short list)
- End-to-end booking flow works and is covered by automated tests.
- Accessibility automated checks and manual audits for core flows are green or triaged.
- CI enforces linting, tests, and security scans before merges.

## 3 — Mapping of major deliverables to repository artifacts

- Foundation / Auth: `app/Models/*`, `database/migrations/*`, `docker/*`, `tests/Feature/Auth` (Phase B / Phase 0)
- Booking: `app/Http/Controllers/Public/BookingController.php`, `app/Models/Booking.php`, `database/migrations/*slots*` and `tests/Feature/BookingFlowTest.php` (Phase C)
- Media pipeline: `app/Domain/Media`, ffmpeg jobs, object storage config, `ops/` scripts, and Prometheus metrics (Phase D)
- Accounts/Notifications: `app/Notifications/`, queue config, calendar/ical export utilities (Phase E)
- Payments & Analytics: Stripe integrations and dashboards, CDN config (Phase F)
- Launch operations: runbooks, Prometheus + Grafana dashboards, backups and recovery scripts (Phase G)

## 4 — Validation plan (how I'll confirm this understanding is correct)

Goal: produce objective evidence that the repo and stakeholders align with the doc assumptions.

Steps (minimal reproducible checks)
1. Static review of the key docs (done): `Project Requirements Document v2.md`, `PAD_condensed.md`, `comprehensive_codebase_completion_execution_plan.md`, and `README.md`.
2. Automated repository checks (local):
   - Confirm tooling files exist: `composer.json`, `package.json`, `docker-compose.yml`.
   - Run a fast CI-like smoke: composer install (inside container or replicate PHP deps), and run `php artisan --version` to check framework version.
3. Run test smoke: `php artisan test --filter=BookingFlowTest` (or entire Feature tests if quick). This verifies migrations and key feature scaffolding.
4. Sanity-check migrations: list migrations to confirm presence of bookings, slots, personal access tokens, users.
5. Check config expectations: `config/media.php`, `config/queue.php`, `config/filesystems.php` for object storage and queue settings.
6. Confirm observability hooks: search for Prometheus exporter middleware, metrics, Sentry, and Horizon config.
7. Quick UX/Accessibility check: run any available Axe CI or automated accessibility specs from `tests/Accessibility/` or related scripts.
8. Stakeholder alignment: share this `Understanding Project Requirements.md` and request Product Owner / Lead Developer sign-off and any clarifying priorities/constraints (PHI, payment region limits, retention windows).

Validation Artefacts to produce
- Short checklist results (pass/warn/fail) for steps 2–7 above.
- A short gap analysis: missing files/configs/credentials preventing progress.
- A prioritized remediation list for any blockers.

## 5 — Acceptance criteria mapping (per-phase, condensed)

- Phase A/B (Foundation & Auth): Docker dev runs, CI skeleton passes lint + phpunit smoke, RBAC seeded, basic metrics exported. -> Done: confirm `docker/`, `composer.json`, `.github/workflows/` exist and run locally or in CI.
- Phase C (Booking MVP): Booking create → confirmation flow end-to-end, admin booking inbox, automated E2E covering booking flow, accessibility baseline. -> Verify `tests/Feature/BookingFlowTest.php`, email templates, and booking migrations.
- Phase D (Media): Media pipeline transcodes to HLS, captions present, signed URLs for private preview. -> Verify ffmpeg jobs or job class presence, object storage config, media conversions.
- Phase E (Accounts/Notifications): Reminder delivery via email/SMS with retries; calendar exports. -> Verify `app/Notifications/*`, queue configs, and ical export utilities.
- Phase F (Payments & Analytics): Stripe hosted flows configured and analytics dashboards available. -> Confirm presence of Stripe env vars, webhooks handling, and analytics dashboards or exports.

Each mapped acceptance criterion should be annotated in the repo with a small test (unit/feature/Dusk) and an automated CI check.

## 6 — Quick risk register (top items and mitigations)

- PHI / GDPR scope discovered late — Mitigation: treat sensitive fields as feature-flagged until legal sign-off; encrypt sensitive columns; limit egress.
- Media pipeline scaling & cost — Mitigation: staged rollout, limit public publishing until CDN and lifecycle policies set; cost-awareness alerts.
- Accessibility regressions — Mitigation: integrate Axe in CI and schedule manual audits; add regression gating for critical flows.
- DB migration locking risk on large tables — Mitigation: use online migration strategies (avoid long locks), dry-run SQL before apply.

## 7 — Edge cases & important technical details to confirm

- Concurrent booking attempts for the same slot: verify atomic capacity checks and DB uniqueness constraints (unique index for slots time + room), and idempotency of booking create.
- Timezone handling: slot generation vs client locale; ensure UTC storage and localised presentation.
- Consent & special-needs fields: ensure explicit consent captured and retention policy applied.
- Media accessibility: captions/transcripts required before publish; video player keyboard accessible.

## 8 — Tests & quality gates I recommend adding or verifying now

- Unit tests for AvailabilityChecker, SlotGenerator, and capacity enforcement.
- Feature tests for booking happy path, double-booking race, and booking cancellation flows.
- Dusk (browser) tests for booking wizard, media playback with captions, and admin content publish preview.
- CI gates: lint -> phpunit (unit+feature) -> Dusk (smoke) -> accessibility checks -> security/dependency scanning.

Commands (copyable) to run locally (Docker-based dev as recommended in README):

```bash
# start dev containers
docker-compose up -d

# install php deps
docker-compose exec app composer install

# run migrations + seeders
docker-compose exec app php artisan migrate --seed

# run the booking feature tests (example)
docker-compose exec app php artisan test --filter=BookingFlowTest
```

## 9 — Assumptions I made (please confirm)

1. Primary stack is Laravel 12 + PHP 8.4 as indicated in README and PAD.
2. Docker-compose environment is present and used for local dev and smoke tests.
3. Media pipeline depends on object storage credentials that are not stored in repo; those need ops secrets.
4. Stripe / SMS provider credentials are intentionally absent from the repo for security — they will be provided via secrets manager.

If any assumption is incorrect, please point it out and I will update the plan immediately.

## 10 — Practical next steps (recommended immediate actions)

1. Run the validation checklist in section 4 and produce the quick checklist artefact.
2. If any blocking gaps are found (missing migrations, missing tests), file prioritized tickets and assign owners.
3. Add minimal health-check endpoints and a lightweight smoke test that CI can run pre-merge.
4. Schedule a 30–45 minute alignment review with Product Owner and Lead Developer to confirm priorities (PHI scope, payment region, retention policy).

## 11 — Contacts & sign-off

Please review this document and respond with one of:

- "Sign-off" — I confirm the understanding and authorise execution of the validation plan.
- "Minor edits" — list corrections and I will update the document.
- "Major changes" — schedule a short meeting and I will prepare a revised plan.

---

Prepared by: (automated reading & synthesis)
Date: 2025-09-28
