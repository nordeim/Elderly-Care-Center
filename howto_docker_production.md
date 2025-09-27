# Production compose replacement plan

We’ll create a dedicated production stack using Nginx + PHP‑FPM, keep vendors baked into the app image, and avoid bind mounts for code. Healthchecks will gate readiness at both the FPM and HTTP layers. Storage is persisted via a named volume, while configuration is injected via `.env`. This file will be named `docker-compose-production.yml`.

---

## Objectives

- **Topology:** Nginx proxy serving `/public` with upstream to PHP‑FPM (app container).
- **Health:** Separate healthchecks—FPM readiness on the app container, HTTP 200 from Nginx on `/healthz`.
- **Data persistence:** Named volume for `storage/` only; code baked in the image.
- **Security/perf:** Non‑root runtime, Opcache enabled, no dev services (Mailhog optional).
- **Determinism:** Entrypoint gates dependencies and migrations; healthchecks won’t mark healthy until the app is actually serving.

---

## Architecture overview

- **app (PHP‑FPM):** Your built image, runs entrypoint validation and php‑fpm. Exposes port 9000 internally only.
- **nginx:** Official Nginx image configured to serve `public/` and forward PHP requests to `app:9000`. Public port 80 mapped.
- **mysql:** MariaDB with persisted data volume.
- **redis:** Redis for cache/queues.
- **volumes:** `mysql-data`, `app-storage`. No bind mounts of source code.

---

## Key design choices

- **App healthcheck:** Use readiness marker `/tmp/app.ready` to confirm entrypoint completed; do not HTTP-check from the app container.
- **Nginx healthcheck:** Use curl to `http://localhost/healthz` to validate full HTTP path.
- **Start periods:** Generous start periods to allow first-run migrations and cache building.
- **Config files:** Ship a minimal `docker/nginx.conf` with upstream to `app:9000`. Mount it read-only into Nginx.

---

## Compose file: docker-compose-production.yml

```yaml
version: "3.8"

services:
  app:
    image: elderly-daycare-platform-app
    container_name: elderly-app
    restart: unless-stopped
    env_file:
      - .env
    environment:
      # Non-secret defaults; override via .env
      APP_ENV: ${APP_ENV:-production}
      APP_DEBUG: ${APP_DEBUG:-false}
      APP_URL: ${APP_URL:-http://localhost}
      REDIS_HOST: ${REDIS_HOST:-redis}
      REDIS_PORT: ${REDIS_PORT:-6379}
      DB_HOST: ${DB_HOST:-mysql}
      DB_PORT: ${DB_PORT:-3306}
      DB_DATABASE: ${DB_DATABASE:-elderly_daycare}
      DB_USERNAME: ${DB_USERNAME:-elderly}
      DB_PASSWORD: ${DB_PASSWORD:-elderly_secret}
    volumes:
      - app-storage:/var/www/html/storage
    expose:
      - "9000"
    depends_on:
      - mysql
      - redis
    entrypoint: ["/usr/local/bin/entrypoint.sh"]
    command: ["php-fpm"]
    healthcheck:
      test: ["CMD-SHELL", "test -f /tmp/app.ready"]
      interval: 15s
      timeout: 5s
      retries: 8
      start_period: 90s

  nginx:
    image: nginx:1.27-alpine
    container_name: elderly-nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      # Read-only mount of Nginx config and static assets
      - ./docker/nginx.conf:/etc/nginx/nginx.conf:ro
      # Optional: custom mime/types or extra conf.d snippets
      # - ./docker/mime.types:/etc/nginx/mime.types:ro
    depends_on:
      - app
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O /dev/null http://localhost/healthz || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 12
      start_period: 30s

  mysql:
    image: mariadb:10.11
    container_name: elderly-mysql
    restart: unless-stopped
    env_file:
      - .env
    environment:
      MARIADB_ROOT_PASSWORD: ${MARIADB_ROOT_PASSWORD:-root_password}
      MARIADB_DATABASE: ${DB_DATABASE:-elderly_daycare}
      MARIADB_USER: ${DB_USERNAME:-elderly}
      MARIADB_PASSWORD: ${DB_PASSWORD:-elderly_secret}
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
    command: ["mysqld", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci"]
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h localhost -u${MARIADB_USER:-elderly} -p${MARIADB_PASSWORD:-elderly_secret} || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 20
      start_period: 60s

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
      start_period: 30s

# Optional: Mailhog (commented out for production)
#  mailhog:
#    image: mailhog/mailhog:v1.0.1
#    container_name: elderly-mailhog
#    restart: unless-stopped
#    ports:
#      - "8025:8025" # Web UI
#      - "1025:1025" # SMTP
#    healthcheck:
#      test: ["CMD-SHELL", "wget -q -O /dev/null http://localhost:8025 || exit 1"]
#      interval: 10s
#      timeout: 5s
#      retries: 12
#      start_period: 30s

volumes:
  mysql-data:
  app-storage:
```

---

## Nginx config for upstream PHP‑FPM

Place this at `docker/nginx.conf`:

