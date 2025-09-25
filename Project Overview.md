### Project purpose and audience

This repository delivers an accessibility-first web platform for elderly daycare centers to showcase services, build trust (staff profiles, certifications, testimonials, media), and convert visitors through a streamlined booking flow, with an admin dashboard for operations. It prioritizes usability for elderly users and caregivers, while enforcing robust security, observability, and phased delivery from MVP to production readiness.

---

### Core capabilities and modules

| Area | What it does | Who it serves | Key notes |
|---|---|---|---|
| Public site | Services, staff, testimonials, resources, virtual tours | Families, caregivers, elderly users | WCAG AA-compliant, high contrast, large text, keyboard navigation |
| Booking | Availability, slots, booking wizard, confirmations | Visitors and staff | End-to-end flow with capacity/constraints and conflict checks |
| Media | Video ingestion, HLS renditions, captions/transcripts | Trust-building content and accessibility | CDN-backed delivery, signed URLs, caption QA workflow |
| Admin | Content, bookings, media, roles/permissions, audit logs | Center staff and admins | RBAC, audit logging, intuitive dashboard |
| Ops | Metrics, alerts, runbooks, CI/CD, security gates | DevOps and operations | Prometheus metrics, Grafana dashboards, Sentry, release playbooks |

> Sources: 

---

### Architecture and stack

The platform uses a pragmatic Laravel monolith with server-side rendering, Livewire-driven interactivity, Tailwind for UI, Redis for sessions/queues, MariaDB for relational data, and a media pipeline (ffmpeg + object storage + CDN). Operational tooling includes Sentry for errors, Prometheus for metrics, Horizon/Telescope for queues and dev observability, and Docker Compose for local and production orchestration. Delivery is via vertical slices aligned to the PRD.

- **Core stack:** Laravel 12 (PHP 8.4), MariaDB 11.x, Redis 7.x, Livewire 3, Tailwind, Alpine.js, Vite, Apache, Docker Compose, Cloudflare CDN.
- **Media pipeline:** Pre-signed uploads → virus scan → ffmpeg HLS ABR ladder → captions/transcripts → CDN delivery with signed URLs for private assets.
- **Security controls:** TLS/HSTS/CSP, RBAC, audit logs, rate limiting, secure cookies, encryption at rest/in transit, dependency scanning, pen test pre-launch.
- **Observability:** Prometheus metrics (HTTP latency, 5xx ratio, queue depth, media backlog), alert thresholds with runbooks, Sentry integration.

---

### Development phases and status

Work is structured into phases with clear acceptance criteria and user validation. Current emphasis is on public content and booking, with trust/media and accounts/notifications following, then payments/analytics and launch hardening.

- **Phase 0 (Foundation):** Dockerized dev env, CI skeleton, RBAC, basic monitoring, auth.
- **Phase 1 (Public discovery & booking MVP):** Home/Services/Staff/Testimonials, booking request flow, admin CRUD, accessibility baseline.
- **Phase 2 (Trust & media):** Media ingestion with HLS, captions/transcripts, testimonials management, virtual tours, improved conflict handling.
- **Phase 3 (Accounts & notifications):** Caregiver accounts, booking history, calendar exports, email/SMS reminders.
- **Phase 4 (Payments & analytics):** Stripe-hosted flows, funnel dashboards, multi-region CDN for media.
- **Phase 5 (Polish & launch):** Accessibility and security audits, pen test, runbooks, training, go-live checklist.

The README shows Phase 1 as “Content Core & Basic Pages” in progress, with later phases queued.

---

### Non-functional targets, accessibility, and security

- **Performance:** p75 FCP < 1.5s, p95 TTI < 3s (mobile), API p95 < 300ms; booking p95 < 2.5s.
- **Reliability:** Availability ≥ 99.9% monthly; defined RPO/RTO for recovery.
- **Accessibility:** WCAG 2.1 AA baseline for core flows; larger text, contrast, captions/transcripts, keyboard navigation, automated axe checks in CI, mandatory manual audits per release.
- **Security:** SAST/DAST, secrets management, encryption at rest/in transit, RBAC, audit logs, pen testing; compliance decision flow for PHI/GDPR, with DPAs/BAA/DPIA if required.

---

### Operations, CI/CD, and deployment

- **CI/CD gates:** Lint, unit/integration tests, static analysis (PHPStan/PSalm), dependency/secret scanning, accessibility automated checks; block merges on critical failures.
- **Release strategy:** Immutable images, staging smoke + E2E tests, canary rollout, automated rollback scripts, incident runbooks for 5xx spikes, booking latency, and media backlog.
- **Runbooks and alerts:** Prometheus-backed alerts (5xx > 2% for 5m; booking p95 > 2.5s; media backlog > 50), with executable remediation steps and post-mortems.
- **Deploy playbook:** Pre-checks, maintenance window, migrations with lock-time caps, CDN invalidation, post-checks, cache warming (availability precompute for 14 days), heightened monitoring.

---

### What this repo enables for you

- **Operational hygiene:** Clear containerized setup, environment templates, phase-specific tests, and explicit production hardening steps. It aligns with deterministic startup and verifiable success criteria you expect.
- **Agent-friendly architecture:** Vertical slices and strong modular boundaries (Content, Booking, Media, Admin, Ops) support reproducible test harnesses and guardrails for complex flows, including media workers and queue governance.
- **Trust-first UX with measurable outcomes:** Accessibility commitments, media with captions/transcripts, and performance/SLO targets give you the levers to enforce quality across discovery-to-booking funnels.

---

### Gaps or notes to watch

- **Live demo/links:** The README references demo/docs/support links that look placeholder-like; validate environment, credentials, and real endpoints before relying on them.
- **Phase alignment in code:** Ensure actual codebase reflects the PAD’s modules (AvailabilityChecker, SlotGenerator, Prometheus middleware, audit logging) and that migrations/indexes exist (e.g., slot uniqueness).
- **Compliance scope:** If special needs or health-adjacent notes are enabled, execute the decision flow and legal tracks immediately to avoid late surprises.

---

### Recommended next steps

- **Confirm repo branch state and phase:** Run local setup, inspect modules and migrations, and verify phase tests mapped in README to ensure functional parity with the PRD/PAD.
- **Stand up observability early:** Integrate the RequestMetricsMiddleware and Prometheus exporter, wire dashboards and alert rules, and validate smoke targets (booking flow, media gallery, admin publish).
- **Lock accessibility gates:** Add axe-core to CI for critical pages, schedule manual audits for booking/admin flows, and capture findings in the acceptance criteria trackers.
- **Media pipeline dry-run:** Validate ffmpeg workers, ABR ladder outputs, caption generation and editorial QA workflow with signed URLs and CDN behavior under load.

If you want, I’ll map these steps into a phased execution checklist tailored to your Docker/Compose and healthcheck standards, plus explicit startup validation artifacts.

https://copilot.microsoft.com/shares/du4s1yYZy7vxH5qWPDJCd
