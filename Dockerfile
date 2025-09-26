FROM php:8.2-fpm

# Install system dependencies and PHP extensions
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

# Copy your static Composer binary into the container
COPY docker/composer /usr/bin/composer
RUN chmod +x /usr/bin/composer

# Create app directory and set permissions
WORKDIR /var/www/html
RUN addgroup --system --gid 1000 appgroup \
    && adduser --system --uid 1000 --ingroup appgroup appuser \
    && chown -R appuser:appgroup /var/www/html

# Copy dependency manifests and install vendors
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader --prefer-dist --no-interaction

# Copy application source (excluding vendor via .dockerignore)
COPY . .

# Switch to non-root user before running composer again
USER appuser

# Optimize autoload (artisan now exists)
RUN composer dump-autoload --optimize --no-interaction

# Entrypoint and healthcheck scripts
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/app-healthcheck.sh /usr/local/bin/app-healthcheck.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/app-healthcheck.sh

USER appuser
CMD ["php-fpm"]

