# Landing Page Data Enhancements Plan

## Objectives
Support the redesigned landing page by enriching seed data for services, testimonials, and metrics while preserving existing workflows.

## Target Files
- `database/seeders/ServiceSeeder.php`
- `database/seeders/TestimonialSeeder.php`
- `database/seeders/DatabaseSeeder.php`
- `database/seeders/MediaSeeder.php` (conditional adjustments)
- `database/factories/TestimonialFactory.php` (new)

## Planned Changes
- **ServiceSeeder**
  - Expand service offerings to at least six entries with descriptive copy, durations, and categories used on landing cards.
  - Ensure idempotent `updateOrCreate` usage to avoid duplication.

- **TestimonialSeeder**
  - Introduce diverse testimonials (minimum five) covering caregivers, family members, healthcare partners.
  - Link to clients when available; otherwise store null client.
  - Assign `status='approved'` and optional metadata (e.g., role field if added later).

- **TestimonialFactory (new)**
  - Provide randomized testimonial generation for future tests; include relationships to `Client` factory.

- **MediaSeeder adjustments (optional)**
  - Associate testimonial media assets with new testimonials where applicable (ensure safe checks if assets exist).

- **DatabaseSeeder updates**
  - Confirm seeder order ensures prerequisite data (clients/services/media) exist before testimonials run.

## Validation Checklist
- [ ] `php artisan migrate:fresh --seed` completes without duplication.
- [ ] Landing page receives at least six services and five testimonials from seed data.
- [ ] Any media associations successfully link (no missing file references).
- [ ] Feature tests (to be added later) can rely on seeded data.
