FROM php:8.2-fpm

# Install system dependencies and PHP extensions (as root)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git curl jq netcat-openbsd ca-certificates \
        build-essential autoconf pkg-config \
        libpng-dev libonig-dev libxml2-dev libzip-dev libpq-dev \
        zip unzip \
    && docker-php-ext-install iconv mbstring pdo_mysql exif pcntl bcmath gd zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

# Copy your static Composer binary and make it executable (as root)
COPY docker/composer /usr/bin/composer
RUN chmod +x /usr/bin/composer

# Workdir and non-root user (before Composer)
WORKDIR /var/www/html
RUN addgroup --system --gid 1000 appgroup \
    && adduser  --system --uid 1000 --ingroup appgroup appuser \
    && mkdir -p /home/appuser \
    && chown -R appuser:appgroup /var/www/html /home/appuser

# Copy application source (artisan included; vendor excluded via .dockerignore)
COPY . .
RUN chown -R appuser:appgroup /var/www/html

# Entrypoint and healthcheck scripts (copy as root, then chmod)
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/app-healthcheck.sh /usr/local/bin/app-healthcheck.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

# Switch to non-root: all Composer and app writes happen under appuser
USER appuser
ENV HOME=/home/appuser \
    COMPOSER_HOME=/home/appuser/.composer

# Copy manifests first (cache-friendly if only app code changes)
COPY composer.json composer.lock ./

# Sanity check: artisan must exist before Composer runs scripts
RUN test -f artisan || (echo "ERROR: artisan file missing in build context" && exit 1)

# Install vendors with scripts enabled (artisan is present) and optimize autoload
# Install vendors and explicitly require predis/predis
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader \
    && composer require predis/predis --no-interaction --no-scripts --no-progress \
    && composer dump-autoload --optimize --no-interaction

# Final runtime
CMD ["php-fpm"]

