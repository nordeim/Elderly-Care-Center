# Analytics Metrics Definitions

**Last Updated:** 2025-09-26 (UTC+08)

---

## Booking Funnel
- **Requested** (`elderly_bookings_requested_total`)
  - Count of booking requests initiated via public/site flows.
  - Source: Incremented when `Booking` records created with status `pending`.
  - Owner: Product team.

- **Confirmed** (`elderly_bookings_confirmed_total`)
  - Count of bookings moved to `confirmed` state through admin or automated workflows.
  - Calculation: Derived from booking status history and mirrored in Prometheus metric.
  - Owner: Operations team.

- **Attended** (`elderly_bookings_attended_total`)
  - Number of confirmed bookings marked as attended after service delivery.
  - Validation: Compared weekly against attendance logs.

- **Cancelled** (`elderly_bookings_cancelled_total`)
  - Bookings cancelled either by caregivers or staff; includes no-shows when reclassified.

- **Conversion Rate**
  - Formula: `confirmed / requested` expressed as a percentage.
  - Reported on admin analytics dashboard and Grafana stat panel.

- **Attendance Rate**
  - Formula: `attended / confirmed` expressed as a percentage.

---

## Payment Metrics
- **Payments Total** (`payments_total`)
  - Count of `Payment` records created in the selected period.

- **Payments Succeeded** (`payments_succeeded_total`)
  - Payments with status `succeeded`.
  - Success Rate = `payments_succeeded_total / payments_total`.

- **Payments Failed** (`payments_failed_total`)
  - Payments with status `cancelled` or `requires_action` that did not recover.

- **Payments Refunded** (`payments_refunded_total`)
  - Count of payments marked `refunded` via Stripe webhook events.

- **Revenue (USD)**
  - Sum of `amount_cents` for succeeded payments / 100.
  - Displayed in admin analytics KPI card.

---

## Media Metrics
- **Media Uploads** (`media_uploads_total`)
  - Count of `MediaItem` records created (any category).

- **Virtual Tours Published** (`media_virtual_tours_total`)
  - Media items tagged with category `virtual_tour`.

---

## Notification Metrics
- **Notifications Sent** (`elderly_notifications_sent_total`)
  - Successfully delivered booking reminders (email + SMS).
  - Channel breakdown exposed via `channel` label.

- **Notifications Failed** (`elderly_notifications_failed_total`)
  - Delivery attempts resulting in vendor or system errors.

- **Notifications Skipped** (`elderly_notifications_skipped_total`)
  - Intentional skips due to preferences, opt-out, or quiet hours.

- **Failure Rate**
  - Formula: `increase(elderly_notifications_failed_total[5m]) / clamp_min(increase(elderly_notifications_sent_total[5m]), 1)`.
  - Alert threshold: >20% sustained for 10 minutes (see Grafana dashboard).

---

## Data Governance
- Metrics rely on application logs and Prometheus counters; retention is 30 days in staging, 180 days in production.
- Personally identifiable information is not included in metrics exports.
- Changes to metric names or formulas require Product + Engineering sign-off and an update to this document.
