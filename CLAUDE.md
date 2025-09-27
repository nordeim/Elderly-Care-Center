# CLAUDE.md — Codebase guide for AI coding agents

Purpose: a compact, factual, and actionable source-of-truth that an AI coding agent (for example, Claude Code) can consume to quickly understand the Elderly Daycare Platform codebase, make safe changes, diagnose issues and implement features correctly.

Date: 2025-09-28

Note: this file is intentionally concise and structured for programmatic consumption: short sections, clear anchors (class/file names), and explicit contracts for the most critical flows.

## 1 — High-level summary

- Stack: Laravel 12 (PHP 8.4+), Blade + Livewire, TailwindCSS, Vite. Background workers use Redis queues. DB is MariaDB (migrations present). Media pipeline uses ffmpeg workers and S3-compatible object storage. Payments use Stripe.
- Runtime: Docker Compose for local/dev (`docker-compose.yml`), app container built from `Dockerfile`. Entrypoint (`docker/entrypoint.sh`) runs bootstrap tasks (wait-for DB/Redis, run migrations, create readiness marker). Healthcheck script at `docker/app-healthcheck.sh` probes `/healthz`.
- Primary domains: Content (services/staff/testimonials), Booking (slots, bookings, availability), Media (ingest, transcode, captions), Accounts/Notifications, Payments, Admin/Observability.

## 2 — What an AI agent should know first (short list)

- Booking flow is transactional and has both a stored-proc path (MySQL) and an application path using row-level locks. See `app/Actions/Bookings/CreateBookingAction.php` and migration `database/migrations/*create_bookings_table.php`.
- Media ingestion is queued: signed uploads → `IngestMediaJob` → `TranscodeJob` → store renditions. See `app/Services/Media/SignedUploadService.php`, `app/Jobs/Media/*`, `app/Services/Media/TranscodingService.php`.
- Payments: centralised Stripe service (`app/Services/Payments/StripeService.php`), Checkout controller and webhook controller under `app/Http/Controllers/Payments/`.
- Queues: configured in `config/queue.php` and job classes declare `onQueue('media')` etc.
- Observability: Prometheus exporters in `app/Support/Metrics/*` and Grafana dashboards under `ops/grafana/dashboards/`.

## 3 — Quick run / test commands (developer & CI)

Use Docker Compose (repo root):

```bash
docker-compose up -d
docker-compose exec app composer install
docker-compose exec app php artisan migrate --seed
docker-compose exec app php artisan key:generate --force
docker-compose exec app php artisan test --testsuite=Feature
```

CI recommendation: run tests in a job that starts MySQL and Redis services, runs migrations, then runs `php artisan test`. For E2E, run Dusk/Cypress in a separate job with a seeded DB.

## 4 — Key files and responsibilities (quick map)

When searching or making edits, prefer these anchors (file path -> concise purpose):

