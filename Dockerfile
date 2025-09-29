FROM php:8.2-fpm

# Install system dependencies and PHP extensions (as root)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git curl jq netcat-openbsd ca-certificates \
        build-essential autoconf pkg-config \
        libpng-dev libjpeg-dev libfreetype6-dev \
        libxml2-dev libzip-dev libonig-dev \
        zip unzip \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
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
    && mkdir -p /home/appuser/.npm \
    && chown -R appuser:appgroup /home/appuser

# Entrypoint and healthcheck scripts
COPY --chown=root:root docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=root:root docker/app-healthcheck.sh /usr/local/bin/app-healthcheck.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

# Copy Composer manifests first (cache-friendly)
COPY --chown=appuser:appgroup composer.json composer.lock package.json package-lock.json ./

# Set Composer environment and install vendors without scripts (cache preserved)
ENV HOME=/home/appuser \
    COMPOSER_HOME=/home/appuser/.composer \
    NPM_CONFIG_CACHE=/home/appuser/.npm
USER appuser
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts \
    && npm ci

# Copy application source (vendor excluded via .dockerignore)
USER root
COPY --chown=appuser:appgroup . .

# Run artisan-dependent composer scripts now that code is present
USER appuser
RUN composer run-script post-autoload-dump || true \
    && composer dump-autoload --optimize --no-interaction \
    && npm run build

# Normalize ownership and deterministic permissions
USER root
RUN rm -rf node_modules /home/appuser/.npm \
    && chown -R appuser:appgroup /var/www/html /home/appuser \
    && find /var/www/html /home/appuser -type d -exec chmod 775 {} + \
    && find /var/www/html /home/appuser -type f -exec chmod 664 {} + \
    && chmod 755 /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

# Switch to non-root for runtime
USER appuser
ENV HOME=/home/appuser \
    COMPOSER_HOME=/home/appuser/.composer

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]

