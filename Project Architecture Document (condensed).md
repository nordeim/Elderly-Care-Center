# Project architecture blueprint

This blueprint uses v3 as the foundation for pragmatic delivery, integrating v1’s comprehensive layers and v2’s modular boundaries to fully align with the PRD and Execution Plan. It is designed for maintainability, trust-first UX, operational reliability, and measurable outcomes.

---

## Architecture overview

- **Principles:** Monolithic Laravel SSR, server-driven interactivity via Livewire, progressive enhancement with Alpine, accessibility-first, performance-conscious media, and auditable operations.
- **Core stack:** Laravel 12 (PHP 8.4), MariaDB 11.x, Redis 7.x (sessions, cache, queues), Livewire 3, Alpine.js, TailwindCSS, Vite, Apache (prod), Docker Compose (dev/prod), Cloudflare CDN; Sentry for error tracking, Horizon for queues, Telescope (dev-only).
- **Delivery approach:** Vertical slices per Execution Plan, each shippable end-to-end with migrations, components, tests, and docs. Governance checklists ensure consistency.

---

## System components and modules

### Module overview

| Module | Key responsibilities | Primary models | Livewire components | External integrations |
|---|---|---|---|---|
| Content & trust | Home, services, staff, testimonials, case studies, certifications, FAQs | Service, Staff, Testimonial, CaseStudy, Certification, FAQ | ServiceExplorer, TestimonialsCarousel, CaseStudyShow | Cloudflare CDN |
| Booking | Availability, slots, multi-step wizard, confirmation emails | Booking, Slot, BlackoutDate, Room, ResourceConstraint | BookingWizard, BookingCalendar, AvailabilityMatrix | Mail (SMTP), Redis queues |
| Media | Photos, videos, responsive images, captions | Media (Spatie), MediaProcessingJob | MediaGallery, VideoPlayer | ffmpeg (HLS), Object storage/CDN |
| Admin & auth | Roles, permissions, content workflow, audit logs | User, Role, Permission, AuditLog | AdminDashboard, ContentEditor | Spatie Permission |
| Operations | Metrics, alerts, backups, error tracking | Metric (export only), BackupJob | OpsStatusPanel | Sentry, Prometheus, cAdvisor |

> Sources: (Not applicable; based on provided documents and alignment goals)

### Directory structure (condensed)