- docker-compose.yml — local runtime (app, mysql, redis, mailhog)
- Dockerfile — app image build (php extensions, composer install)
- docker/entrypoint.sh — bootstrap: env checks, wait-for services, migrations, readiness marker
- docker/app-healthcheck.sh — container health probe
- routes/web.php, routes/api.php — route definitions
- app/Http/Controllers/Site/BookingController.php — public booking UI endpoints (create/store)
- app/Actions/Bookings/CreateBookingAction.php — business logic for booking create (transactional)
- app/Models/Booking.php, BookingSlot.php, SlotReservation.php — booking domain models
- database/migrations/*create_bookings_table.php — DB contract for bookings
- app/Jobs/Media/IngestMediaJob.php, TranscodeJob.php — media pipeline jobs
- app/Services/Media/TranscodingService.php — ffmpeg orchestration
- app/Services/Media/SignedUploadService.php — signed URL generation
- app/Services/Payments/StripeService.php — Stripe interactions
- app/Http/Controllers/Payments/CheckoutController.php, StripeWebhookController.php — checkout + webhook
- app/Notifications/* — notification classes (reminders, confirmations)
- app/Jobs/Notifications/SendReminderJob.php — reminder job
- app/Support/Metrics/* — Prometheus metric exporters
- ops/observability/prometheus/prometheus.yml — observability config
- ops/grafana/dashboards/* — dashboards (booking funnel, auth baseline)
- resources/views/pages/book.blade.php — booking wizard UI
- resources/views/components/media/player.blade.php — media player
- tests/Feature/* and tests/Unit/* — automated tests

## 5 — Primary code anchors and search tokens

Search for these exact tokens when you need to find relevant code quickly:

- CreateBookingAction, BookingSlot, SlotReservation, AvailabilityChecker, SlotGenerator
- IngestMediaJob, TranscodeJob, TranscodingService, SignedUploadService
- StripeService, CheckoutController, StripeWebhookController
- BookingMetrics, MediaMetrics, NotificationMetrics
- /metrics (Prometheus endpoint), healthz, app.ready

These anchors directly map to responsibilities described in docs and tests.

## 6 — Contracts for critical flows (inputs / outputs / errors)

Booking create — CreateBookingAction::execute(array $payload) -> Booking
- Inputs: payload with 'slot_id', 'client' or 'email', optional 'notes', 'caregiver_name'
- Behavior: transactional; uses stored proc on MySQL if present, otherwise lockForUpdate to decrement available_count and create booking + status history
- Outputs: Booking model (status 'pending')
- Error modes: throws RuntimeException when slot unavailable or stored proc returns failure. Agent should translate these to user-facing validation.

Media ingest — IngestMediaJob(mediaItemId)
- Inputs: media item record references (file_url, metadata)
- Behavior: optional virus scan; mark status; dispatch TranscodeJob
- Outputs: TranscodeJob queued; media status updated to processing/failed/complete
- Errors: ProcessFailedException or script missing; job re-tries configured. Respect job's $tries and backoff settings.

Payments — StripeService::createDepositIntent(Booking, amountCents, metadata)
- Inputs: Booking model, amount in cents, metadata
- Behavior: create payment intent via StripeClient; persist Payment record with intent id and status
- Errors: ApiErrorException — log and rethrow. Webhook verification required when handling Stripe callbacks.

## 7 — Tests & CI: where they live and what to run

- Unit and Feature tests: `tests/Unit/`, `tests/Feature/` (run with `php artisan test`)
- Important test anchors: `tests/Feature/Bookings/CreateBookingTest.php` (currently placeholder), `tests/Feature/Payments/StripeFlowTest.php`, `tests/Feature/Media/VirtualTourTest.php`
- Observability tests: none automated; rely on Prometheus rules + manual dashboards (add smoke tests to assert /metrics contains booking counters)

## 8 — Common edit patterns and cautions (advice for an AI agent)

- DB migrations: follow non-destructive approach. For schema changes that add columns, use nullable defaults and background backfills. Avoid dropping or renaming heavy columns in-place.
- Concurrency: booking operations must preserve capacity. Prefer using CreateBookingAction and its transactional path rather than manual ad-hoc inserts.
- Stored procedures: repo contains a MySQL stored-proc invocation in CreateBookingAction — if altering booking semantics, update both the stored proc and the PHP branch or remove the stored-proc branch intentionally with a clear migration and test.
- Media: transcode jobs run external ffmpeg; changes to TranscodingService must preserve expected HLS renditions and caption workflow.
- Secrets: Stripe keys, object storage keys, and other secrets are environment-driven; do NOT commit secrets to repo. Use `config/secrets/README.md` and env files/secrets manager.

## 9 — Edge cases & prioritized tests to add

High priority tests to add or enable:

1. Booking concurrent request race — simulate two requests for same slot and assert only one booking created and capacity decremented correctly.
2. Booking stored-proc fallback — verify behavior on MySQL with stored proc (if proc is present in DB).
3. Media ingest failure & retry — simulate virus scan failure and ensure job marks failed and requeues as configured.
4. Stripe webhook signature validation — test handling of invalid signature and replay attacks.

## 10 — PR checklist for safe changes

- Run `php artisan test` and ensure no regressions in Feature and Unit tests.
- If change touches DB schema, add migration and a reversible down() when safe. Add a data migration plan if necessary.
- If change touches booking or media flows, add/adjust feature tests (concurrent booking test for booking changes). Add metrics increment assertions when appropriate.
- Update `ops/grafana` dashboards or `app/Support/Metrics/*` if new metrics are introduced.
- Ensure no secrets are committed. Use env vars and update `config/secrets/README.md` if new secret keys expected.

## 11 — Where to look for more context (docs & owners)

- Project Requirements: `Project Requirements Document v2.md`
- Execution Plan: `comprehensive_codebase_completion_execution_plan.md`
- Architecture notes: `PAD_condensed.md`
- Completion report: `codebase_completion_status_report.md`
- Owners & runbooks: `docs/governance/roles-and-responsibilities.md`, `docs/runbooks/*`

Contact owners (if available in repo or team): Product Owner & Lead Developer listed in `comprehensive_codebase_completion_execution_plan.md` and `docs/governance/*`.

---

If you want, I can now automatically add a small runnable PHPUnit feature test that replaces the placeholder in `tests/Feature/Bookings/CreateBookingTest.php` with a minimal in-container friendly test, plus a GitHub Actions workflow to run tests with MySQL/Redis services. Say "Scaffold test + CI" to proceed.
