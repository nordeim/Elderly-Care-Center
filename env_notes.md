### Overview

Below are drop-in replacements for both `.env` and `.gitignore`, designed to:
- Prevent secrets from leaking into version control.
- Align with your dev (Compose) and production (Nginx + PHP-FPM) setups.
- Support deterministic startup, health checks, queues, and media delivery.
- Keep configuration explicit and agent-friendly.

---

### Drop-in .env

Use this as your baseline `.env` (local development). For production, override values via environment injection (Compose env file, orchestrator secrets), not by committing a production `.env`.

```env
# =============================================================================
# Application
# =============================================================================
APP_NAME="Elderly Daycare Platform"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000
APP_TIMEZONE=Asia/Singapore
APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_KEY=base64:CHANGE_ME_GENERATE_VIA_php_artisan_key:generate
# If behind a proxy/load balancer in staging/prod, set trusted proxies
TRUSTED_PROXIES=*

# =============================================================================
# Logging
# =============================================================================
LOG_CHANNEL=stack
LOG_LEVEL=debug

# =============================================================================
# Database (local Compose)
# =============================================================================
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=elderly_daycare
DB_USERNAME=elderly
DB_PASSWORD=elderly_secret

# =============================================================================
# Redis (sessions, cache, queues)
# =============================================================================
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=null
REDIS_CLIENT=phpredis

# =============================================================================
# Cache / Session / Queue
# =============================================================================
CACHE_DRIVER=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120
SESSION_SECURE_COOKIE=false
QUEUE_CONNECTION=redis
# HORIZON can replace queue:work in production if desired
# HORIZON_ENABLED=false

# =============================================================================
# Mail (local: Mailhog)
# =============================================================================
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@example.local"
MAIL_FROM_NAME="${APP_NAME}"

# =============================================================================
# Broadcasting (optional)
# =============================================================================
BROADCAST_DRIVER=log

# =============================================================================
# Filesystems (local)
# =============================================================================
FILESYSTEM_DRIVER=local
# For production, consider s3 and set:
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# AWS_DEFAULT_REGION=ap-southeast-1
# AWS_BUCKET=
# AWS_URL=

# =============================================================================
# Metrics / Observability (optional toggles)
# =============================================================================
SENTRY_DSN=
SENTRY_ENVIRONMENT=${APP_ENV}
PROMETHEUS_ENABLED=true

# =============================================================================
# Security headers / CORS (if using Laravel-cors)
# =============================================================================
CORS_ALLOWED_ORIGINS=http://localhost:8000
CORS_ALLOWED_METHODS=GET,POST,PUT,PATCH,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Content-Type,Authorization,X-Requested-With
CORS_EXPOSED_HEADERS=
CORS_MAX_AGE=3600
CORS_SUPPORTS_CREDENTIALS=true

# =============================================================================
# Stripe (Phase F)
# Use test keys locally; never commit real secrets.
# =============================================================================
STRIPE_PUBLIC_KEY=pk_test_CHANGE_ME
STRIPE_SECRET_KEY=sk_test_CHANGE_ME
STRIPE_WEBHOOK_SECRET=whsec_CHANGE_ME

# =============================================================================
# CDN / Asset delivery (Phase F)
# =============================================================================
CDN_ENABLED=false
CDN_BASE_URL=

# =============================================================================
# Calendar / Notifications
# =============================================================================
NOTIFICATIONS_EMAIL_ENABLED=true
NOTIFICATIONS_SMS_ENABLED=false
TIMEZONE_DEFAULT=Asia/Singapore

# =============================================================================
# Health / Ops
# =============================================================================
HEALTH_DB_CHECK=true
HEALTH_REDIS_CHECK=true
```

#### Production overrides (do not commit)
- Set `APP_ENV=production`, `APP_DEBUG=false`, `APP_URL=https://yourdomain`.
- Inject secrets via orchestrator (Compose env file, Swarm/K8s secrets).
- `SESSION_SECURE_COOKIE=true` behind HTTPS.
- `FILESYSTEM_DRIVER=s3` and fill AWS credentials if using object storage.
- `CDN_ENABLED=true` and set `CDN_BASE_URL=https://cdn.yourdomain`.
- Real Stripe keys and webhook secret, managed securely.

---

### Drop-in .gitignore

This `.gitignore` prevents committing secrets and transient artifacts while preserving required Laravel directories.

```gitignore
# =============================================================================
# OS / Editor junk
# =============================================================================
.DS_Store
Thumbs.db
*.swp
*.swo

# =============================================================================
# Environment and secrets
# =============================================================================
.env
.env.*
!.env.example

# =============================================================================
# Dependencies
# =============================================================================
/vendor/
/node_modules/

# =============================================================================
# Laravel cache / logs / debug
# =============================================================================
/bootstrap/cache/*.php
/bootstrap/cache/*.json
/storage/*.sqlite
/storage/debugbar/*
/storage/logs/*
/storage/framework/cache/*
/storage/framework/sessions/*
/storage/framework/testing/*
/storage/framework/views/*

# Keep public/storage symlink if present
/public/storage

# =============================================================================
# Coverage / build artifacts
# =============================================================================
/coverage/
/dist/
/build/
/.yarn/
/.pnp.js
/.nyc_output
/.phpunit.result.cache
/phpunit.xml

# =============================================================================
# Composer / Node lock files (commit these for determinism)
# =============================================================================
# DO NOT ignore composer.lock or package-lock.json
# composer.lock
# package-lock.json
# pnpm-lock.yaml
# yarn.lock

# =============================================================================
# Docker / Compose
# =============================================================================
/docker/*.env
/docker/*.tmp
/docker/*.bak
# Allow committed Compose and Dockerfiles; ignore local overrides
docker-compose.override.yml
docker-compose.local.yml
docker-compose.test.yml

# =============================================================================
# IDE / Project configs
# =============================================================================
.vscode/
.idea/
*.iml

# =============================================================================
# Terraform / Infra state (if present, keep out of VCS unless using remote state)
# =============================================================================
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl
```

---

### Notes and validation

- Generate `APP_KEY` after first boot: run `php artisan key:generate` or rely on entrypoint automation.
- Keep `.env.example` committed with safe placeholders to support onboarding and CI scaffolding.
- RouteServiceProvider’s HTTPS enforcement will honor `APP_URL` scheme; set correctly per environment.
- If you add Horizon, include its config and protect the dashboard behind admin auth.
- Validate startup: `php artisan contract:config` should pass with this `.env`; health endpoint should report 200 with DB/Redis ready.

https://copilot.microsoft.com/shares/x4noVn5g5Hac2n21ZVENC
