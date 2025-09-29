# Landing Page Implementation Sub-Plan

## Overview
This sub-plan operationalizes the master makeover design into actionable development phases. Each task includes target files, change description, and validation checklist.

## Phase 1 – Information Architecture & Routing
- **Task 1**: Create dedicated Blade view for landing page.
  - **Files**: `resources/views/pages/landing.blade.php`, `routes/web.php`.
  - **Changes**: New Blade template implementing finalized section structure; map `/` to new controller or closure returning the view.
  - **Validation**: [ ] Route responds 200 in browser; [ ] Blade extends layout with `@vite` assets; [ ] Basic accessibility landmarks present.
- **Task 2**: Introduce controller method for home page.
  - **Files**: `app/Http/Controllers/Site/HomeController.php` (new), `routes/web.php`.
  - **Changes**: Controller returning view with data placeholders (services, testimonials, metrics).
  - **Validation**: [ ] Controller registered with route name; [ ] Feature test seeds data and asserts view contains CTA text.

## Phase 2 – Data Wiring & Content
- **Task 3**: Seed testimonial and program highlight data.
  - **Files**: `database/seeders/DatabaseSeeder.php`, `database/seeders/TestimonialSeeder.php` (new), `app/Models/Testimonial.php` (new).
  - **Changes**: Model + migration if needed, seeder populating testimonial content for carousel; optional `ServiceHighlight` data structure.
  - **Validation**: [ ] `php artisan migrate --seed` completes; [ ] Blade loops render seeded data.
- **Task 4**: Add metrics support for hero counters.
  - **Files**: `app/Support/Metrics/BookingMetrics.php` (augment), `app/Services/Analytics/EngagementService.php` (new maybe), Blade view.
  - **Changes**: Provide aggregated counts for `years_of_service`, `families_served`, etc.
  - **Validation**: [ ] Unit/feature test verifying metric values; [ ] Blade displays numbers with animation fallback.

## Phase 3 – Visual Components & Animation
- **Task 5**: Implement shadcn UI components.
  - **Files**: `resources/js/components/ui/*`, `resources/views/pages/landing.blade.php`.
  - **Changes**: Add `Card`, `Carousel`, `Button`, `Input`, `Steps`, `Badge` components via shadcn CLI; integrate with Blade via `@vite` and Alpine wrappers.
  - **Validation**: [ ] Components compile without Tailwind purge issues; [ ] Buttons show hover animation; [ ] Carousel auto-scroll works and pauses on hover.
- **Task 6**: Build intersection animations and reduced motion.
  - **Files**: `resources/js/lib/animations.ts`, `resources/js/app.js`, Blade data attributes.
  - **Changes**: IntersectionObserver to add `opacity-100 translate-y-0` classes; respect `prefers-reduced-motion`.
  - **Validation**: [ ] Animations trigger on scroll; [ ] Reduced motion disables transitions; [ ] No console errors.

## Phase 4 – Media & Asset Integration
- **Task 7**: Integrate hero video and fallback.
  - **Files**: `public/media/hero.mp4`, `public/media/hero.webm`, Blade hero section.
  - **Changes**: Add `<video>` with overlay, fallback image, alt text; lazy load via `loading="lazy"` for images.
  - **Validation**: [ ] Video autoplays muted loop; [ ] Fallback image on Safari iOS; [ ] Lighthouse performance remains > 90.
- **Task 8**: Add iconography and imagery assets.
  - **Files**: `public/images/*`, `resources/views/pages/landing.blade.php`.
  - **Changes**: Include icon components for services, badges for CTA; ensure file naming consistent.
  - **Validation**: [ ] Asset paths resolve; [ ] Alt text descriptive; [ ] No layout shift metrics degrade.

## Phase 5 – Footer & Global Enhancements
- **Task 9**: Implement footer newsletter form & social proof.
  - **Files**: `resources/views/pages/landing.blade.php`, possible `app/Http/Controllers/Site/NewsletterController.php` (new).
  - **Changes**: Add shadcn `Input` + `Button` for subscription, logos row, contact info.
  - **Validation**: [ ] Form submits to stub endpoint (returns success toast); [ ] Logos grayscale to color on hover; [ ] Links keyboard accessible.
- **Task 10**: Update layout and partials.
  - **Files**: `resources/views/layouts/app.blade.php`, `resources/views/components/navigation.blade.php` (new), `resources/views/components/footer.blade.php` (new).
  - **Changes**: Extract header/footer into reusable components; include `@vite` macros and script deference.
  - **Validation**: [ ] Components render across site; [ ] Header sticky with smooth blur; [ ] Mobile menu toggles via Alpine.

## Phase 6 – Quality Assurance
- **Task 11**: Automated testing.
  - **Files**: `tests/Feature/HomePageTest.php` (new), `tests/Browser/HomePageDuskTest.php` (future optional).
  - **Changes**: Feature tests verifying sections presence; optional Dusk test for carousel functionality.
  - **Validation**: [ ] `php artisan test` passes; [ ] Dusk suite optional.
- **Task 12**: Documentation & handoff.
  - **Files**: `README.md`, `docs/plans/landing_page_implementation_subplan.md` (this file), `docs/accessibility/landing-page-audit.md` (new).
  - **Changes**: Update instructions to run frontend tooling, record accessibility audit results, mark checkboxes as complete.
  - **Validation**: [ ] Documentation reviewed; [ ] Stakeholder sign-off recorded.

## Implementation Checklist Summary
- [ ] Routing & controller ready.
- [ ] Dynamic content sources available.
- [ ] UI components integrated with animation logic.
- [ ] Media assets optimized.
- [ ] Footer & global elements polished.
- [ ] Tests and docs updated.