```nginx
worker_processes auto;
events { worker_connections 1024; }

http {
  include       /etc/nginx/mime.types;
  sendfile      on;
  tcp_nopush    on;
  keepalive_timeout 65;
  server_tokens off;

  upstream php_fpm {
    server app:9000;
  }

  server {
    listen 80;
    server_name _;

    root /var/www/html/public;
    index index.php index.html;

    # Simple health endpoint (served by Laravel)
    location = /healthz {
      try_files $uri /index.php?$query_string;
    }

    location / {
      try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
      include fastcgi_params;
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      fastcgi_pass php_fpm;
      fastcgi_read_timeout 60;
    }

    location ~* \.(jpg|jpeg|png|gif|svg|css|js|woff2?|ttf|eot)$ {
      expires 7d;
      access_log off;
      add_header Cache-Control "public";
    }
  }
}
```

Notes:
- **Root path:** Points to `/var/www/html/public` inside the app container’s filesystem.
- **Upstream:** Targets `app:9000` via internal Docker network.
- **Health:** `/healthz` routes through Laravel; ensure your app provides it.

---

## Validation checklist

- **App readiness:** Entrypoint writes `/tmp/app.ready`; app healthcheck passes only after migrations and bootstrap complete.
- **HTTP readiness:** Nginx healthcheck returns 200 for `/healthz`.
- **Storage persistence:** `app-storage` volume contains runtime artifacts (logs, cached views, uploaded files).
- **No bind mounts:** Code changes require rebuild; deterministic runtime and tight permissions.
- **Networking:** Nginx exposes `80`; app exposes `9000` to the network only (via service link), not to host.
- **First-run timing:** MySQL start_period is long enough to avoid false negatives; Nginx waits for app to be ready.

---

## How to use

- **Start production stack:**
  ```
  docker compose -f docker-compose-production.yml up -d --build
  ```
- **Check health:**
  - App: `docker inspect --format='{{json .State.Health}}' elderly-app`
  - Nginx: `curl -I http://localhost/healthz`

---

## Optional enhancements

- **TLS:** Add `443:443` and mount certs; use an `nginx.conf` with TLS server block.
- **Security headers:** Add HSTS, CSP, and other headers in Nginx.
- **Status endpoints:** Configure `php-fpm` `ping`/`status` locations and wire Nginx `location /fpm-status` for deep health.
- **Secrets:** Use Docker secrets or environment management (e.g., AWS SSM) instead of `.env` in production.

If you want, I can add a hardened `php-fpm` pool config and an Nginx TLS server block tailored to your deployment environment.

https://copilot.microsoft.com/shares/CNbAoo2KAYUT4GuNApSKG

---

This log is exactly what you want to see from a hardened Laravel container startup, Jeremiah. Let’s break it down:

---

## ✅ What’s working

- **.env handling**  
  The entrypoint detected no `.env` and safely copied `.env.example`. That’s your fallback logic doing its job.

- **Dependency waits**  
  It patiently retried MySQL until the container was actually listening, then moved on to Redis. This prevents race conditions where migrations would fail because the DB wasn’t ready.

- **Laravel bootstrap**  
  - Storage symlink created (`public/storage` → `storage/app/public`).  
  - Storage directories ensured.  
  - Permissions normalized.  
  - Cache strategy respected: since `APP_ENV` isn’t production, it cleared caches instead of building them.

- **Database connectivity & migrations**  
  - PDO check succeeded.  
  - Migrations ran cleanly, creating all your tables in sequence.  
  - The log shows each migration file executed with timing, confirming idempotent startup.

- **Redis check**  
  Ping returned `1`, confirming connectivity.

- **Readiness marker & healthchecks**  
  After startup validation, `/tmp/app.ready` was written. Your healthcheck script is probing `/healthz` every 15s, and the logs show consistent ~0.17–0.19ms responses. That’s a healthy loop.

- **Application serving**  
  Laravel’s built‑in server is running on `0.0.0.0:8000`, and responding to `/healthz`.

---

## ⚠️ Observations

- **Startup delay**: It took ~14 attempts (~28s) before MySQL was ready. That’s normal for a fresh MariaDB container initializing, but you might want to increase the healthcheck `start_period` for MySQL to avoid false negatives on first boot.

- **Non‑production mode**: The entrypoint correctly detected a non‑production environment and cleared caches. In production, it would build caches instead. That’s exactly the adaptive behavior you designed.

- **Serving model**: Right now you’re using `artisan serve`. That’s fine for dev/test, but for production you’ll want to switch to `php-fpm` behind Nginx. Your Dockerfile is already prepared for that (`CMD ["php-fpm"]`), so it’s just a matter of adjusting your Compose stack.

---

## 🎯 Next refinements

1. **Tune MySQL healthcheck**  
   - Increase `start_period` to 60–90s in `docker-compose.yml` for MySQL.  
   - This avoids the app container waiting so long with repeated retries.

2. **Production stack**  
   - Add an Nginx service in Compose, mount `public/` as docroot, and proxy to the FPM socket.  
   - Switch the app container’s command back to `php-fpm`.  
   - Healthcheck Nginx instead of artisan serve.

3. **Permissions optimization**  
   - Since you already use `COPY --chown`, you can drop the recursive `chown` in your Dockerfile and just run the `find … chmod` normalization. That will shave minutes off build time.

---

## ✅ Bottom line

Your container is **bootstrapping correctly, running migrations, validating dependencies, and serving health endpoints**. The logs show a clean, deterministic startup sequence with no silent failures. You’ve essentially built a production‑grade Laravel container with explicit validation gates.

Would you like me to sketch the **Nginx + FPM production Compose stack** next, so you can see how to evolve this from a dev‑friendly `artisan serve` setup into a true production topology?
