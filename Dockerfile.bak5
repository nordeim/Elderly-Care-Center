FROM php:8.2-fpm

# Install system dependencies and PHP extensions (as root)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git curl jq netcat-openbsd ca-certificates \
        build-essential autoconf pkg-config \
        libpng-dev libjpeg-dev libfreetype6-dev \
        libxml2-dev libzip-dev \
        zip unzip \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install iconv mbstring pdo_mysql exif pcntl bcmath gd zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

# Copy Composer and make it executable (as root)
COPY docker/composer /usr/bin/composer
RUN chmod 755 /usr/bin/composer && composer --version || true

# Workdir and non-root user (align PHP-FPM pool later if needed)
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

# Ensure artisan exists if your Composer scripts depend on it (optional gate)
# If scripts require app code, copy app before install; otherwise install vendors first.
# Minimal sanity check kept for your current flow:
RUN test -f artisan || (echo "NOTICE: artisan missing; Composer scripts relying on artisan will be skipped" && true)

# Install vendors (no-dev, optimized). If scripts rely on code, add --no-scripts here and run scripts after copying app.
RUN su -s /bin/sh -c 'composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader' appuser

# Copy application source (vendor excluded via .dockerignore)
COPY --chown=appuser:appgroup . .

# Normalize ownership and deterministic permissions
# - Directories: 775
# - Files: 664
RUN chown -R appuser:appgroup /var/www/html /home/appuser \
    && find /var/www/html /home/appuser -type d -exec chmod 775 {} + \
    && find /var/www/html /home/appuser -type f -exec chmod 664 {} + \
    && chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

# Optionally align FPM pool user/group to appuser to avoid permission mismatches
# RUN sed -ri 's/^user = .*/user = appuser/; s/^group = .*/group = appgroup/' /usr/local/etc/php-fpm.d/www.conf

# Switch to non-root for runtime
USER appuser
ENV HOME=/home/appuser \
    COMPOSER_HOME=/home/appuser/.composer

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]

