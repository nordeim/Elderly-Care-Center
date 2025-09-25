### Sprint-ready checklist overview

This tight, operationally safe sprint plan hardens Docker/Compose, adds deterministic startup validation, implements healthchecks, and codifies config contracts. It’s built to prevent silent failures, race conditions, and environment drift while keeping iteration fast.

---

### Compose and Dockerfile hardening

#### Updated docker-compose.yml with healthchecks and explicit readiness

```yaml
version: "3.9"

services:
  app:
    build:
      context: ..
      dockerfile: docker/php/Dockerfile
    container_name: elderly-app
    ports:
      - "8000:8000"
    environment:
      APP_ENV: local
      APP_DEBUG: "true"
      APP_URL: http://localhost:8000
      DB_HOST: mysql
      DB_PORT: 3306
      DB_DATABASE: elderly_daycare
      DB_USERNAME: elderly
      DB_PASSWORD: elderly_secret
      REDIS_HOST: redis
      REDIS_PORT: 6379
      MAIL_HOST: mailhog
      MAIL_PORT: 1025
    volumes:
      - ../:/var/www/html
    depends_on:
      - mysql
      - redis
      - mailhog
    entrypoint: ["/usr/local/bin/entrypoint.sh"]
    command: ["bash", "-lc", "php artisan serve --host=0.0.0.0 --port=8000"]
    healthcheck:
      test: [ "CMD-SHELL", "/usr/local/bin/app-healthcheck.sh" ]
      interval: 15s
      timeout: 5s
      retries: 8
      start_period: 30s

  mysql:
    image: mariadb:11.8-noble
    container_name: elderly-mysql
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: root_password
      MARIADB_DATABASE: elderly_daycare
      MARIADB_USER: elderly
      MARIADB_PASSWORD: elderly_secret
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
    command: ["mysqld", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci"]
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h localhost -uroot -proot_password || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 12
      start_period: 20s

  redis:
    image: redis:7.4
    container_name: elderly-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 12
      start_period: 15s

  mailhog:
    image: mailhog/mailhog:v1.0.1
    container_name: elderly-mailhog
    ports:
      - "8025:8025"
    healthcheck:
      test: ["CMD-SHELL", "nc -z localhost 8025"]
      interval: 10s
      timeout: 5s
      retries: 12
      start_period: 15s

volumes:
  mysql-data:
```

#### Hardened Dockerfile with non-root user and preinstalled utilities

```dockerfile
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git curl jq netcat-openbsd ca-certificates \
        libpng-dev libonig-dev libxml2-dev libzip-dev libpq-dev \
        zip unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Create app directory and set permissions
WORKDIR /var/www/html
RUN addgroup --system --gid 1000 appgroup && adduser --system --uid 1000 --ingroup appgroup appuser \
    && chown -R appuser:appgroup /var/www/html

# Copy dependency manifest and install vendors (cached layer)
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader --prefer-dist --no-interaction

# Copy source
COPY . .

# Optimize autoload
RUN composer dump-autoload --optimize --no-interaction

# Entrypoint and healthcheck scripts
COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/php/app-healthcheck.sh /usr/local/bin/app-healthcheck.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

USER appuser
CMD ["php-fpm"]
```

---

### Deterministic startup validation and healthchecks

#### Entrypoint script with explicit readiness gates

Create file: docker/php/entrypoint.sh
```bash
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
```

#### App healthcheck script verifying HTTP and dependencies

Create file: docker/php/app-healthcheck.sh
```bash
#!/usr/bin/env bash
set -euo pipefail

# Fail fast if readiness marker missing
test -f /tmp/app.ready || exit 1

# HTTP health endpoint (fast path)
if command -v curl >/dev/null 2>&1; then
  curl -fsS "http://localhost:8000/healthz" >/dev/null || exit 1
else
  # Fallback TCP check
  nc -z localhost 8000 || exit 1
fi

exit 0
```

---

### Laravel health endpoint and config contract tests

#### Health route and controller

Add route in routes/web.php:
```php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HealthController;

Route::get('/healthz', [HealthController::class, 'check']);
```

Create app/Http/Controllers/HealthController.php:
```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthController extends Controller
{
    public function check(): JsonResponse
    {
        // Basic dependency probes with bounded timeouts
        $dbOk = false; $redisOk = false;
        try { DB::select('SELECT 1'); $dbOk = true; } catch (\Throwable $e) {}
        try { $redisOk = Redis::connection()->ping() === 'PONG'; } catch (\Throwable $e) {}

        $status = ($dbOk && $redisOk) ? 200 : 503;

        return response()->json([
            'status' => $status === 200 ? 'ok' : 'degraded',
            'checks' => [
                'db' => $dbOk ? 'ok' : 'fail',
                'redis' => $redisOk ? 'ok' : 'fail',
                'time' => now()->toIso8601String(),
            ],
        ], $status);
    }
}
```

