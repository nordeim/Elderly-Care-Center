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
