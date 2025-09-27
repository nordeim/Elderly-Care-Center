# Production-ready Dockerfile replacement plan

Below is a cautious, phased plan to produce a drop-in Dockerfile that is cache-efficient, secure, and aligned with your Compose stack. It uses the “Option 1” strategy: install Composer dependencies without running scripts until app code (including artisan) is present.

---

## Objectives and design decisions

- **Dependencies and extensions:** Install only what’s necessary; compile GD with JPEG/FreeType; include mbstring with oniguruma; enable Redis via PECL; add Opcache for production performance.
- **Cache strategy:** Copy composer manifests first, run `composer install --no-scripts`, then copy source and run artisan-dependent scripts. This keeps vendor caching intact.
- **User and permissions:** Use a non-root `appuser` and normalize file modes deterministically with `find`.
- **Entrypoint alignment:** Keep ENTRYPOINT wired; Compose can override command to `artisan serve` for dev.
- **Composer reliability:** Run Composer as `appuser` with proper HOME/COMPOSER_HOME to avoid “/nonexistent” cache warnings.
- **Operational hygiene:** Minimize layers, clean apt lists, avoid overbroad chmod; explicit modes for scripts and directories.

---

## Build flow plan

1. **Base image and apt packages**
   - **Install:** git, curl, jq, nc, build toolchain, pkg-config, libjpeg/freetype, libpng, libxml2, libzip, libonig, zip/unzip.
   - **Extensions:** Configure GD (`--with-jpeg --with-freetype`), install `mbstring pdo_mysql exif pcntl bcmath gd zip opcache`, install and enable `redis` via PECL.
   - **Cleanup:** Remove apt lists.

2. **Composer and scripts**
   - **Composer binary:** Copy static `composer` to `/usr/bin` and validate version (non-fatal).
   - **Entrypoint/healthcheck:** Copy to `/usr/local/bin`, chmod to 0755.

3. **User and working directory**
   - **Create:** `appuser:appgroup` (uid/gid 1000), home `/home/appuser`.
   - **Workdir:** `/var/www/html`.

4. **Vendor caching**
   - **Copy manifests:** `composer.json` and `composer.lock` with `--chown=appuser:appgroup`.
   - **Set env:** `HOME` and `COMPOSER_HOME` for Composer.
   - **Install vendors:** As `appuser`, `composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts`.

5. **Application source and scripts execution**
   - **Copy app code:** With `--chown=appuser:appgroup`.
   - **Run post scripts:** As `appuser`, run `composer run-script post-autoload-dump` (non-fatal) and `composer dump-autoload --optimize` to ensure optimized autoload.

6. **Permissions normalization**
   - **Ownership:** `chown -R appuser:appgroup /var/www/html /home/appuser`.
   - **Directory modes:** `find ... -type d -exec chmod 775`.
   - **File modes:** `find ... -type f -exec chmod 664`.
   - **Scripts:** Ensure `/usr/local/bin/*` are 0755.

7. **Opcache tuning**
   - **Config file:** Write recommended production Opcache settings into `/usr/local/etc/php/conf.d/opcache-recommended.ini`.

8. **Runtime user and entrypoint**
   - **USER:** `appuser`.
   - **ENV:** Keep `HOME` and `COMPOSER_HOME`.
   - **ENTRYPOINT/CMD:** Entrypoint to your script; default CMD `php-fpm` (Compose may override to `artisan serve`).

---

## Validation checklist

- **Composer scripts:** With `--no-scripts` before app copy, no artisan error occurs; post-autoload runs after app code is present.
- **mbstring:** Oniguruma dev headers included (`libonig-dev`), eliminating configure failures.
- **GD features:** `libjpeg-dev` and `libfreetype6-dev` present; `docker-php-ext-configure gd` uses correct flags.
- **Redis:** PECL `redis` enabled; Predis optional via Composer.
- **Permissions:** Files vs directories have appropriate modes; scripts are executable.
- **Opcache:** Enabled with production-friendly config; improves performance under FPM.
- **Cache efficiency:** Vendor layer only invalidates on manifest changes; app changes don’t reinstall vendors.

---

## Complete drop-in replacement Dockerfile

```Dockerfile
FROM php:8.2-fpm

# Install system dependencies and PHP extensions (as root)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git curl jq netcat-openbsd ca-certificates \
        build-essential autoconf pkg-config \
        libpng-dev libjpeg-dev libfreetype6-dev \
        libxml2-dev libzip-dev libonig-dev \
        zip unzip \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install mbstring pdo_mysql exif pcntl bcmath gd zip opcache \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

# Opcache production settings
RUN set -eux; \
    { \
      echo 'opcache.enable=1'; \
      echo 'opcache.enable_cli=0'; \
      echo 'opcache.memory_consumption=128'; \
      echo 'opcache.interned_strings_buffer=16'; \
      echo 'opcache.max_accelerated_files=10000'; \
      echo 'opcache.validate_timestamps=0'; \
      echo 'opcache.revalidate_freq=0'; \
      echo 'opcache.jit=1255'; \
      echo 'opcache.jit_buffer_size=100M'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Copy Composer and make it executable (as root)
COPY docker/composer /usr/bin/composer
RUN chmod 755 /usr/bin/composer && composer --version || true

# Workdir and non-root user
WORKDIR /var/www/html
RUN addgroup --system --gid 1000 appgroup \
    && adduser  --system --uid 1000 --ingroup appgroup appuser \
    && mkdir -p /home/appuser

# Entrypoint and healthcheck scripts
COPY --chown=root:root docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=root:root docker/app-healthcheck.sh /usr/local/bin/app-healthcheck.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

# Copy Composer manifests first (cache-friendly)
COPY --chown=appuser:appgroup composer.json composer.lock ./

# Set Composer environment and install vendors without scripts (cache preserved)
ENV HOME=/home/appuser \
    COMPOSER_HOME=/home/appuser/.composer
USER appuser
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts

# Copy application source (vendor excluded via .dockerignore)
USER root
COPY --chown=appuser:appgroup . .

# Run artisan-dependent composer scripts now that code is present
USER appuser
RUN composer run-script post-autoload-dump || true \
    && composer dump-autoload --optimize --no-interaction

# Normalize ownership and deterministic permissions
USER root
RUN chown -R appuser:appgroup /var/www/html /home/appuser \
    && find /var/www/html /home/appuser -type d -exec chmod 775 {} + \
    && find /var/www/html /home/appuser -type f -exec chmod 664 {} + \
    && chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

# Switch to non-root for runtime
USER appuser
ENV HOME=/home/appuser \
    COMPOSER_HOME=/home/appuser/.composer

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
```

