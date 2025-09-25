# Phase C Implementation Plan — Public Content & Booking MVP

## Objectives

- Deliver public-facing discovery pages (`home`, `services`, `staff`, `testimonials`).
- Implement booking flow based on `booking_slots`, `bookings`, `slot_reservations`, `booking_status_history`.
- Provide admin management UI for services, staff, and booking inbox.
- Achieve accessibility and performance baselines per `Project Requirements Document v2.md` §4.

## Workstreams & Tasks

### 1. Public Content Experience
- Build Blade templates for `home`, `services`, `staff`, `testimonials`, `virtual-tour`.
- Integrate dynamic content via controllers (`app/Http/Controllers/Public/*`).
- Apply accessibility styles (`resources/css/accessibility.css`) and skip links.
- Add testimonials & staff sections referencing seeded data.

### 2. Booking Flow Backend
- Create migrations for booking tables consistent with `database_schema_mysql_complete.sql` (`booking_slots`, `slot_reservations`, `bookings`, `booking_status_history`).
- Implement actions & services for booking creation, status updates, and conflict handling (`app/Actions/Bookings/*`).
- Utilize stored procedure logic (`sp_create_booking`) via DB transaction wrappers.
- Provide API endpoints & controllers (`app/Http/Controllers/Public/BookingController.php`, `app/Http/Controllers/Admin/BookingInboxController.php`).

### 3. Admin Management
- Build Livewire or controller-based CRUD for services and staff (`resources/views/admin/services/manage.blade.php`, `resources/views/admin/bookings/index.blade.php`).
- Implement policies and middleware for admin access.
- Add booking status actions (confirm, cancel, waitlist).

### 4. Accessibility & Performance
- Introduce `resources/css/accessibility.css` with WCAG-compliant tokens.
- Run axe automated tests via CI; create manual audit template `docs/accessibility/manual-audit-template.md`.
- Add skip links, focus states, semantic headings.
- Schedule k6 load test scripts stub for booking endpoint (later automation).

### 5. Testing & Validation
- Unit tests for booking actions (`tests/Unit/Bookings/*`).
- Feature tests for public booking flow and admin CRUD (`tests/Feature/Bookings/*`).
- Browser/E2E tests placeholder (`tests/Browser/BookingE2E.php`).
- Populate seeders (`database/seeders/ServicesSeeder.php`, `StaffSeeder.php`, `TestimonialsSeeder.php`).
- Document validation findings `docs/validation/reports/phase-c-accessibility.md`.

## Acceptance Criteria

- Booking flow completes in staging with automated E2E coverage.
- Admin booking inbox with CRUD works and respects RBAC.
- Accessibility: axe CI passes, manual audit documented, skip links and focus states visible.
- Performance target: booking endpoint p95 < 2.5s under k6 load (test script stubbed, manual run planned).
- Validation: 5 moderated sessions (caregiver + elderly) completed and logged.

## Dependencies & Risks

- Requires Phase B authentication and Docker environment to be operational.
- Media pipeline (Phase D) not yet available; ensure media-related UI gracefully handles disabled state.
- Risk: stored procedure usage requires DB compatibility; plan fallback Laravel transaction logic if needed.

## Milestones

- **M1:** Schema migrations & models ready (week 1).
- **M2:** Public pages + booking form functional (week 2).
- **M3:** Admin booking inbox & service/staff management (week 3).
- **M4:** Accessibility + performance validations complete (week 4).
- **M5:** User validation sessions and sign-off (week 5).
