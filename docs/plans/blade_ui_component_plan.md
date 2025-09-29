# Blade UI Components Plan

## Purpose
Provide Blade wrappers that mirror shadcn/ui button, card, input, and badge primitives for use within Blade templates.

## Target Files
- `resources/views/components/ui/button.blade.php`
- `resources/views/components/ui/card.blade.php`
- `resources/views/components/ui/input.blade.php`
- `resources/views/components/ui/badge.blade.php`

## Button Component
- Accept attributes: `type`, `variant` (default, secondary, outline, ghost, link), `size` (sm, default, lg, icon), `href` (optional for `<a>` render).
- Applied classes should align with `buttonVariants` defined by shadcn (translate Tailwind classes to string lookup in Blade).
- If `href` present → render `<a>`; else `<button>`.

## Card Component
- Structure: outer div with card classes (`relative flex flex-col rounded-3xl bg-white shadow-xl-soft ...`).
- Slots for `header`, `content`, `footer` using Blade `@isset` pattern or fallback to default slot.
- Accept `class` merge.

## Input Component
- Render `<input>` element with Tailwind classes from shadcn `input` style.
- Accept `type`, `name`, `id`, `placeholder`, and merge class attribute.

## Badge Component
- Render `<span>` with Tailwind classes for default badge; support `variant` (default, secondary, outline) to adjust colors.

## Validation Checklist
- [ ] Components support attribute bag merging (`$attributes->merge([...])`).
- [ ] CTA buttons in `landing.blade.php` swap to `<x-ui.button>` or `<x-ui.button href="">`.
- [ ] Program cards wrap content with `<x-ui.card>`.
- [ ] Newsletter form uses `<x-ui.input>` and `<x-ui.button>`.
