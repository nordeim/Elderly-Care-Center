# Notification Metrics Reference

**Last Updated:** 2025-09-25 (UTC+08)

---

## Metric Catalogue
- **`elderly_notifications_scheduled_total`** (counter)
  - Counts booking reminders queued for delivery across all channels.
  - Labels: none; channel-specific variants emit via `channel` label (`email`, `sms`).
- **`elderly_notifications_sent_total`** (counter)
  - Successful deliveries per channel.
  - Labels: `channel` (`email`, `sms`).
- **`elderly_notifications_failed_total`** (counter)
  - Delivery attempts that errored (provider, validation, exceptions).
  - Labels: `channel`.
- **`elderly_notifications_skipped_total`** (counter)
  - Reminders intentionally skipped (quiet hours, opt-out, missing contact).
  - Labels: `channel`.

All metrics sourced from `App\Support\Metrics\NotificationMetrics` and exposed via `BookingMetricsController` at `/metrics/booking`.

---

## Prometheus Scrape Example
```yaml
scrape_configs:
  - job_name: elderly-booking
    metrics_path: /metrics/booking
    static_configs:
      - targets: ['app.web:8080']
```

---

## Alerting Suggestions
- **High failure rate:**
  ```promql
  increase(elderly_notifications_failed_total[5m]) /
  clamp_min(increase(elderly_notifications_sent_total[5m]), 1) > 0.2
  ```
- **Skipped surge (SMS):**
  ```promql
  increase(elderly_notifications_skipped_total{channel="sms"}[10m]) > 5
  ```

Configure alerts to page after 10 minutes of continuous failure and notify support for skips over threshold.

---

## Grafana Panels
1. **Delivery Overview:** Stacked area of sent/failed per channel (`Panel ID: notif-delivery-overview`).
2. **Skip Reasons:** Single-stat showing latest skip count filtered by `channel="sms"`.
3. **Notification Backlog:** Combine queue depth metric (`queue_notifications_length`) with scheduled totals for correlation.

Panels reference Prometheus data source `PrometheusMain`.

---

## Operational Notes
- Metrics are stored under the `array` cache driver in non-production; ensure Redis or persistent store configured for staging/prod.
- Clear metrics namespace via cache flush only during maintenance windows; counters reset to zero afterwards.
- Tie runbook `docs/runbooks/notification-failures.md` to Grafana panel annotations for easier postmortems.