#### Config contract command (merge-blocking sanity)

Create app/Console/Commands/ConfigContractCheck.php:
```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class ConfigContractCheck extends Command
{
    protected $signature = 'contract:config';
    protected $description = 'Validate required environment variables and configuration contracts';

    public function handle(): int
    {
        $required = [
            'APP_ENV', 'APP_URL',
            'DB_HOST','DB_PORT','DB_DATABASE','DB_USERNAME','DB_PASSWORD',
            'REDIS_HOST','REDIS_PORT',
        ];

        $missing = [];
        foreach ($required as $key) {
            if (empty(env($key))) $missing[] = $key;
        }

        if (!empty($missing)) {
            $this->error('Missing required env vars: '.implode(', ', $missing));
            return self::FAILURE;
        }

        // Simple format checks
        if (!preg_match('#^https?://#', env('APP_URL',''))) {
            $this->error('APP_URL must start with http:// or https://');
            return self::FAILURE;
        }
        if (!ctype_digit((string)env('DB_PORT')) || !ctype_digit((string)env('REDIS_PORT'))) {
            $this->error('DB_PORT and REDIS_PORT must be numeric');
            return self::FAILURE;
        }

        $this->info('Config contract OK');
        return self::SUCCESS;
    }
}
```

Register in app/Console/Kernel.php:
```php
protected $commands = [
    \App\Console\Commands\ConfigContractCheck::class,
];
```

Add a feature test: tests/Feature/ConfigContractCheckTest.php
```php
<?php

use Illuminate\Support\Facades\Artisan;

test('config contract passes with valid env', function () {
    putenv('APP_URL=http://localhost:8000');
    putenv('DB_PORT=3306');
    putenv('REDIS_PORT=6379');

    $exitCode = Artisan::call('contract:config');
    expect($exitCode)->toBe(0);
});
```

---

### CI and operational validation steps

#### Sprint tasks checklist

- **Compose changes applied:** Update docker-compose.yml with healthchecks, entrypoint, and environment normalization.
- **Dockerfile hardened:** Non-root user, utilities installed, entrypoint and healthcheck scripts copied and executable.
- **Entrypoint readiness:** Add entrypoint.sh with env contract checks, dependency waits, Laravel key generation, caches, migrations, and readiness marker.
- **Health endpoint live:** Implement /healthz route and HealthController with DB/Redis probes and 200/503 semantics.
- **Config contract command:** Add contract:config command; include a basic feature test to enforce correctness.
- **CI gates:** 
  - **Build:** docker build app image and run php artisan contract:config.
  - **Unit/Feature tests:** phpunit across app; include ConfigContractCheckTest.
  - **Accessibility smoke (optional this sprint):** axe on landing and booking pages.
- **Makefile helpers (optional):** 
  - **Label:** up
    - docker compose -f docker/docker-compose.yml up -d --build
  - **Label:** logs
    - docker logs -f elderly-app
  - **Label:** check
    - curl -fsS http://localhost:8000/healthz && echo "OK"
- **Operational runbooks:** 
  - **Label:** startup validation
    - Verify elderly-app logs show “Startup validation complete”; confirm /tmp/app.ready exists.
  - **Label:** dependency drills
    - Stop mysql/redis to validate degraded health response (503) and app-healthcheck failure behavior.
  - **Label:** migration integrity
    - Confirm php artisan migrate --force idempotency: re-run without errors; validate schema version table.

#### Local validation sequence

1. **Build and start:** docker compose -f docker/docker-compose.yml up -d --build
2. **Watch readiness:** docker logs -f elderly-app until “Startup validation complete”.
3. **Probe health:** curl -i http://localhost:8000/healthz (expect 200 and db/redis ok).
4. **Contract check:** docker exec elderly-app php artisan contract:config (expect “Config contract OK”).
5. **Degrade test:** docker stop elderly-mysql; curl -i http://localhost:8000/healthz (expect 503); restart mysql and confirm recovery.

---

### Notes and next steps

- **Privilege safety:** Running as appuser prevents accidental root writes on mounted volumes; ensure host file permissions support UID 1000.
- **Migrations control:** If schema evolves during sprint, add a migration lock-time cap and seed data checks to avoid long startup blocking.
- **Queue workers:** If using queues soon, extend healthz to include queue readiness and add a dedicated worker service with its own healthcheck.
- **Compose profiles:** Consider dev/prod profiles separating php-fpm + nginx for production, while keeping artisan serve for local speed.

https://copilot.microsoft.com/shares/c9XojE2CJELTcguhQfqc8
