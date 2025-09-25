# Media Worker Operations Runbook

**Last Updated:** 2025-09-25 (UTC+08)

---

## Purpose
Queue workers (`ops/workers/media-worker-deployment.yaml`) execute media ingestion, virus scanning, and transcoding jobs (`IngestMediaJob`, `TranscodeJob`). This runbook guides on-call engineers through monitoring, scaling, and recovery.

---

## Service Overview
- **Deployment:** `media-worker` Kubernetes deployment (2 replicas, `queue:work --queue=media`).
- **Queues:** Redis connection `media` queue (see `config/queue.php`).
- **Jobs:**
  - `IngestMediaJob` — virus scanning & queueing transcode jobs.
  - `TranscodeJob` — invokes `TranscodingService` (ffmpeg) to produce conversions & thumbnails.
- **Metrics:** `MediaMetrics` emits `media_conversion_backlog`, `media_transcode_*`, `media_virus_scan_failure_total` (exposed via `/metrics/media`, TODO).
- **Logs:** Laravel default log channel (`storage/logs/laravel.log`) shipping via cluster logging agent.

---

## Monitoring & Alerts
- **Prometheus:** Ensure scrape target `booking-metrics` extended to include media metrics once exposed.
- **Key thresholds:**
  - `media_conversion_backlog > 25` for 10 minutes → investigate stuck jobs.
  - `media_transcode_failure_total` increments → review logs & ffmpeg exit codes.
  - `media_virus_scan_failure_total` > 0 → confirm scanner availability.
- **Dashboards:** Add panels to Grafana (TODO in Phase D plan).

---

## Routine Operations
1. **Scaling workers:**
   ```bash
   kubectl scale deployment/media-worker --replicas=<desired>
   ```
2. **Restart queue workers:**
   ```bash
   kubectl rollout restart deployment/media-worker
   ```
3. **Check queue depth:**
   ```bash
   kubectl exec deploy/media-worker -- php artisan horizon:stats
   ```
   (Alternatively inspect Redis `llen media`.)

---

## Incident Response
- **Symptom:** Jobs stuck in `pending` / backlog growing
  1. Verify Redis connectivity (`redis-cli -h <redis-host> ping`).
  2. Inspect worker pod logs for `ProcessFailedException` or storage errors.
  3. Manually retry failed jobs:
     ```bash
     php artisan queue:retry all
     ```
- **Symptom:** Virus scan failures
  - Ensure `ops/scripts/scan-media.sh` path exists and ClamAV daemon operational.
  - Temporarily disable scanning via `MEDIA_VIRUS_SCANNING=false` (with Product Owner approval) if causing outages.
- **Symptom:** Transcoding failures
  - Confirm ffmpeg available in worker image.
  - Review storage permissions; ensure bucket credentials valid.
  - Re-run specific job with `php artisan queue:retry <job-id>` once corrected.

---

## Maintenance
- **ClamAV signatures:** Schedule daily `freshclam` update on worker nodes.
- **Disk usage:** Monitor temp directory usage (jobs create temp files; `TranscodingService` cleans up on destruct). If leaks detected, inspect logs for exceptions preventing cleanup.
- **Dependency upgrades:** Validate ffmpeg changes in staging before prod rollout.

---

## Contacts
- **Primary Owner:** Media Pipeline Engineer
- **Escalation:** DevOps on-call → Engineering Manager → CTO

---

## References
- `ToDo_for_Phase_D_outstanding_items.md`
- `comprehensive_codebase_completion_execution_plan.md` — Phase D section
- `app/Jobs/Media/IngestMediaJob.php`
- `app/Jobs/Media/TranscodeJob.php`
- `app/Services/Media/TranscodingService.php`