---

## Notes and optional enhancements

- **Iconv warning:** Dropped `iconv` from `docker-php-ext-install`; it’s built-in on this image and the warning isn’t needed.
- **Intl extension:** If you need internationalization, add `libicu-dev` and `docker-php-ext-install intl`.
- **Production serving:** In production you’ll typically run `php-fpm` behind Nginx. Your Compose currently runs `artisan serve` on port 8000; keep that for dev or adjust Compose for Nginx+FPM in prod.
- **Healthcheck start period:** Consider increasing to 60–90s on first boot to accommodate migrations and cache building.

If you want, I can also provide a production Compose stack (Nginx + FPM) with proper healthchecks and least-privilege mounts.

https://copilot.microsoft.com/shares/JFhzvUiteKquEMWyrqvFt

---

# Build failure diagnosis and fix

Your build is failing while compiling the mbstring extension due to missing Oniguruma development headers. The log shows PHP’s configure step for mbstring requiring oniguruma via pkg-config and aborting when it’s not found. This is because we removed `libonig-dev` earlier; on Debian-based images like `php:8.2-fpm`, mbstring still depends on system oniguruma.

---

## Root cause

- **Missing dependency:** `libonig-dev` (and runtime `libonig5`) are required for `docker-php-ext-install mbstring` on Debian-based PHP images.
- **Symptom in logs:** “Package requirements (oniguruma) were not met” and “Package 'oniguruma' not found.”

---

## Minimal fix

- Add `libonig-dev` back to apt dependencies before running `docker-php-ext-install mbstring`.

---

## Hardened Dockerfile (corrected)

```Dockerfile
FROM php:8.2-fpm

# Install system dependencies and PHP extensions (as root)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git curl jq netcat-openbsd ca-certificates \
        build-essential autoconf pkg-config \
        libpng-dev libjpeg-dev libfreetype6-dev \
        libxml2-dev libzip-dev libonig-dev \
        zip unzip \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install iconv mbstring pdo_mysql exif pcntl bcmath gd zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

# Copy Composer and make it executable (as root)
COPY docker/composer /usr/bin/composer
RUN chmod 755 /usr/bin/composer && composer --version || true

# Workdir and non-root user
WORKDIR /var/www/html
RUN addgroup --system --gid 1000 appgroup \
    && adduser  --system --uid 1000 --ingroup appgroup appuser \
    && mkdir -p /home/appuser

# Entrypoint and healthcheck scripts
COPY --chown=root:root docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=root:root docker/app-healthcheck.sh /usr/local/bin/app-healthcheck.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

# Copy Composer manifests first (cache-friendly)
COPY --chown=appuser:appgroup composer.json composer.lock ./

# Optional: strict artisan presence
# RUN test -f artisan || (echo "ERROR: artisan missing; aborting build" && exit 1)

# Install vendors under appuser
RUN su -s /bin/sh -c 'composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader' appuser

# Copy application source (vendor excluded via .dockerignore)
COPY --chown=appuser:appgroup . .

# Normalize ownership and deterministic permissions
RUN chown -R appuser:appgroup /var/www/html /home/appuser \
    && find /var/www/html /home/appuser -type d -exec chmod 775 {} + \
    && find /var/www/html /home/appuser -type f -exec chmod 664 {} + \
    && chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

# Align PHP-FPM pool to appuser if desired
# RUN sed -ri 's/^user = .*/user = appuser/; s/^group = .*/group = appgroup/' /usr/local/etc/php-fpm.d/www.conf

USER appuser
ENV HOME=/home/appuser \
    COMPOSER_HOME=/home/appuser/.composer

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
```

---

## Notes

- The “iconv is already loaded” warning is benign; iconv is part of core extensions in your image. You can drop `iconv` from `docker-php-ext-install` if desired, but it doesn’t break the build.
- If you later add `intl`, you’ll need `libicu-dev` and `docker-php-ext-install intl`.
- Compose’s `command` uses `artisan serve` on port 8000; ensure healthcheck start period is generous enough (consider 60–90s) when migrations run on first boot.

If you want to keep the image slimmer for production, we can split dev-only tools into a multi-stage build.

https://copilot.microsoft.com/shares/nH3GivREJNB4qzSavgfPf
