# Elderly Daycare Platform — Merged PRD & Execution Plan (v2 — PAD-aligned)

> **Single source of truth:** this is the updated, drop-in replacement PRD + Execution Plan that merges the original PRD, the Execution Plan, and the PAD\_condensed architecture specifics. It imports PAD’s SLOs, Prometheus metrics & alerts, media pipeline details, deploy playbook, and operational runbooks — and it adds explicit compliance, security gating, retention harmonization, and PWA/offline resilience.

---

## Table of contents

1. Executive summary & key changes (v2)
2. Project overview & goals
3. Personas & user journeys
4. Scope & prioritized features (phases)
5. Technical architecture & stack
6. Non-functional requirements (NFRs) & SLOs — PAD-aligned
7. Security & privacy (HIPAA / GDPR decision node)
8. Accessibility & UX standards
9. Media pipeline & storage lifecycle (ffmpeg + HLS)
10. Observability: Prometheus metrics catalog, alerts & runbooks (from PAD)
11. CI/CD, security gates & release strategy
12. Testing & quality strategy (incl. pen-test requirement)
13. Integrations & APIs
14. Offline resilience & PWA design
15. Phased execution plan (detailed) — with acceptance criteria
16. Deploy playbook & runbooks (executable checklist)
17. Data retention policy (harmonized)
18. Risks, assumptions & mitigations
19. Deliverables, signoffs & governance (owners)
20. Integrated checklists (actionable)
21. Appendix: sample ffmpeg ladder, sample Prometheus rules, sample runbook commands

---

## 1. Executive summary & key changes (v2)

This version (v2) is a drop-in replacement for the previously merged PRD + Execution Plan. Major high-priority edits added:

* Imported PAD performance SLOs (p75 FCP < 1.5s, p95 TTI < 3s mobile) and metrics catalog. (Owner: DevOps)
* Added Prometheus metrics names, labels, and recommended alert thresholds from PAD. (Owner: Observability)
* Added concrete media pipeline (ffmpeg transcode/HLS ladder, caption and transcript policy, signed URL policy, virus scanning). (Owner: Media eng)
* Explicit *compliance decision node*: determine PHI/EU personal data in-scope → trigger HIPAA/DPIA/BAA/DPA workstreams. (Owner: Product + Legal)
* CI/CD security gates: SAST, DAST, dependency scanning, secret scanning in pipeline; require pass before merge; schedule external pen test pre-launch. (Owner: Security)
* Harmonized retention table with PAD values and PRD audit-log requirements. (Owner: Ops)
* PWA/offline resilience design added to support caregivers in low-connectivity environments. (Owner: Frontend)
* Deploy playbook and runbooks imported and expanded (with pre/post checks and rollback steps). (Owner: DevOps)

All additions are traceable to PAD recommendations and to the gaps previously identified in the merged PRD.

---

## 2. Project overview & goals

*Purpose:* Build a modern, responsive, accessible platform for elderly daycare centers to present services, host trustworthy media, enable bookings/enrolment and provide a reliable admin experience for non-technical staff.

*Primary objectives:* convert visitors to bookings, provide trust signals (staff profiles, tours, testimonials), maintain accessibility for older adults and caregivers, operate securely, and deliver repeatable deployments with observability.

*Key success metrics:* (see section 6 — SLOs)

---

## 3. Personas & user journeys

(Same as prior merged PRD; each phase must include user validation with elderly participants and caregivers.)

---

## 4. Scope & prioritized features (phases)

(Phase 0..5 retained. See section 15 for per-phase acceptance criteria.)

---

## 5. Technical architecture & stack

**Reference stack (aligned with PAD):**

* Backend: Laravel (API-first) with SSR using Blade/Livewire for progressive enhancement. Use PHP 8.x supported LTS. (Owner: Backend)
* Frontend: Tailwind CSS + Alpine.js; PWA service worker for offline. (Owner: Frontend)
* DB: MariaDB 11.x (or PostgreSQL if chosen) with read-replicas for scale. (Owner: DB)
* Cache/Queue: Redis
* Media: S3-compatible object store + CDN; media transcoding cluster (ffmpeg workers). (Owner: Media eng)
* Observability: Prometheus + Grafana + OpenTelemetry traces + Sentry for error tracking. (Owner: Observability)
* CI/CD: GitHub Actions → build → tests → container images → staging deploy. (Owner: DevOps)
* Secrets manager + KMS for encryption keys

