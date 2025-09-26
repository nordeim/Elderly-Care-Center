#!/usr/bin/env bash
set -euo pipefail

log() { printf "[entrypoint] %s\n" "$*"; }

# 1) Env contract sanity checks (minimal required vars)
required_vars=(APP_ENV APP_URL DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_HOST REDIS_PORT)
for v in "${required_vars[@]}"; do
  if [ -z "${!v:-}" ]; then
    log "Missing required env: $v"; exit 12
  fi
done

# 2) Wait for dependencies with bounded retries
wait_for_port() {
  local host="$1" port="$2" name="$3" retries="${4:-40}" sleep_s="${5:-2}"
  for i in $(seq 1 "$retries"); do
    if nc -z "$host" "$port"; then
      log "$name ready at ${host}:${port}"; return 0
    fi
    log "Waiting for $name (${host}:${port})... attempt $i/$retries"; sleep "$sleep_s"
  done
  log "Timeout waiting for $name (${host}:${port})"; return 1
}

wait_for_port "${DB_HOST}" "${DB_PORT}" "mysql"
wait_for_port "${REDIS_HOST}" "${REDIS_PORT}" "redis"

# 3) Laravel bootstrap checks
if [ ! -f ".env" ]; then
  log "No .env found; copying .env.example"; cp .env.example .env || true
fi

# Generate app key if not set
if ! grep -qE '^APP_KEY=.+$' .env; then
  log "Generating APP_KEY"; php artisan key:generate --force
fi

# Ensure storage symlink and directories
log "Ensuring storage symlink"; php artisan storage:link || true
log "Cache warm-up (config/routes/views)"
php artisan config:clear && php artisan config:cache
php artisan route:clear && php artisan route:cache || true
php artisan view:clear || true

# Database connectivity + migrations (idempotent)
log "DB connectivity check"; php -r 'new PDO("mysql:host=".$_ENV["DB_HOST"].";port=".$_ENV["DB_PORT"], $_ENV["DB_USERNAME"], $_ENV["DB_PASSWORD"]);'
log "Running migrations"; php artisan migrate --force

# Redis ping check (via Laravel)
log "Redis ping check"; php -r 'echo (new Predis\Client(["host"=>$_ENV["REDIS_HOST"],"port"=>$_ENV["REDIS_PORT"]]))->ping();' || true

# Expose readiness marker
echo "$(date -Iseconds)" > /tmp/app.ready
log "Startup validation complete"

# Exec original CMD
exec "$@"
