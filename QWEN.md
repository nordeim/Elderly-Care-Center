# AI Agent Context: Elderly Daycare Platform (`CLAUDE.md`)

**Purpose:** This document is the source of truth for AI agents interacting with this codebase. It provides a concise, factual overview of the project's architecture, key files, and development conventions to ensure accurate and consistent code modification.

---

## 1. Technical Vitals

| Attribute | Value | Location / Confirmation |
| :--- | :--- | :--- |
| **Backend Framework** | Laravel 12 | `composer.json` |
| **PHP Version** | 8.4 | `README.md` |
| **Primary Database** | MariaDB | `docker-compose.yml` |
| **Caching / Queues** | Redis | `config/queue.php`, `config/cache.php` |
| **Frontend Stack** | TailwindCSS, Alpine.js (via Blade) | `package.json`, `PAD_condensed.md` |
| **Dev Environment** | Docker | `docker-compose.yml` |
| **CI/CD** | GitHub Actions | `.github/workflows/` |

---

## 2. Architecture Overview

There is a critical divergence between the planned architecture and the current implementation.

### 2.1. Intended Architecture (from Planning Docs)

-   **Pattern:** Domain-Driven Design (DDD) with business logic organized into modules.
-   **Directory Structure:** `app/Domain/{Booking}, app/Domain/{Media}`, etc.
-   **Frontend:** Highly interactive, server-side rendered via **Livewire** components.

### 2.2. Current Implemented Architecture

-   **Pattern:** Standard Laravel Model-View-Controller (MVC).
-   **Directory Structure:** `app/Http/Controllers`, `app/Models`, `app/Services`. The `app/Domain` directory does **not** exist.
-   **Frontend:** Traditional Blade templates. There are **no Livewire** components.

### 2.3. 🔴 Guidance for AI Agent 🔴

**Adhere to the CURRENT (MVC) architecture.**

-   **DO NOT** create Livewire components unless explicitly instructed to begin a migration.
-   **DO NOT** create files in an `app/Domain` structure.
-   Place new business logic inside single-purpose **Action** classes (`app/Actions`) or **Service** classes (`app/Services`).
-   Place new controllers in `app/Http/Controllers`.
-   This ensures consistency with the existing codebase.

---

## 3. Key Directories & Files

| Path | Description |
| :--- | :--- |
| `app/Http/Controllers/Site/` | Public-facing controllers for pages like Home, Services, and the Booking form. |
| `app/Http/Controllers/Admin/` | Controllers for the admin panel (e.g., `BookingInboxController`). |
| `app/Models/` | Contains all Eloquent models. This is the data layer and is well-aligned with the database schema. |
| `app/Actions/` | **Primary location for core business logic.** Contains single-responsibility classes that execute key operations. |
| `app/Actions/Bookings/CreateBookingAction.php` | **CRITICAL FILE:** Contains the primary logic for creating a new booking. |
| `app/Jobs/` | Queued jobs for asynchronous tasks like sending notifications (`SendReminderJob`) and media processing (`TranscodeJob`). |
| `database/migrations/` | Contains all database schema definitions. This is the source of truth for the data structure. |
| `config/booking.php`, `config/media.php` | Custom configuration files for application-specific settings. |
| `tests/Feature/` | **Primary location for tests.** Contains feature tests that validate application workflows. |
| `tests/Feature/Bookings/CreateBookingTest.php` | The main test file for the booking creation process. |

---

## 4. Core Logic Walkthrough: The Booking Flow

This is the most critical user journey. Understanding this flow is key to working with the codebase.

1.  **Route Definition:** A `POST` request to `/booking` is defined in `routes/web.php`.
2.  **Controller Entrypoint:** The request is handled by the `store` method in `app/Http/Controllers/Site/BookingController.php`.
3.  **Validation:** The incoming data is validated by `app/Http/Requests/CreateBookingRequest.php`.
4.  **Core Business Logic:** The controller dispatches the validated data to `app/Actions/Bookings/CreateBookingAction.php`. This Action class contains the logic for checking availability, creating the `Booking` and `BookingSlot` records, and locking capacity.
5.  **Database Interaction:** The Action uses Eloquent models like `Booking.php` and `BookingSlot.php` to persist data.
6.  **Post-Booking Event:** An event is fired to trigger side-effects, such as sending a confirmation email (handled by a queued listener or job).

---

## 5. Development & Verification Commands

All commands must be run via `docker-compose exec app`.

| Command | Description |
| :--- | :--- |
| `php artisan migrate --seed` | **Run this first.** Sets up the database schema and seeds initial data. |
| `php artisan test` | Runs the entire automated test suite (PHPUnit). |
| `php artisan test --filter=CreateBookingTest` | Runs only the tests related to the booking creation feature. |
| `composer install` | Installs PHP dependencies. |
| `npm install` | Installs frontend dependencies. |
| `npm run build` | Compiles frontend assets for production. |

---

## 6. Key Data Structures (Models)

| Model | Table | Purpose |
| :--- | :--- | :--- |
| `User` | `users` | Stores staff and admin accounts. |
| `Client` | `clients` | Stores information about the elderly individuals. |
| `Service` | `services` | Defines the daycare services offered (e.g., "Half-Day Care"). |
| `BookingSlot` | `booking_slots` | Represents an available time slot for a specific service and facility. **This is the core of the availability system.** |
| `Booking` | `bookings` | Represents a confirmed booking made by a client for a specific slot. |
| `MediaItem` | `media_items` | Stores metadata for uploaded photos and videos. |
| `AuditLog` | `audit_logs` | Records significant actions performed by administrators. |
