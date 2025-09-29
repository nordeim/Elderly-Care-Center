# Landing Page UI Integration Plan

## Objectives
Upgrade landing page sections with shadcn UI components, reusable Blade partials, and animation hooks while maintaining accessibility and performance.

## Component Targets
- **Hero CTA buttons** → adopt shadcn `Button` variants for primary/secondary actions.
- **Program cards** → convert to shadcn `Card` layout with icon support.
- **Testimonials carousel** → implement custom Embla layout enhanced with shadcn `Badge` or `Avatar` if needed.
- **Newsletter form** → replace raw input with shadcn `Input` and `Button`.
- **Navigation/Footer** → evaluate extraction into Blade components for reuse.

## File-Level Plan
- `resources/js/app.js`
  - Import shadcn components registry once generated.
  - Ensure `setupTestimonialsCarousel` integrates with new DOM structure.

- `resources/views/pages/landing.blade.php`
  - Replace CTA buttons with `<x-ui.button>` or blade partial referencing shadcn components.
  - Wrap program cards using shadcn `card` classes for consistent spacing.
  - Adjust testimonial markup to match Embla slider markup expected by JS.
  - Add `data-animate` attributes and utility classes consistent with `initScrollAnimations`.

- `resources/js/components/ui/*`
  - Use shadcn CLI to generate `button`, `card`, `input`, `badge`, and any additional primitives.
  - Configure to export as global components or use inline markup from generated Tailwind classes.

- `resources/views/components/navigation.blade.php` & `resources/views/components/footer.blade.php`
  - (Optional) Extract header/footer markup for reuse across pages.

## Animation Enhancements
- Extend `initScrollAnimations()` to support staggered reveals using `dataset.animationDelay` values.
- Add event listeners for CTA hover states if needed (prefers CSS transitions where possible).

## Validation Checklist
- [ ] shadcn CLI executed and components generated under `resources/js/components/ui`.
- [ ] Landing page renders without missing component classes.
- [ ] Carousel autoplay and dot navigation functional.
- [ ] Animations respect reduced motion preference.
- [ ] Accessibility checks: header landmarks, button labels, form fields.
