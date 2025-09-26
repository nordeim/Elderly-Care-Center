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
    && chown -R appuser:appgroup /var/www/html

# Entrypoint and healthcheck scripts (copy as root, then chmod)
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/app-healthcheck.sh /usr/local/bin/app-healthcheck.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

# Switch to non-root: all Composer and app writes happen under appuser
USER appuser

# Copy manifests and install vendors inside the container (deterministic)
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader --prefer-dist --no-interaction

# Copy application source (vendor/ excluded via .dockerignore)
COPY . .

# Optimize autoload (artisan now present)
RUN composer dump-autoload --optimize --no-interaction

# Final runtime
CMD ["php-fpm"]

