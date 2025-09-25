# Runbook — Authentication Access Issues

**Purpose:** Provide on-call staff with actionable steps to diagnose and resolve authentication failures for admin/staff users.

## 1. Alert Triggers

- Prometheus alert `http_5xx_ratio` > 2% with `/login` route in top offenders.
- Support ticket reporting login failures (invalid creds despite correct input, lockouts).
- Security tooling flags abnormal login attempts (rate limit exceeded).

## 2. Immediate Triage Checklist

- **Confirm Incident Context**: Timestamp, affected environment (staging/production), impacted roles.
- **Check Rate Limits**: Inspect Redis for throttle keys (`login|<IP>`). Clear keys if necessary.
- **Review Recent Deployments**: Identify if new release touched `app/Http/Controllers/Auth/LoginController.php` or auth middleware.
- **Validate Secrets**: Ensure env vars (`APP_KEY`, DB credentials) loaded by containers.

## 3. Diagnostic Commands

```bash
# Tail structured auth logs
kubectl logs deploy/elderly-app --tail=200 | jq '. | select(.context.route=="login")'

# Inspect failed jobs (if queue integrated)
php artisan queue:failed --queue=auth
```

- **Database Check**: `SELECT email, is_active FROM users WHERE email='user@example.com';`
- **Throttle Reset**: `php artisan cache:forget login|<hash>` (if using cache for rate limiter).

## 4. Common Remediation Steps

- **Rate Limit Lockout**: Clear throttle keys; communicate to affected users.
- **Credential Desync**: Re-run `RegisterAdminAction` via tinker to reset admin password.
- **Session Driver Issues**: Restart Redis, verify connectivity (`redis-cli ping`).
- **APP_KEY Missing**: Regenerate using `php artisan key:generate`; redeploy.

## 5. Escalation Paths

- Security Lead if suspicious access patterns (possible intrusion).
- DevOps Engineer if infrastructure/service mesh issues suspected.
- Product Owner if downtime > 15 minutes or user data compromise.

## 6. Post-Incident Actions

- Document root cause and mitigation in incident tracker.
- Update test coverage for regression (Feature test in `tests/Feature/Auth/`).
- Review monitoring dashboards (`ops/grafana/dashboards/auth-baseline.json`) for anomaly detection improvements.

## 7. Contacts

- On-call rotation: see `docs/governance/roles-and-responsibilities.md`.
- Security hotline: security@elderly-daycare.com (placeholder — update once staffed).
