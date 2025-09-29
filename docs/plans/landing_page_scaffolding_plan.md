# Landing Page Scaffolding Plan

## Scope
Establish new landing page view/controller wiring aligned with `landing_page_implementation_subplan.md` Phase 1.

## Target Files & Intent
- **`routes/web.php`**
  - Route `/` should resolve to dedicated controller method returning redesigned landing page view.
  - Add named route `landing` for future references.
  - Ensure existing `HomeController` binding still accessible or refactored accordingly.

- **`app/Http/Controllers/Site/HomeController.php`**
  - Convert from single-action (`__invoke`) to explicit methods (`index`) if necessary.
  - Provide structured data (services, testimonials, metrics counters) to the view via view model array.
  - Prepare placeholders for future data enhancements (virtual tour CTA, hero stats).

- **`resources/views/pages/landing.blade.php`** *(new)*
  - Scaffold section structure defined in master plan (header placeholder, hero, services, care philosophy, testimonials carousel, CTA, footer placeholder).
  - Use Tailwind utility classes and new animation data attributes (no finalized design yet—structural layout only).
  - Insert `@section('navigation')`, `@section('content')`, and `@section('footer')` to integrate with updated layout.

- **`resources/views/pages/home.blade.php`**
  - Decide whether to repurpose as informational page or remove in favor of `landing`. Initial step: keep but update to extend new layout sections for fallback until final migration.

## Implementation Checklist
- [ ] Update controller signature & data preparation in `app/Http/Controllers/Site/HomeController.php`.
- [ ] Create `resources/views/pages/landing.blade.php` with section scaffolding and descriptive TODO comments.
- [ ] Adjust `routes/web.php` to point `/` to new landing view and rename route to `landing` while preserving old name alias if needed.
- [ ] Ensure tests or placeholders updated to reference new route (add to TODO for later testing phase).

## Validation Plan
- [ ] `php artisan route:list | grep landing` (manual or documented) to verify route registration.
- [ ] Load `/` in browser (manual) to confirm view renders without errors (post-implementation).
- [ ] `php artisan test --filter=Home` after tests added in later phases.
