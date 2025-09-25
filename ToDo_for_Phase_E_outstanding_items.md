# Phase E Sub-Plan — Accounts, Notifications & Calendars

**Source Alignment:** `comprehensive_codebase_completion_execution_plan.md` §Phase E  
**Objective:** Deliver caregiver-facing accounts with booking visibility, automated reminders, calendar export tooling, and enhanced audit logging with observability & documentation.

---

## Workstream 1 — Caregiver Account Experiences

### 1. `app/Http/Controllers/Caregiver/DashboardController.php`
- **Description:** Controller exposing authenticated caregiver dashboard, aggregating upcoming bookings, reminders status, and profile preferences.
- **Checklist:**
  - Ensure controller enforces caregiver guard & authorization (`RolePolicy`).
  - Load bookings with eager relationships (services, staff) scoped to caregiver account.
  - Provide view data for notification preferences and calendar export links.
  - Add localized flash messaging hooks for profile updates.

### 2. `resources/views/caregiver/dashboard.blade.php`
- **Description:** Accessible Blade view rendering caregiver dashboard, integrating booking history, reminders toggle, and calendar export CTA.
- **Checklist:**
  - Include responsive layout with WCAG-compliant focus states & semantic headings.
  - Display upcoming bookings table, past bookings accordion, and notification preferences form.
  - Integrate `@csrf` form for preference updates and provide ARIA labels for toggles.
  - Surface calendar export download link generated via `ICalGenerator`.

### 3. `database/migrations/2025_04_XX_add_account_tables.php`
- **Description:** Migration extending caregiver profiles with preferences, notification channels, MFA secrets, plus linking users ↔ clients if applicable.
- **Checklist:**
  - Add `caregiver_profiles` table with fields (user_id, preferred_contact_method, timezone, sms_opt_in, mfa_secret, last_login_at).
  - Include indices and foreign keys to `users` and `clients` as required.
  - Add `booking_notifications` table for preference overrides (booking_id, channel, status).
  - Provide rollback ensuring foreign key constraints dropped in reverse order.

---

## Workstream 2 — Notifications & Reminders

### 1. `app/Notifications/BookingReminderNotification.php`
- **Description:** Notification class sending multi-channel reminders (mail, SMS) with personalized content.
- **Checklist:**
  - Implement `via()` returning channel list based on caregiver preferences.
  - Define `toMail()` with markdown template referencing reminder Blade view.
  - Provide `toVonage()`/`toNexmo()` or SMS channel equivalent.
  - Attach metadata for audit logging (delivery window, booking_id).

### 2. `app/Jobs/Notifications/SendReminderJob.php`
- **Description:** Queue job orchestrating reminder scheduling, de-duplication, and retry behavior.
- **Checklist:**
  - Accept booking ID + reminder type; ensure idempotency key to avoid duplicates.
  - Respect `config('notifications.retry')` backoff windows.
  - Record metrics (`notification_success_total`, `notification_failure_total`).
  - Write audit log entry per dispatch.

### 3. `config/notifications.php`
- **Description:** Configuration specifying providers, retry policies, quiet hours, and template overrides.
- **Checklist:**
  - Define `channels` array (mail, sms) with provider credentials env lookups.
  - Set default `reminder_window_hours`, `quiet_hours`, and `max_attempts`.
  - Include feature flags for preview/testing environments.
  - Document config keys inline for ops team.

### 4. `resources/views/emails/reminder.blade.php`
- **Description:** Markdown email template for booking reminders.
- **Checklist:**
  - Include dynamic booking details (date, time, location, staff member).
  - Provide CTA buttons for rescheduling/cancel link with signed URLs.
  - Add accessibility-compliant alt text for imagery (if any).
  - Reference fallback contact phone/email.

---

## Workstream 3 — Calendar Export & Audit Logging

### 1. `app/Services/Calendar/ICalGenerator.php`
- **Description:** Service creating iCal feeds/files for caregiver bookings.
- **Checklist:**
  - Generate valid RFC 5545 iCal strings with VEVENT entries per booking.
  - Support timezone conversion per caregiver preference.
  - Encode secure token for ICS download links.
  - Include unit tests for recurrence/no recurrence cases.

### 2. `resources/views/calendar/booking-export.blade.php`
- **Description:** Lightweight view for presenting ICS download instructions and linking to generated feed.
- **Checklist:**
  - Provide explanation of how to import into Google/Outlook.
  - Offer button to download ICS file and link to subscribe URL.
  - Add troubleshooting FAQ accordion.
  - Ensure page accessible via caregiver dashboard CTA.

### 3. `database/migrations/2025_04_XX_create_audit_logs_table.php`
- **Description:** Migration establishing audit logs capturing critical account & notification events.
- **Checklist:**
  - Define `audit_logs` table with fields (id, actor_id, actor_type, action, target_id, target_type, meta JSON, ip_address, created_at).
  - Add indices on `actor_id`, `target_id`, and `action` for query efficiency.
  - Ensure storage engine & charset align with schema standards.
  - Provide down migration dropping indices then table.

---

## Workstream 4 — Testing, Observability & Operations

### 1. `tests/Feature/Notifications/ReminderTest.php`
- **Description:** Feature test verifying reminder job dispatch and notification delivery logic.
- **Checklist:**
  - Use fakes for mail/SMS to assert dispatch counts.
  - Cover quiet-hour suppression and retry scheduling.
  - Assert audit log entries and metrics increments.

### 2. `tests/Feature/Calendar/ICalExportTest.php`
- **Description:** Feature test confirming ICS generation and download endpoints.
- **Checklist:**
  - Assert ICS response headers/content.
  - Validate timezone conversion logic.
  - Ensure unauthorized users denied access.

### 3. `docs/runbooks/notification-failures.md`
- **Description:** Operational runbook for diagnosing notification pipeline issues.
- **Checklist:**
  - Document alert thresholds, dashboards, and provider status pages.
  - Provide step-by-step remediation for common failures (credential expiry, queue backlog).
  - Include escalation matrix and sample commands for replaying jobs.

### 4. `docs/validation/phase-e-account-usability.md`
- **Description:** Validation report capturing caregiver usability sessions for new account features.
- **Checklist:**
  - Summarize participant demographics and devices.
  - Document findings for dashboard clarity, reminders accuracy, calendar adoption.
  - Log accessibility outcomes and follow-up actions.

### 5. `docs/observability/notification-metrics.md`
- **Description:** Documentation of new metrics/alerts for notifications and calendar exports.
- **Checklist:**
  - Define each metric (name, type, tags, threshold).
  - Provide Prometheus query samples and Grafana panel IDs.
  - Note alert routing paths and runbook references.

---

## Cross-Cutting Checklist
- **Security & Privacy:** Audit logging integrated, MFA optional for admins/caregivers, data minimization enforced in notifications.
- **Accessibility:** Dashboard and email templates pass WCAG checks; transcripts backlog tracked for future phases.
- **Observability:** Metrics for notifications/calendar exports registered; alerts configured with Ops.
- **QA & Validation:** Feature tests green; usability study scheduled; documentation updated in `README.md` release notes.

---

## Milestone Tracking
- Track progress via this checklist and update statuses during sprint reviews.
- Ensure alignment with Product Owner and QA for exit criteria sign-off prior to Phase F kickoff.