Design: stateless web nodes, externalized sessions, containerized services, ABR media via HLS.

---

## 6. Non-functional requirements (NFRs) & SLOs — PAD-aligned

**Performance (RUM & API):**

* p75 FCP (First Contentful Paint) < **1.5s** (mobile). (PAD import)
* p95 TTI (Time to Interactive) < **3.0s** (mobile). (PAD import)
* Site median page load (mobile): < 2s (baseline). Use PAD numbers as stretch targets.
* API p95 latency: < **300ms**; booking endpoint p95 latency < **2.5s**.
* Acceptable 5xx error ratio: < **0.5%** over 10m sliding window (Alert threshold: >2% for 5m triggers P0). (PAD import)

**Availability & Recovery:**

* Uptime target: **99.9%** monthly.
* RPO (data loss tolerance): **4 hours** for critical booking data.
* RTO (recovery): **2 hours** for critical services.

**Security & Compliance:**

* TLS 1.2+ enforced, HSTS enabled.
* Encryption at rest for sensitive data (AES-256) with managed KMS.
* RBAC for admin functions; access audit logs retained per retention table.

**Maintainability / Testing:**

* Unit coverage target ≥ 70% for business logic; critical flows 90%+.
* SAST and DAST must pass in CI before merge to main.

**Observability:**

* Prometheus metrics, Grafana dashboards, Alerting rules as per section 10.

---

## 7. Security & privacy (HIPAA / GDPR decision node)

**Decision node (must be executed during Phase 0):**

* Determine whether the platform will **store or process PHI** (Protected Health Information) or **process EU personal data**.

  * If **PHI in scope**: Trigger HIPAA track — require Business Associate Agreement (BAA) with hosting vendor, implement HIPAA administrative and technical controls, enable additional audit log retention, mandatory staff training, annual external pen-test, and breach notification runbook. (Owner: Product + Legal)
  * If **EU personal data in scope**: Trigger GDPR track — conduct DPIA, appoint DPO (if required), sign Data Processing Agreements (DPA) with sub-processors, define lawful bases and implement data subject request workflows. (Owner: Product + Legal)
  * If neither: Document decision and store the assessment.

**Technical controls (minimum):**

* TLS everywhere, TLS certificate management, HSTS, CSP headers.
* Audit logging for read/write of user records (who/what/when).
* Least privilege for DB access and KMS keys.
* SAST/DAST pipeline and dependency scanning.

**Operational controls:**

* Incident response plan and runbook (P0/P1/P2 defined), on-call rotation, contact matrix and legal notification timelines.

---

## 8. Accessibility & UX standards

Commit to WCAG 2.1 AA baseline (prefer 2.2 AA where practical). Include automated axe-core checks in CI and manual screen-reader audits. Recruit elderly users/caregivers for usability testing in Beta.

---

## 9. Media pipeline & storage lifecycle (ffmpeg + HLS)

**Requirements:**

* All uploaded video content must have captions and transcripts (automatic speech-to-text + human QA for accuracy). Audio-only transcripts required. (Owner: Media)
* Virus scanning for uploaded files at ingest (ClamAV or managed equivalent).
* Strip EXIF and PII from images on ingest.

**Transcoding & ABR Ladder (sample):**

* Source ingest (mp4) → Transcode worker (ffmpeg) → HLS outputs with ABR ladders:

  * 1080p (1920x1080) — 4500 kbps
  * 720p  (1280x720)  — 2500 kbps
  * 480p  (854x480)   — 1200 kbps
  * 360p  (640x360)   — 700 kbps
  * 240p  (426x240)   — 300 kbps
* Create web-optimized preview (poster + LQIP) and store master + renditions in S3.

**Delivery:**

* CDN-backed HLS via signed URLs for private content (short expiry) and normal CDN caching for public content.
* Storage lifecycle: hot (30 days in S3), warm (90 days), archive (Glacier / long-term cold) per policy and cost constraints.

**Operational controls:**

* Media conversion backlog metric (see metrics catalog). If backlog > **50** transcoding jobs for >1h, alert DevOps. (PAD import)

---

## 10. Observability: Prometheus metrics catalog, alerts & runbooks (from PAD)

**Prometheus metrics (recommended):**

