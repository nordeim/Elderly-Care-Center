# Phase F Sub-Plan — Payments, Analytics & Scale

**Source Alignment:** `comprehensive_codebase_completion_execution_plan.md` §Phase F  
**Objective:** Deliver hosted Stripe payment flows, analytics dashboards, and CDN scaling with full compliance, observability, and operational readiness.

---

## Workstream 1 — Payments Integration

### 1. `database/migrations/2025_05_01_000000_create_payments_table.php`
- **Description:** Create payments ledger capturing deposits, booking associations, Stripe metadata, and state transitions.
- **Checklist:**
  - Columns: `id`, `booking_id`, `stripe_payment_intent_id`, `status` (enum: pending, succeeded, requires_action, cancelled, refunded), `amount_cents`, `currency`, `receipt_url`, `metadata` JSON, timestamps.
  - Foreign key to `bookings` with cascade updates and restricted deletes.
  - Indices on `stripe_payment_intent_id`, `booking_id`, and `status`.
  - Down migration cleanly drops table and indexes.

### 2. `app/Services/Payments/StripeService.php`
- **Description:** Encapsulate Stripe API interactions for creating payment intents, confirming status, and handling refunds.
- **Checklist:**
  - Inject Stripe SDK client using config-driven secret keys.
  - Methods: `createDepositIntent(Booking $booking, int $amountCents)`, `retrieveIntent(string $id)`, `handleRefund(Payment $payment, array $options = [])`.
  - Map Stripe responses to internal `Payment` model attributes and handle errors with domain exceptions.
  - Log critical events and update `Payment` records accordingly.

### 3. `app/Http/Controllers/Payments/CheckoutController.php`
- **Description:** Orchestrate hosted checkout initiation, collecting deposit amount and redirecting caregivers to Stripe.
- **Checklist:**
  - Guard with caregiver authorization + CSRF.
  - Validate booking ownership and deposit amount.
  - Call `StripeService` to create payment intent and persist `Payment` model.
  - Return view with client secret and publishable key for Stripe Elements.
  - Flash success/error messages and redirect to caregiver dashboard on completion.

### 4. `app/Http/Controllers/Payments/StripeWebhookController.php`
- **Description:** Handle Stripe webhook events (payment_intent.succeeded, payment_intent.payment_failed, charge.refunded).
- **Checklist:**
  - Verify webhook signature using `STRIPE_WEBHOOK_SECRET`.
  - Update `Payment` records and associated booking status transitions.
  - Log audit events via `AuditLog::record()`.
  - Return 200 responses for handled events; log/unhandled events for review.

### 5. `resources/views/payments/deposit.blade.php`
- **Description:** Hosted checkout page embedding Stripe Elements for caregivers to complete deposits.
- **Checklist:**
  - Display booking summary (date/time/service, amount due) and payment form with accessible labels.
  - Include Stripe JS initialization with publishable key and client secret.
  - Provide confirmation state, error handling, and link back to dashboard.
  - Ensure WCAG compliance (focus management, ARIA status alerts).

### 6. `app/Models/Payment.php`
- **Description:** Eloquent model representing payments ledger.
- **Checklist:**
  - Fillable attributes aligning with migration columns.
  - Cast `metadata` JSON and amount to integer.
  - Relationships: `booking()`, optional `receipt()` placeholder for future.
  - Helper scopes for status filtering and currency conversions.

### 7. `tests/Feature/Payments/StripeFlowTest.php`
- **Description:** Feature test simulating deposit initiation and webhook handling.
- **Checklist:**
  - Use Stripe client fakes/stubs to assert intent creation and webhook processing.
  - Cover success and failure paths, verifying booking/payment state changes.
  - Assert audit logs and notifications triggered when payments succeed/fail.

### 8. `docs/payments/stripe-integration.md`
- **Description:** Technical guide for configuring Stripe integration across environments.
- **Checklist:**
  - Document required environment variables, webhook setup steps, and test card usage.
  - Outline PCI scope and hosted checkout rationale (no card data stored).
  - Include troubleshooting tips and escalation contacts.

---

## Workstream 2 — Analytics Dashboards

### 1. `app/Http/Controllers/Admin/AnalyticsController.php`
- **Description:** Aggregate booking, media, and payment metrics for admin insights.
- **Checklist:**
  - Authorize via `access-admin` gate.
  - Query metrics (bookings by status, conversion funnel, media usage, payment success rate).
  - Provide JSON for dynamic charts and pass data to Blade view.
  - Handle date range filters with sensible defaults (last 30 days).

