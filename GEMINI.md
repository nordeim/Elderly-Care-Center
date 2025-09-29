# AI Agent Context: Elderly Daycare Platform

**Purpose:**
This document is the source of truth for AI agents interacting with this codebase. It provides a concise, factual overview of the project's architecture, key files, and development conventions.

---

## Project Overview

This project is a web application for an **Elderly Daycare Platform**. It allows for booking services, managing clients, and handling related administrative tasks.

The architecture is a standard **Laravel Model-View-Controller (MVC)** pattern with a comprehensive service and action layer. Business logic is encapsulated in single-purpose Action classes (`app/Actions`) or domain-specific Service classes (`app/Services`). The application is designed to run in a Docker containerized environment for development and production consistency.

### Technical Stack

| Component | Technology | Version / Details | Confirmation File |
| :--- | :--- | :--- | :--- |
| Backend Framework | Laravel | `~11.0` | `composer.json` |
| Language | PHP | `8.2` | `Dockerfile` |
| Database | MariaDB | `~10.11` | `docker-compose.yml` |
| Caching & Queues | Redis | `~7.4` | `docker-compose.yml`, `.env.example` |
| Frontend Stack | Blade, TailwindCSS, Alpine.js | Vite build tool | `package.json`, `vite.config.js` |
| Dev Environment | Docker | Docker Compose | `docker-compose.yml` |
| CI/CD | GitHub Actions | PHPUnit Workflows | `.github/workflows/` |

---

## Building and Running the Application

The project uses a Docker-based development environment managed by Docker Compose and a `Makefile` for convenience. The `docker/entrypoint.sh` script automates setup tasks (e.g., migrations, cache building) on container startup.

### 1. First-Time Setup

```sh
# 1. Copy the example environment file
cp .env.example .env

# 2. Generate the Laravel application key
docker-compose run --rm app php artisan key:generate

# 3. Build and start all services in the background
make up
```

### 2. Standard Workflow

The `Makefile` provides shortcuts for most common operations.

```sh
# Start all services (builds if necessary)
make up

# Stop and remove all containers and volumes
make down

# Open a shell inside the application container
make bash

# Run database migrations
make migrate

# Run tests
make test

# View all available commands
make help
```

The application will be available at `http://localhost:8000` and the Mailhog UI at `http://localhost:8025`.

---

## Development Conventions

### Architecture
*   **Adhere to the existing MVC architecture.** Do not introduce other patterns like DDD or Livewire unless explicitly instructed.
*   Place new business logic inside single-purpose **Action classes** (`app/Actions`) or **Service classes** (`app/Services`).
*   Controllers (`app/Http/Controllers`) should be lean and primarily responsible for handling HTTP requests and delegating to Actions or Services.
*   Use Form Requests (e.g., `app/Http/Requests/BookingRequest.php`) for validating incoming request data.

### Core Logic: Booking Flow
The most critical user journey is the booking flow. Understanding it is key to working with the codebase.
1.  **Route:** A `POST` request to `/book` is defined in `routes/web.php`.
2.  **Controller:** The request is handled by `app/Http/Controllers/Site/BookingController.php`.
3.  **Validation:** Data is validated by `app/Http/Requests/BookingRequest.php`.
4.  **Business Logic:** The controller dispatches the validated data to the critical file `app/Actions/Bookings/CreateBookingAction.php`.
5.  **Database:** The Action uses Eloquent models like `Booking` and `BookingSlot` to persist data.

### Testing
*   Tests are located in the `tests/` directory, primarily `tests/Feature/`.
*   The main test for the booking creation process is `tests/Feature/Bookings/CreateBookingTest.php`.
*   Run the entire test suite using `make test` or `docker-compose exec app php artisan test`.

### Key Directories
| Path | Description |
| :--- | :--- |
| `app/Actions/` | Core, single-responsibility business logic classes. |
| `app/Services/` | Domain-specific business logic services (e.g., Payments, Media). |
| `app/Http/Controllers/` | Controllers organized by area (Admin, Site, Payments). |
| `app/Models/` | All Eloquent models. |
| `app/Jobs/` | Queued jobs for asynchronous tasks (e.g., Notifications, Media). |
| `app/Support/Metrics/` | Classes for collecting and analyzing application metrics. |
| `config/` | Contains standard Laravel config and custom configs like `booking.php` and `media.php`. |
| `database/migrations/` | The source of truth for the database schema. |
| `routes/web.php` | Defines all web-facing application routes. |
