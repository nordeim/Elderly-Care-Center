# Booking Metrics Overview

## Endpoint Summary

- **Path:** `/metrics/booking`
- **Content Type:** `text/plain; version=0.0.4`
- **Purpose:** Exposes booking lifecycle counters for Prometheus scraping.

## Metric Families

- `elderly_bookings_created_total`
  - Counter. Tracks total booking requests created via web or admin flows.
- `elderly_booking_status_total{status="<status>"}`
  - Gauge. Snapshot of booking counts per status from `config/booking.php`.
- `elderly_booking_status_transition_total{from="<from>",to="<to>"}`
  - Counter. Increments when `BookingInboxController` updates booking status.
- `elderly_reservation_sweeper_total{result="success|failure"}`
  - Counter. Records sweeper job outcomes from `ReservationSweeperJob`.

## Prometheus Configuration

Add the following job to `ops/observability/prometheus/prometheus.yml`:

```yaml
  - job_name: 'booking-metrics'
    metrics_path: /metrics/booking
    scrape_interval: 30s
    static_configs:
      - targets:
          - app:8000
        labels:
          service: elderly-booking
```

## Alerting Considerations

- Alert on `elderly_booking_status_total{status="pending"}` exceeding high watermark (e.g., > 100) for more than 15 minutes.
- Alert if `elderly_reservation_sweeper_total{result="failure"}` increases more than 3 times in 10 minutes.

## Dashboard Ideas

- Pending bookings time series.
- Status transition rate by pathway (web vs admin).
- Sweeper success/failure rate pie chart.

## Operational Notes

- Metrics rely on the cache store defined in `config/metrics.php` (default `redis`).
- Reset counters by clearing the `metrics:booking:*` keys in cache.
- Endpoint is unauthenticated; secure via network policies or add auth middleware in production.