### 2. `resources/views/admin/analytics.blade.php`
- **Description:** Accessible analytics dashboard with charts/tables for bookings, payments, and media metrics.
- **Checklist:**
  - Use responsive layout with cards summarizing key KPIs.
  - Include charts (line/bar) using Chart.js or similar, with ARIA descriptions.
  - Provide filters for date range and service type.
  - Surface alerts if metrics indicate anomalies (e.g., high failure rate).

### 3. `ops/observability/grafana-dashboards/booking-funnel.json`
- **Description:** Grafana dashboard configuration for booking funnel and payment success metrics.
- **Checklist:**
  - Panels: funnel conversion, booking latency, payment success/fail counters, notification vs payment correlations.
  - Datasource references to Prometheus metrics introduced in Phase D/E.
  - Include alert thresholds metadata for Ops handoff.

### 4. `docs/analytics/metrics-definitions.md`
- **Description:** Canonical definitions for analytics KPIs used in dashboards.
- **Checklist:**
  - Define booking funnel stages, payment metrics, media engagement, and notification performance.
  - Specify calculation methodology, data sources, and owners.
  - Include glossary and version control notes for evolving metrics.

### 5. `tests/Feature/Admin/AnalyticsDashboardTest.php`
- **Description:** Feature test ensuring analytics controller renders data for authorized admins.
- **Checklist:**
  - Seed representative bookings, payments, media metrics.
  - Assert controller aggregates KPIs and view renders key sections.
  - Verify unauthorized users receive 403.

---

## Workstream 3 — CDN & Performance Scaling

### 1. `ops/terraform/modules/cdn/` (new module directory)
- **Description:** Terraform module encapsulating CDN distribution (e.g., AWS CloudFront) for media assets.
- **Checklist:**
  - Define CDN distribution, origin access controls, cache behaviors, logging.
  - Parameterize domain, TLS cert ARN, caching policies, price class.
  - Output CDN domain and distribution ID for environment consumption.

### 2. `ops/terraform/environments/staging/cdn.tf`
- **Description:** Environment-specific Terraform configuration instantiating CDN module.
- **Checklist:**
  - Reference `modules/cdn` with staging-specific variables (domain, bucket, cert IDs).
  - Configure route53/ DNS records as needed.
  - Include variables for alert thresholds and logging buckets.

### 3. `docs/operations/cdn-deployment.md`
- **Description:** Operational guide for provisioning and maintaining CDN infrastructure.
- **Checklist:**
  - Provide deployment steps (Terraform init/plan/apply), rollback, and validation checklist.
  - Document cache invalidation procedures and cost monitoring tips.
  - Outline escalation contacts and SLA expectations.

### 4. `docs/performance/load-testing-plan.md`
- **Description:** Plan for executing load tests to validate CDN and payment flows.
- **Checklist:**
  - Define tooling (k6/JMeter), scenarios (booking flow, media playback), and success criteria (p95 latency targets).
  - Document schedule, environment setup, and reporting requirements.
  - Map results to exit criteria (CDN reducing load times, payment responsiveness).

### 5. `scripts/performance/run-load-tests.sh`
- **Description:** Automation script to execute load test scenarios and collect reports.
- **Checklist:**
  - Parameterize environment URLs, duration, and VU counts.
  - Output JSON summaries and store artifacts in `storage/load-tests/`.
  - Exit with non-zero status on threshold breaches for CI integration.

---

## Cross-Cutting Checklist
- **Compliance & Security:** Document PCI scope in `docs/payments/stripe-integration.md`, ensure webhook verification and audit logging for payment events.
- **Observability:** Extend Prometheus metrics for payment success/failure and integrate with Grafana dashboard definitions.
- **Testing:** Add payment and analytics tests to CI; plan manual validation sessions with caregivers/admins for billing flows.
- **Documentation:** Update `README.md` deployment notes with payment setup, CDN deployment references, and load testing procedure.

---

## Milestone Tracking & Validation
- Use this sub-plan to track Phase F workstreams, updating status during sprint reviews.
- Exit Phase F when payments operational in staging, analytics dashboards live, CDN delivering media with validated performance, and documentation/tests signed off by Product, QA, and DevOps leads.