* `http_request_duration_seconds` (labels: handler, method, status\_code, route) — histogram for request latency. Alert p95 > 1s for static views, > 2.5s for booking endpoints.
* `http_request_errors_total` (labels: handler, method, status\_code, route) — counter for errors. Alert when 5xx ratio > 2% over 5m.
* `booking_endpoint_latency_seconds` (labels: status) — histogram specifically for booking create/update flows.
* `queue_jobs_count` (labels: queue\_name) — gauge for queue depth. Alert when queue depth > 100 for >10m or job\_duration p95 > 120s.
* `media_conversion_backlog` — gauge for pending transcode jobs. Alert when > 50 for >1h.
* `booking_funnel_progress_total` — counter for stage events (view → start booking → complete booking) for conversion monitoring.
* `redis_memory_bytes`, `db_connections`, `db_slow_queries_total` — infra health metrics.

**Sample alert thresholds (PAD-aligned):**

* `http_5xx_ratio > 2%` over 5m → P0 alert — runbook: check error traces in Sentry, recent deploys, rollback if needed.
* `booking_endpoint_p95_latency > 2.5s` for 10m → P1 — runbook: check DB slow queries, analyze recent migrations, check queue backlog.
* `media_conversion_backlog > 50` for 1h → P2 — runbook: scale transcode workers, inspect ffmpeg failures.

**Runbook pointers (store in repo `/docs/runbooks/`):**

* `/docs/runbooks/incident_5xx_spike.md` — steps: identify service, check Sentry traces, identify most frequent 5xx path, compare release timestamps, rollback or patch, notify stakeholders.
* `/docs/runbooks/incident_booking_latency.md` — steps: check db slow queries, check cache heat, check queue backlogs, scale DB read replicas if needed.

---

## 11. CI/CD, security gates & release strategy

**Pipeline (GitHub Actions recommended):**

* Steps: format & lint → unit tests → build → SAST (PHPStan/PSalm, SonarCloud) → dependency scan & secret scan → DAST (OWASP ZAP) for staging → build artifacts → integration/E2E tests → staging deploy.
* Block merge to main if SAST/DAST/Dependency checks fail.

**Release strategy:**

* Promote via manual approval: staging → canary (5–10% traffic) → full prod or blue/green.
* Pre-deploy checks: smoke tests, queue drain, dry-run migrations.
* Post-deploy: smoke verification, key metrics check (prometheus), synthetic user journey test.

**Security gating / pen-test:**

* Schedule external penetration test against production-like environment prior to public launch.
* Critical vulnerabilities must be fixed before public release; high vulnerabilities must have formal risk acceptance if deferred.

---

## 12. Testing & quality strategy (incl. pen-test requirement)

**Automated tests:** unit, integration, E2E (Cypress), accessibility scans (axe), visual regression.
**Load testing:** Use k6 with booking scenario; capacity tests for media pages with CDN.
**Security testing:** SAST & DAST in CI; external pen-test pre-launch and annually thereafter.

---

## 13. Integrations & APIs

Calendar (iCal/Google), SMS (Twilio), Email (SES/Sendgrid), Payment (Stripe) via hosted flows, EHR/FHIR (only if required with strict consent & legal review).

---

## 14. Offline resilience & PWA design

**Goals:** Allow caregivers/admins to view cached schedules, client notes, and to queue booking actions offline which sync when connectivity returns.

**Approach:**

* Implement PWA service worker caching strategies: cache-first for static assets, network-first with fallback for dynamic schedules.
* Background sync to attempt queued submissions; include conflict resolution using versioning / optimistic concurrency keys.

**Acceptance:** Offline scheduling queue persists across restarts; queued actions retry and present conflict UI to user when needed.

---

## 15. Phased execution plan (detailed)

(Vertical slice approach retained.) High-level timeline for team of 2 devs + 1 designer + 1 QA: Phase 0 Foundation (2–3w); Phase 1 MVP (5–7w); Phase 2 Trust & Media (3–4w); Phase 3 Accounts & Notifications (4–6w); Phase 4 Payments & Scale (3–5w); Phase 5 Polish & Compliance (2–4w).

Per-phase acceptance criteria updated to include SLO gates, security gates and PAD operational checks. E.g., Phase 1 cannot be accepted unless:

* E2E booking test passes in staging.
* Accessibility baseline checks pass in CI and manual audit performed.
* SAST and dependency scans pass.
* Observability dashboards exist for booking flows and media.