- **app/Domain/**
  - **Content:** Models, policies, controllers (Service, Staff, Testimonial, CaseStudy, Certification, FAQ)
  - **Booking:** Models (Booking, Slot, Room, ResourceConstraint, BlackoutDate), Services (AvailabilityChecker, SlotGenerator)
  - **Media:** Services (MediaProcessingService), Jobs (TranscodeVideoJob), Policies
  - **Admin:** Policies, Workflow (ContentState, ContentWorkflowPolicy), Auditing (AuditLogger)
  - **Ops:** Metrics (PrometheusExporter), Observability (RequestMetricsMiddleware), Backups (BackupService)
- **app/Livewire/** components grouped by domain
- **database/** migrations, seeders (initial content, roles)
- **config/** security.php, performance.php, media.php, ops.php

---

## Data model and capacity governance

### ERD highlights

- **Service:** id, title, description, duration_minutes, required_staff_ratio, active
- **Room:** id, name, capacity, accessible (bool)
- **ResourceConstraint:** id, room_id, service_id, max_clients, staff_ratio_override
- **Slot:** id, service_id, room_id, start_at, end_at, capacity, available_count, status
- **Booking:** id, slot_id, client_name, client_email, phone, emergency_contact, consent_at, special_needs_notes (nullable), status (pending|confirmed|cancelled), created_at
- **BlackoutDate:** id, start_at, end_at, reason, applies_to (room|service|global)

### Booking lifecycle

- **States:** pending → confirmed → attended/cancelled → archived
- **Guards:** capacity checks on room/service; staff ratio computed from service and constraints; blackout dates enforced; overlapping slots prevented via unique index on (room_id, start_at, end_at).
- **Consent & retention:** consent_at recorded at booking; special_needs_notes only enabled if consent captured and privacy policy acknowledged; retention policy enforced via scheduled purge.

### Capacity enforcement

- **AvailabilityChecker:** Aggregates constraints:
  - **Inputs:** service_id, date range, rooms, staff ratio, blackout dates.
  - **Logic:** Generates candidate slots → filters by blackout/resource/staff ratio → caches availability summary in Redis (TTL 5–15 minutes).
- **SlotGenerator:** Recurrence rules (daily/weekly), holiday calendar, room accessibility; writes slots idempotently with upserts and guards.

---

## Security, privacy, and compliance

- **Transport & headers:** HTTPS-only, HSTS max-age, CSP (strict, allow self + CDN), X-Frame-Options: DENY, Referrer-Policy: strict-origin-when-cross-origin, Permissions-Policy minimal.
- **Auth hardening:** Rate limiting on login and public forms; optional 2FA for admins; password policy balanced with usability; session rotation on privilege change.
- **Uploads:** MIME/size validation, EXIF GPS stripping, virus scanning via dedicated container, quarantine on suspicious files.
- **Consent & retention:**
  - **Consent capture:** explicit checkboxes for data use; separate consent for special needs and media usage.
  - **Retention windows:** bookings PII retained 12 months; special needs data retained 6 months unless legal requirement extends. Configurable in ops.php.
  - **Deletion workflow:** Admin-only, audited deletion; background job wipes related media and caches; privacy-safe soft-delete window with final hard-delete.
- **Audit logging:** CRUD on high-risk entities (bookings, staff, case studies, testimonials, certifications) with before/after diffs; immutable append-only logs stored in DB and shipped to secure storage periodically.

---

## Media pipeline and CDN

### Video pipeline (HLS/ffmpeg)

- **Flow:**
  - **Upload → Scan:** virus scan; validate codecs and size; extract metadata.
  - **Transcode:** ffmpeg to HLS with ABR ladder (e.g., 1080p@5Mbps, 720p@3Mbps, 480p@1.5Mbps); generate thumbnails; normalize audio levels.
  - **Captions:** required; upload or auto-generate draft then human review; block publish if missing.
  - **Store:** hot storage for recent; cold storage for archived; set lifecycle rules.
  - **Publish:** push playlists/segments to CDN; set cache headers; signed URLs for admin preview.
- **Responsive images:** Spatie medialibrary conversions (webp/jpg sizes: sm/md/lg), srcset, lazy loading, LQIP placeholders.
- **Accessibility:** larger controls, high-contrast player, captions, transcripts for key stories; keyboard controls; avoid autoplay.

---

## Performance and scalability

- **Caching tiers:**
  - **HTTP/CDN:** Cache static pages and media; cache-control rules; HTML edge caching for anonymous traffic with purge on content updates.
  - **App fragment cache:** Livewire fragment caching for testimonials, staff lists, service cards.
  - **Query cache:** Repository-level caching for frequently read content (services, FAQs).
- **DB optimization:** Composite indexes (slots, bookings), eager loading, N+1 guards via Laravel debug; slow query logging with thresholds.
- **Asset pipeline:** Vite hashed bundles, preloading critical CSS, defer non-critical JS; Tailwind JIT; font-display: swap; image compression.
- **Scalability plan:** Horizontal scaling for web (stateless), Redis HA via sentinel, DB read replicas for reporting; queue concurrency tuning for media jobs.

---

## Observability and SLOs

### SLO targets

| Area | SLO target | Measure | Scope |
|---|---|---|---|
| Availability | 99.9% monthly | Uptime per public route | Public pages |
| Performance | p75 FCP < 1.5s, p95 TTI < 3s | RUM + lab | Mobile |
| Booking success | > 95% completion | Funnel conversion | Booking wizard |
| Media processing | 90% jobs < 5 minutes | Queue job duration | Video pipeline |

### Metrics catalog (Prometheus-exported)

- **Web:**
  - **Label:** http_request_duration_seconds
    - Histogram with routes and method labels; p50/p95 derived by PromQL.
  - **Label:** http_5xx_ratio
    - Counter for 5xx; ratio per route.
- **Queue:**
  - **Label:** queue_job_duration_seconds
    - Job type labels (TranscodeVideoJob, SendBookingEmail).
  - **Label:** queue_job_failures_total
    - Failures by job type.
- **DB:**
  - **Label:** db_pool_in_use
    - Gauge for connections; saturation alerts.
  - **Label:** db_slow_queries_total
    - Counter; threshold > 200ms.
- **Media:**
  - **Label:** media_upload_errors_total
    - Error counter by cause.
  - **Label:** media_conversion_backlog
    - Gauge for pending jobs.
- **Business:**
  - **Label:** booking_funnel_progress_total
    - Step counts (step1_viewed, step2_validated, step3_submitted).
  - **Label:** booking_success_total
    - Confirmed bookings.

### Alerting (noise-free with runbooks)

| Alert | Condition | Initial threshold | Runbook summary |
|---|---|---|---|
| 5xx spike | http_5xx_ratio > 2% for 5m | 2% | Check recent deploy → roll back if needed; inspect error logs; disable heavy media |
| Booking latency | p95 http_request_duration_seconds{route="booking/*"} > 2.5s for 10m | 2.5s | Scale web workers; warm cache; check DB slow queries; degrade images |
| Queue backlog | media_conversion_backlog > 50 for 15m | 50 | Increase workers; verify ffmpeg hosts; pause new uploads; drain |
| DB saturation | db_pool_in_use > 80% for 10m | 80% | Scale DB; reduce concurrency; review slow queries; enable read replica for reporting |

---

## Deployment and operations

### Staged deploy playbook

1. **Pre-checks:**  
   - **Health:** run smoke tests on staging; Sentry quiet; queue drains < 10 jobs.  
   - **Backup:** snapshot DB + media manifests; verify restore procedure.

2. **Maintenance window:**  
   - **Enable:** app:down with retry for booking and contact; display friendly message.

3. **Migrations:**  
   - **Dry-run:** generate SQL diff (review indexes); apply with lock time caps; auto-retry with backoff.

4. **Deploy:**  
   - **Steps:** build assets (Vite), push image, run containers; invalidate CDN for changed paths.

5. **Post-checks:**  
   - **Smoke:** booking flow, media gallery, admin publish; check Prometheus metrics, Sentry alerts.

6. **Warm caches:**  
   - **Prime:** home/services/testimonials; precompute availability for next 14 days.

7. **Exit maintenance:**  
   - **Monitor:** 30–60 minutes heightened monitoring; auto rollback script available.

### Backup & recovery

- **DB:** nightly full, hourly incremental; monthly restore rehearsal.
- **Media:** object storage versioning; checksum verification; lifecycle rules (hot 90 days, cold thereafter).
- **Config & secrets:** encrypted backups; rotation every 90 days.

---

## Accessibility and UX

- **Foundations:** SSR, semantic HTML, ARIA roles, skip links, single-column mobile flows, large touch targets, visible focus rings.
- **Forms:** inline validation, error proximity, “Back” affordance, keyboard navigability; avoid nested modals.
- **Media:** captions required, contrast-checked controls, keyboard shortcuts; transcripts for key case studies.
- **Trust content:** testimonials with attribution and date; certifications verifiable; case studies with outcomes.

---

## Testing and CI/CD

- **Test strategy:**
  - **Feature tests:** core flows (booking, contact, admin publish) with DB transactions.
  - **Browser tests:** booking wizard, keyboard-only navigation, media playback.
  - **Performance tests:** page weight and FCP; media transcode duration bounds; DB slow query alerts.
  - **Security tests:** header presence, rate limits, upload validation, permission checks.
- **Coverage goal:** ≥ 80% for critical models/services; Dusk coverage for booking and media.
- **CI/CD pipeline:**
  - **Stages:** lint → unit/feature → Dusk → security scan (deps, CSP) → build → deploy → post-deploy smoke.
  - **Artifacts:** coverage reports, Lighthouse scores, metrics snapshots.
  - **Gates:** block deploy on failing SLO checks for critical pages; manual override documented.

---

## Implementation roadmap alignment

- **Phase 1–2 (Foundation):**
  - **Action:** Roles & permissions; content models; basic services page; queues & email; Sentry + Prometheus exporter; CI pipeline.
- **Phase 3–4 (Booking MVP):**
  - **Action:** SlotGenerator + AvailabilityChecker with rooms/resources; BookingWizard (no medical data yet); consent capture; confirmation emails; fragment caching.
- **Phase 5 (Media):**
  - **Action:** Image conversions, EXIF stripping; HLS pipeline; captions workflow; CDN cache rules; queue monitoring.
- **Phase 6 (Trust & Admin):**
  - **Action:** Testimonials, case studies, certifications; ContentState (draft/publish/schedule), approvals; audit logs; preview before publish.
- **Phase 7 (Optimization & Ops):**
  - **Action:** SLO tuning, alerts with runbooks; backups rehearsal; performance passes (indexes/eager-loading); asset hashing/CDN; accessibility audit and fixes.

---

### Governance checklists

- **Content governance:**
  - **States:** draft, review, scheduled, published, archived.
  - **Approvals:** required for testimonials/case studies/certifications.
  - **Versioning:** maintain change history; preview before publish.
- **Privacy governance:**
  - **Consent:** explicit + granular; log consent artifacts.
  - **Retention:** enforce purge jobs; admin override with audit.
  - **Access:** restrict sensitive fields; redact in logs.
- **Operational governance:**
  - **Metrics:** export and validate; alert thresholds reviewed quarterly.
  - **Security:** quarterly header/captcha/rate-limit audit; vulnerability scans.
  - **Recovery:** monthly restore tests; documented RPO/RTO.

---

### Ready-to-implement snippets

#### Prometheus middleware registration (web kernel)

```php
// app/Http/Middleware/RequestMetricsMiddleware.php
public function handle($request, Closure $next) {
    $start = microtime(true);
    $response = $next($request);
    $duration = microtime(true) - $start;

    app('prometheus')->histogram('http_request_duration_seconds', 'Request duration', ['route','method','status'])
        ->observe($duration, [$request->route()->uri(), $request->method(), $response->getStatusCode()]);

    if ($response->getStatusCode() >= 500) {
        app('prometheus')->counter('http_5xx_total', 'Server error responses', ['route'])
            ->inc([$request->route()->uri()]);
    }
    return $response;
}
```

#### Content workflow trait

```php
// app/Domain/Admin/Workflow/ContentState.php
trait ContentState {
    public function publish(): void { $this->update(['state' => 'published', 'published_at' => now()]); }
    public function schedule(Carbon $at): void { $this->update(['state' => 'scheduled', 'scheduled_at' => $at]); }
    public function archive(): void { $this->update(['state' => 'archived']); }
    public function isPublic(): bool { return $this->state === 'published' && ($this->scheduled_at === null || $this->scheduled_at <= now()); }
}
```

#### Slot uniqueness index (migration)

```php
Schema::table('slots', function (Blueprint $table) {
    $table->unique(['room_id','start_at','end_at'], 'slots_room_time_unique');
});

https://copilot.microsoft.com/shares/2W6u2cuv8BQfQGuSp2SdV
