# Combined validation of entrypoint and healthcheck

You’ve built a solid startup gate with explicit env validation, dependency waits, Laravel bootstrap, and a readiness marker. The healthcheck correctly uses both a readiness file and an HTTP probe, which prevents “half-ready” states. Below are precise validations and targeted fixes to harden behavior, avoid subtle failures, and keep signals and timing deterministic.

---

## Key alignment and timing

- **Startup sequence vs healthcheck:** The entrypoint writes the readiness marker after all validations and migrations, then execs the command. The healthcheck requires both the marker and HTTP 200 on port 8000, so the container won’t be marked healthy until the app is listening; that’s correct and avoids false positives.
- **Command model:** In Compose, you run `php artisan serve` (port 8000). The healthcheck probes `localhost:8000/healthz`, which is consistent. If you ever switch to `php-fpm` + Nginx, update the healthcheck accordingly.
- **Start period:** 30s may be tight during cold starts (composer autoload warm-up, migrations). Consider 60–90s to avoid unnecessary healthcheck failures during intensive bootstraps.

---

## Entrypoint review: issues and fixes

- **Bash syntax error in .env fallback:** The snippet uses `} else {`, which is invalid in Bash. Use a standard `if/else/fi` block.
- **Predis detection with php -r:** `class_exists("Predis\\Client")` won’t work unless Composer autoload is loaded. Add `require '/var/www/html/vendor/autoload.php';` before checking for Predis.
- **Permissions logic on bind-mounts:** `chown -R "$(id -u)":"$(id -g)"` may fail on host-owned bind mounts; you already guard with `|| true`. Keep it, but prefer mode fixes via `find` so mount ownership mismatches don’t block startup.
- **Route/view cache failure masking:** In non-prod, `|| true` is fine. In prod, fail-hard to catch syntax issues early—already covered by the prod branch.
- **Redis check exit policy:** Currently soft-fails. In production, consider hard-fail if Redis is a critical dependency.
- **Environment normalization:** `${APP_ENV,,}` relies on Bash; you’re using Bash, so it’s fine. For portability, you could avoid lowercase expansion, but it’s acceptable here.

---

## Healthcheck review: behavior and improvements

- **Readiness gate:** Requiring `/tmp/app.ready` prevents health checks during bootstrap and migrations; good.
- **HTTP path:** `/healthz` assumes the route exists. If not guaranteed, make it configurable via `HEALTHCHECK_URL` env with a default fallback to `/` or `/api/health`.
- **Fallback:** If curl is missing, `nc -z` confirms port is open but not application-level health. Since curl is installed, this fallback is only for contingency; fine.

### Optional improvement
- Allow a configurable URL and tighten error signals:
  ```bash
  # inside app-healthcheck.sh
  URL="${HEALTHCHECK_URL:-http://localhost:8000/healthz}"
  curl -fsS "$URL" >/dev/null || exit 1
  ```
- Consider lengthening `start_period` to tolerate migrations on fresh volumes.

---

## Patch: corrected and hardened entrypoint

Below is a drop-in replacement that fixes syntax, adds Predis autoload, and keeps your operational intent intact. Differences are annotated inline.

