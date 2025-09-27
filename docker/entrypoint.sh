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
# Generate APP_KEY if missing (in .env) or left as placeholder
if ! grep -qE '^APP_KEY=.+$' .env; then
  log "Generating APP_KEY"
  php artisan key:generate --force
else
  current_key=$(sed -n 's/^APP_KEY=//p' .env | head -n1 | tr -d '\r"')
  if [[ -z "$current_key" || "$current_key" == *CHANGE_ME* ]]; then
    log "APP_KEY placeholder detected; generating new key"
    php artisan key:generate --force
  fi
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

