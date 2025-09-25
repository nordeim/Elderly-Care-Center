# Stripe Integration Guide

**Last Updated:** 2025-09-26 (UTC+08)

---

## Overview
The Elderly Daycare Platform uses Stripe hosted checkout and payment intents to collect booking deposits. This guide explains configuration, deployment, compliance boundaries, and troubleshooting for the integration implemented in Phase F.

---

## Environment Configuration
Set the following variables in each environment (`.env`, deployment secrets, CI):

```dotenv
STRIPE_SECRET_KEY=sk_live_or_test
STRIPE_PUBLISHABLE_KEY=pk_live_or_test
STRIPE_WEBHOOK_SECRET=whsec_live_or_test
PAYMENTS_DEFAULT_DEPOSIT_CENTS=5000
PAYMENTS_CURRENCY=usd
```

### Local Development
- Use Stripe CLI to forward webhooks: `stripe listen --forward-to http://localhost:8000/payments/stripe/webhook`.
- Use test cards (e.g., `4242 4242 4242 4242`, any future expiration, CVC `123`).
- Confirm `.env` loads `STRIPE_*` keys before running `php artisan serve`.

### Staging / Production
- Store secrets in infrastructure secret manager (e.g., AWS Secrets Manager, HashiCorp Vault).
- Grant webhook endpoint on Stripe dashboard: set URL to staging/production webhook route and copy signing secret.
- Ensure outbound firewall allows Stripe API domains.

---

## Payment Flow
1. Caregiver initiates deposit on dashboard and is redirected to `CheckoutController::show()`.
2. `StripeService::createDepositIntent()` creates a payment intent and persists `Payment` record.
3. Stripe Elements accepts card details on `resources/views/payments/deposit.blade.php`.
4. Webhooks at `/payments/stripe/webhook` confirm success/failure and update `Payment`/`Booking` state.
5. `AuditLog::record()` captures succeeded/failed/refunded events.

---

## Compliance & Security
- Only hosted checkout and payment intents are used; card data never touches application servers.
- Maintain PCI SAQ A compliance: document flows, restrict access to Stripe dashboard, rotate API keys regularly.
- Webhook signature verification is mandatory (`STRIPE_WEBHOOK_SECRET`). Monitor logs for signature failures.
- Restrict who can access logs containing payment metadata.

---

## Observability
- Prometheus metrics exposed via `BookingMetricsController` include payment success/failure counts.
- Grafana dashboard (`ops/observability/grafana-dashboards/booking-funnel.json`) visualizes success rates and funnel drop-offs.
- Runbook for payment failures: see `docs/runbooks/notification-failures.md` and add payment-specific section.

---

## Testing & Validation
- Automated coverage: `tests/Feature/Payments/StripeFlowTest.php` exercises checkout and webhook logic using mocked Stripe client.
- Manual validation checklist:
  1. Use Stripe test card to confirm deposit flow in staging.
  2. Trigger failure using card `4000 0000 0000 0002` to verify error handling.
  3. Issue partial refund via Stripe dashboard and confirm webhook updates payment status.
  4. Validate audit logs and metrics reflect each event within one minute.

---

## Troubleshooting
- **Webhook 400 errors:** Verify signing secret, ensure payload not truncated by ingress, and check Stripe CLI logs.
- **Payments stuck in requires_action:** User may need 3DS challenge; confirm Stripe Elements surfaces modal. Review logs for `requires_action` statuses and trigger reminder email/sms if necessary.
- **Receipt URL missing:** Ensure charges array in intent includes receipt; if not, confirm Stripe account email settings.
- **Currency mismatch:** Update `PAYMENTS_CURRENCY` and regenerate intents; note conversion is not handled automatically.

---

## Escalation
1. Contact on-call payments engineer via `#payments-ops` Slack for incidents.
2. Escalate to product owner if prolonged outage (>30 minutes) impacts caregiver deposits.
3. Notify finance lead for manual reconciliation if refunds processed outside application.

---

## Change Log
- **2025-09-26:** Initial integration documentation authored during Phase F implementation.