```bash
#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

log() { printf "[entrypoint] %s\n" "$*"; }
die() { log "ERROR: $*"; exit 1; }

# --- 1) Env contract sanity checks ---
required_vars=(APP_ENV APP_URL DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_HOST REDIS_PORT)
for v in "${required_vars[@]}"; do
  if [ -z "${!v:-}" ]; then
    die "Missing required env: ${v}"
  fi
done

# Ensure .env presence with strict fallback (fixes invalid Bash else block)
if [ ! -f ".env" ]; then
  if [ -f ".env.example" ]; then
    log "No .env found; copying .env.example -> .env"
    cp .env.example .env
  else
    die "Neither .env nor .env.example found in working directory"
  fi
fi

# --- 2) Dependency gating ---
wait_for_port() {
  local host="$1" port="$2" name="$3" retries="${4:-40}" sleep_s="${5:-2}"
  for i in $(seq 1 "$retries"); do
    if nc -z "$host" "$port"; then
      log "$name ready at ${host}:${port}"; return 0
    fi
    log "Waiting for $name (${host}:${port})... attempt $i/$retries"; sleep "$sleep_s"
  done
  die "Timeout waiting for $name (${host}:${port})"
}

wait_for_port "${DB_HOST}" "${DB_PORT}" "mysql"
wait_for_port "${REDIS_HOST}" "${REDIS_PORT}" "redis"

# --- 3) Laravel bootstrap ---
# Generate APP_KEY if missing (in .env)
if ! grep -qE '^APP_KEY=.+$' .env; then
  log "Generating APP_KEY"
  php artisan key:generate --force
fi

# Storage symlink and directories
log "Ensuring storage symlink"; php artisan storage:link || log "storage:link failed (continuing)"
log "Ensuring storage directories"
mkdir -p \
  storage/app/public \
  storage/framework/cache/data \
  storage/framework/sessions \
  storage/framework/views \
  storage/framework/testing \
  storage/logs \
  bootstrap/cache

# Permissions normalization (bind-mount safe)
log "Normalizing permissions for storage and bootstrap/cache"
chown -R "$(id -u)":"$(id -g)" storage bootstrap/cache || true
find storage bootstrap/cache -type d -exec chmod 775 {} + || true
find storage bootstrap/cache -type f -exec chmod 664 {} + || true

# --- 4) Cache strategy by environment ---
is_prod_like() {
  case "${APP_ENV,,}" in
    prod|production|staging) return 0 ;;
    *) return 1 ;;
  esac
}

if is_prod_like; then
  log "Production-like environment: building caches"
  php artisan config:cache
  php artisan route:cache
  php artisan view:cache
else
  log "Non-production environment: clearing caches"
  php artisan config:clear || true
  php artisan route:clear || true
  php artisan view:clear || true
fi

# --- 5) Database connectivity + migrations ---
log "DB connectivity check via PDO"
php -r '
$dsn = sprintf("mysql:host=%s;port=%s;dbname=%s",
  getenv("DB_HOST"), getenv("DB_PORT"), getenv("DB_DATABASE"));
try {
  $pdo = new PDO($dsn, getenv("DB_USERNAME"), getenv("DB_PASSWORD"));
  $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
  echo "PDO OK\n";
} catch (Throwable $e) {
  fwrite(STDERR, "PDO ERROR: ".$e->getMessage()."\n");
  exit(1);
}
'

run_migrations() {
  local retries="${1:-5}" sleep_s="${2:-3}"
  for i in $(seq 1 "$retries"); do
    if php artisan migrate --force; then
      log "Migrations completed"
      return 0
    fi
    log "Migrations failed (attempt $i/$retries); retrying in ${sleep_s}s"
    sleep "$sleep_s"
  done
  return 1
}

log "Running migrations"
run_migrations || die "Migrations failed after retries"

# --- 6) Redis verification with driver detection (adds autoload for Predis) ---
log "Redis ping check"
php -r '
$host = getenv("REDIS_HOST"); $port = (int)getenv("REDIS_PORT");
if (extension_loaded("redis")) {
  $r = new Redis();
  if (!$r->connect($host, $port)) { fwrite(STDERR, "Redis connect failed\n"); exit(1); }
  echo $r->ping(), "\n"; exit(0);
}
$autoload = "/var/www/html/vendor/autoload.php";
if (file_exists($autoload)) { require $autoload; }
if (class_exists("Predis\\Client")) {
  $c = new Predis\Client(["host"=>$host,"port"=>$port]);
  echo $c->ping(), "\n"; exit(0);
}
fwrite(STDERR, "No redis driver available (phpredis or predis)\n"); exit(0);
' || log "Redis ping failed (continuing)"

# --- 7) Readiness marker ---
date -Iseconds > /tmp/app.ready
log "Startup validation complete"

# --- 8) Exec original CMD with PID 1 semantics ---
exec "$@"
```

---

## Suggested healthcheck enhancement

To make the healthcheck configurable and resilient:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Fail fast if readiness marker missing
test -f /tmp/app.ready || exit 1

URL="${HEALTHCHECK_URL:-http://localhost:8000/healthz}"

if command -v curl >/dev/null 2>&1; then
  curl -fsS "$URL" >/dev/null || exit 1
else
  # Fallback TCP check
  nc -z localhost 8000 || exit 1
fi

exit 0
```

- **Label:** Configurable endpoint via HEALTHCHECK_URL
- **Benefit:** Allows changing the route without rebuilds.

---

## Operational guardrails and validation

- **Entrypoint preflight:** Verify `bash -n docker/entrypoint.sh` passes syntax checks (it will now).
- **Healthcheck dry-run:** `bash -n docker/app-healthcheck.sh` and test `curl` to `/healthz` locally.
- **Start period:** Consider `start_period: 60s` for initial migrations on fresh volumes.
- **Logs:** Expect a clear sequence: env → waits → bootstrap → caches → PDO → migrations → Redis → ready.

If you want, I can wire a minimal `/healthz` route/controller in Laravel that returns 200 and optionally checks DB/Redis based on a query param for deep probes.

https://copilot.microsoft.com/shares/yxaU3GERD9G6TunKyvADs