---

## 16. Deploy playbook & runbooks (executable checklist)

**Pre-deploy (manual checklist):**

* [ ] Confirm green CI on main.
* [ ] Confirm SAST/DAST passed and no outstanding critical vulns.
* [ ] Announce maintenance / release window.
* [ ] Drain background queue or ensure workers scaled accordingly.
* [ ] Run database migration dry-run on staging; ensure reversible migrations.

**Deploy steps:**

* Create release tag and immutable docker image.
* Deploy to canary (5–10% traffic) or blue environment.
* Run smoke tests (health endpoints, booking create smoke test).
* Monitor key metrics for 10–15 minutes (http\_5xx\_ratio, booking\_latency\_p95, queue\_depth).

**Rollback:**

* If critical alert triggers or synthetic tests fail, promote previous docker image and run rollback script: `scripts/rollback.sh <previous-tag>`.

**Runbooks:** Stored in `/docs/runbooks/*.md` in repo and mirrored to Ops knowledge base.

---

## 17. Data retention policy (harmonized)

| Data type                      |                                             Retention | Notes                                                     |
| ------------------------------ | ----------------------------------------------------: | --------------------------------------------------------- |
| Booking PII                    |                         12 months after last activity | Can be extended per consent.                              |
| Special\_needs / medical notes | 6 months after client exit (or per legal requirement) | If PHI in scope, align with HIPAA retention requirements. |
| Audit logs (admin actions)     |                                             12 months | Immutable storage recommended.                            |
| System logs (app logs)         |                                    30 days searchable | Long-term archive cold storage if required.               |
| Backups (DB snapshots)         |                                               90 days | Encrypted, tested restores quarterly.                     |

(Owners: Ops + Product must approve and document in policy file `/docs/data_retention.md`.)

---

## 18. Risks, assumptions & mitigations

(Expanded with PAD integrations: media costs, PHI in scope, accessibility risks, timeline slippage.)

---

## 19. Deliverables, signoffs & governance (owners)

**Key owners (recommended):**

* Product owner: **TBD** — decision maker for PHI/GDPR scope
* Lead dev: **TBD** — technical signoff
* Observability/DevOps: **TBD** — owns SLOs and runbooks
* Security: **TBD** — owns SAST/DAST gates and pen-test scheduling
* Legal: **TBD** — owns BAAs, DPAs, DPIAs

Signoff workflow: Product → Accessibility → Security → Stakeholder acceptance.

---

## 20. Integrated checklists (actionable)

**High-priority (do now):**

* [ ] Execute compliance decision node and document result. (Owner: Product + Legal)
* [ ] Add PAD SLOs & Prometheus metrics to repo dashboards. (Owner: Observability)
* [ ] Add media pipeline details and start implementing ffmpeg workers. (Owner: Media eng)
* [ ] Add CI SAST/DAST gates and secret scanning. (Owner: Security)
* [ ] Schedule external pen-test pre-launch and define remediation SLA. (Owner: Security)

**Phase-by-phase checklists:** See appendix and section 15 for per-phase acceptance criteria.

---

## 21. Appendix: sample ffmpeg ladder, sample Prometheus rules, runbook commands

**Sample ffmpeg transcode command (1080p):**

```
ffmpeg -i input.mp4 -c:v libx264 -preset medium -b:v 4500k -maxrate 4830k -bufsize 9000k -vf "scale=1920:1080" -c:a aac -b:a 128k -hls_time 6 -hls_playlist_type vod out_1080p.m3u8
```

**Sample Prometheus alert rule (booking latency):**

```
- alert: BookingEndpointHighLatency
  expr: histogram_quantile(0.95, sum(rate(booking_endpoint_latency_seconds_bucket[5m])) by (le)) > 2.5
  for: 10m
  labels:
    severity: page
  annotations:
    summary: "Booking endpoint p95 latency > 2.5s"
    runbook: "/docs/runbooks/incident_booking_latency.md"
```

**Runbook excerpt (incident booking latency):**

1. Open Grafana dashboard for booking flows.
2. Check query slow logs and db slow queries (`SELECT * FROM mysql.slow_log ...`).
3. Check Redis memory & connection status.
4. If DB is the cause, scale read replicas or apply indexing fix and deploy migration in maintenance window.

---

*End of document.*
