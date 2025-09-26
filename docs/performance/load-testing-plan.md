# Load Testing Plan — Phase F

**Last Updated:** 2025-09-26 (UTC+08)

---

## Objectives
- Validate CDN effectiveness for media assets and static content.
- Ensure payment checkout flow maintains < 2.5s p95 latency under expected load.
- Confirm notification and booking APIs sustain projected traffic without queue backlog regression.

---

## Tooling & Environment
- **Tool:** k6 (preferred) or JMeter (fallback).
- **Environment:** Staging with CDN enabled (`media-staging.elderlydaycare.test`).
- **Data:** Use anonymized fixture data; reset staging database and Stripe test accounts before each run.
- **Monitoring:** Grafana dashboards (`booking-funnel`, `media-performance`), AWS CloudWatch for CDN metrics, Stripe dashboard for payment intent load.

---

## Scenarios
1. **Booking Funnel Flow**
   - Simulate public user browsing, booking request submission, and admin confirmation API.
   - Target: 20 virtual users (VUs), ramp to 60 VUs over 10 minutes.
   - Success: p95 latency < 1.5s for booking endpoints, error rate < 1%.

2. **Payment Checkout**
   - Simulate caregivers initiating deposit, invoking Stripe payment intent, and webhook callbacks (mocked or using Stripe test mode).
   - Target: 10 VUs sustained for 15 minutes.
   - Success: p95 latency < 2.5s, webhook queue depth stable, payment success rate ≥ 95%.

3. **Media Delivery via CDN**
   - Request mix of images/videos via CDN endpoints using 100 VUs for 15 minutes.
   - Success: CDN hit ratio ≥ 80%, p95 latency < 400ms, origin error rate < 0.5%.

4. **Notification API Burst (Optional)**
   - Trigger reminder scheduling endpoints with 30 VUs for 5 minutes.
   - Success: Queue backlog < 100 jobs, notification failure rate < 2%.

---

## Execution Steps
1. Deploy latest build to staging; verify migrations and CDN provisioning.
2. Run `scripts/performance/run-load-tests.sh --scenario all --vus 50 --duration 15m` to execute predefined scenarios.
3. Monitor dashboards in real time; capture screenshots or export metrics.
4. After tests, collect reports from `storage/load-tests/` and attach to sprint artifacts.

---

## Pass/Fail Criteria
- All scenarios meet latency and error thresholds.
- No critical incidents triggered (alerts, sustained 5xx, Stripe rate limiting).
- CDN hit ratio improvement recorded compared to baseline (Phase E metrics).

---

## Reporting
- Summarize results in `docs/performance/load-test-results/<date>.md` (create as needed).
- Include environment configuration, scenario outputs, and remediation actions if thresholds breached.
- Notify Product, QA, and DevOps leads of findings within 24 hours.

---

## Rollback & Mitigation
- If performance regressions detected, halt further deployments and open incident report.
- Revert CDN changes via Terraform if misconfiguration suspected.
- Escalate to engineering leadership for capacity planning adjustments.
