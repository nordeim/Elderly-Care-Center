# Gemini Context: Elderly Daycare Platform

This document provides a comprehensive overview for the Gemini AI agent to effectively understand and assist with the development of this project.

## 1. Project Overview

This is a **Laravel 12** web application designed to serve as a platform for an elderly daycare center. Its primary purpose is to allow families and caregivers to discover services, view facility information, and book visits. The platform is built with a "trust-first" and "accessibility-first" approach.

-   **Backend:** Laravel 12 (PHP 8.4)
-   **Frontend:** TailwindCSS and Alpine.js, rendered via server-side Blade templates.
-   **Database:** MariaDB
-   **Infrastructure:** The entire development environment is containerized using Docker.
-   **Architecture:** The project currently follows a standard **Laravel MVC (Model-View-Controller)** pattern. Business logic is primarily encapsulated in `app/Actions` and `app/Services`.
    -   **Note:** Planning documents specify a more advanced Domain-Driven Design (DDD) and the use of Livewire for interactivity, but this has **not** been implemented. For consistency, all new code should follow the existing MVC pattern.

## 2. Building and Running

The project is managed entirely through Docker. All commands should be prefixed with `docker-compose exec app`.

### Initial Setup

```bash
# 1. Copy environment configuration
cp .env.example .env

# 2. Start Docker containers in the background
docker-compose up -d

# 3. Install PHP and JS dependencies
docker-compose exec app composer install
docker-compose exec app npm install

# 4. Generate an application key
docker-compose exec app php artisan key:generate

# 5. Run database migrations and seeders
docker-compose exec app php artisan migrate --seed

# 6. Build frontend assets
docker-compose exec app npm run build

# The application will be available at http://localhost
```

### Running Tests

```bash
# Run the entire test suite
docker-compose exec app php artisan test

# Run a specific test file (e.g., the booking test)
docker-compose exec app php artisan test --filter=CreateBookingTest
```

### Frontend Development

```bash
# Start the Vite development server with hot-reloading
docker-compose exec app npm run dev
```

## 3. Development Conventions

-   **Business Logic:** Core, single-purpose business logic should be placed in the `app/Actions` directory. Broader service-layer logic can be placed in `app/Services`.
-   **Controllers:** Controllers in `app/Http/Controllers` should remain lean, primarily responsible for handling HTTP requests/responses and delegating to Action or Service classes.
-   **Data Layer:** The data layer is well-defined with Eloquent models in `app/Models` and migrations in `database/migrations`. This is a stable part of the application.
-   **Testing:** Feature tests are the primary method of verification and are located in `tests/Feature`. All new functionality should be accompanied by corresponding feature tests.
-   **Configuration:** Custom application settings are stored in `config/*.php` files, such as `config/booking.php` and `config/media.php`.
-   **Consistency:** Adhere strictly to the existing MVC pattern for any new features or bug fixes to maintain architectural consistency.
