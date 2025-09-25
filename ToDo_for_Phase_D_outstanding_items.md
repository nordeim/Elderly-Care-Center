# Phase D Outstanding Items — Execution Plan

**Prepared:** 2025-09-25 (UTC+08)

## Overview
Phase D focuses on launching the media pipeline and reinforcing trust-building content. The following plan outlines remaining deliverables, sequencing, and ownership to reach Phase D exit criteria defined in `comprehensive_codebase_completion_execution_plan.md`.

---

## Workstreams & Deliverables

### 1. Media Data Model & Storage Foundations
- Define database schema for media assets (`database/migrations/2025_03_XX_create_media_tables.php`) and Eloquent models.
- Create `config/media.php` with storage bucket settings, transcoding profiles, and quotas.
- Implement storage abstraction (S3-compatible) with signed upload URL service.
- Update environment examples and seed sample records.

### 2. Ingestion & Transcoding Pipeline
- Implement `app/Jobs/Media/IngestMediaJob.php`, `app/Jobs/Media/TranscodeJob.php`, and `app/Services/Media/TranscodingService.php`.
- Integrate virus scanning script (`ops/scripts/scan-media.sh`) and job orchestration.
- Configure queue routing, retries/backoff, and caption generation hook.
- Emit metrics/logs for queue backlog, failures, and processing time.

### 3. Worker Deployment & Operations
- Author `ops/workers/media-worker-deployment.yaml` for containerized workers.
- Document runbook covering scale-up/down, secrets rotation, and failure recovery.
- Ensure CI/CD updates include worker build/deploy steps.

### 4. Accessibility & Trust Frontend
- Build `resources/views/components/media/player.blade.php` with accessible controls, captions, and transcript support.
- Create `resources/views/pages/virtual-tour.blade.php` and wire media assets into testimonials/admin flow.
- Integrate consent messaging and privacy links for media usage.

### 5. Testing & Validation
- Implement `tests/Unit/Media/TranscodingServiceTest.php` using mocks/fakes.
- Implement `tests/Feature/MediaUploadTest.php` and browser smoke test for playback.
- Conduct elderly user validation sessions; capture findings in validation report.

### 6. Documentation & Compliance
- Draft `docs/media/captioning-guidelines.md` and update privacy assessment for media handling.
- Extend observability documentation with media metrics and alert thresholds.
- Update `docs/runbooks/` and compliance evidence as deliverables complete.

---

## Timeline & Sequencing

| Sprint | Focus | Key Outputs |
| --- | --- | --- |
| Sprint 1 (Weeks 1–2) | Workstreams 1 & 2 | Media schema, config, ingestion/transcoding jobs, metrics instrumentation |
| Sprint 2 (Weeks 3–4) | Workstreams 3 & 4 | Worker deployment files, ops runbooks, media player & virtual tour UI |
| Sprint 3 (Week 5) | Workstreams 5 & 6 | Automated tests, validation sessions, captioning guidelines, documentation updates |

---

## Risks & Mitigations
- **FFmpeg resource cost:** Set quotas in `config/media.php` and monitor via new Prometheus metrics.
- **Accessibility regressions:** Involve Accessibility Lead during component reviews and manual audits.
- **Security of uploads:** Enforce short-lived signed URLs, virus scanning, and audit logging.

---

## Exit Criteria Checklist
- Media pipeline stable in staging, including virus scanning and signed URLs.
- Captions/transcripts mandatory and verified in UI.
- Trust content with media embedded on public pages.
- Metrics (`media_conversion_backlog`, failures) and alerts configured.
- Validation sessions completed; documentation updated.
