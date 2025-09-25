# Notification Failures Runbook

**Last Updated:** 2025-09-25 (UTC+08)  
**Audience:** On-call engineers & support team  
**Scope:** Email/SMS booking reminder pipeline (`BookingReminderNotification`, `SendReminderJob`).

---

## Alert Triggers
- **Primary:** `elderly_notifications_failed_total` rate > 5/min for 10 minutes.
- **Secondary:** `elderly_notifications_skipped_total{channel="sms"}` > 0 with SIMULATE flag disabled.
- **Queue backlog:** `queue:notifications` size > 50 for 15 minutes.

Alerts route to `#ops-notifications` and escalate to the on-call engineer after 10 minutes.

---

## Observability References
- **Metrics Dashboard:** Grafana → *Reminder Delivery* panels pulling from Prometheus `elderly_notifications_*` series.
- **Logs:** Search `notification_id` or `booking_notification_id` in centralized log system (Laravel channel `stack`).
- **Audit Logs:** `audit_logs` table entries with `action = calendar_export.*` confirm caregiver access.

---

## Diagnosis Checklist
1. **Confirm Queue Health**
   - `php artisan queue:failed` (interactive shell) for failed jobs.
   - `redis-cli llen notifications` to check backlog.
2. **Review Recent Logs**
   - Filter by `Failed to send booking reminder` message for exception details.
   - Look for provider responses (e.g., SMTP 5xx, SMS vendor codes).
3. **Verify Credentials**
   - Confirm `NOTIFICATIONS_EMAIL_DRIVER` / `NOTIFICATIONS_SMS_DRIVER` env variables.
   - Check provider dashboards for outages.
4. **Inspect Reminder Logs**
   - Query `booking_notifications` for recent `status = 'failed'` entries.
   - Ensure `scheduled_for` not in quiet hours window.

---

## Remediation Steps
- **Queue Stalls**
  1. `php artisan queue:retry all` to re-run failed jobs.
  2. Scale `media-worker` deployment if shared queue resources saturated.
- **Provider Failures**
  - Switch to fallback provider if SLA requires (update env + config cache).
  - Requeue failed notifications after verifying credentials.
- **Preference Issues**
  - If SMS opt-in disabled erroneously, update `caregiver_profiles.sms_opt_in` with consent record.
- **Quiet Hours Misconfiguration**
  - Adjust `NOTIFICATIONS_QUIET_HOURS_*` env vars, deploy config cache reload.

---

## Escalation Matrix
1. **Primary On-call Engineer** – Mitigate within 30 minutes.
2. **Platform Engineering Lead** – If incident > 30 minutes.
3. **Product Owner & Support Lead** – If caregiver communications impacted for > 1 hour.

---

## Post-Incident Tasks
- Add root-cause summary to `docs/incidents/` with impact, timeline, resolution.
- Update Prometheus alert thresholds if tuning required.
- If new failure pattern found, enhance runbook guidance and add automated checks.
