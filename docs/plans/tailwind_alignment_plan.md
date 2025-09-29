# Tailwind Alignment Plan

## Objective
Eliminate Vite build warnings by reverting to Tailwind CSS v3 configuration that supports existing custom utilities (`bg-brand-mist`, etc.) while maintaining shadcn components.

## Tasks
- **Dependencies**
  - Pin `tailwindcss` to `^3.4.13`.
  - Remove `@tailwindcss/postcss` (v4-only) and reinstall classic PostCSS plugin usage.
  - Ensure `tailwindcss-animate` is handled as a Tailwind plugin via config.

- **PostCSS Config (`postcss.config.js`)**
  - Restore plugin object form `{ tailwindcss: {}, autoprefixer: {} }` using `tailwindcss` package directly.

- **CSS (`resources/css/app.css`)**
  - Remove Tailwind v4 directives (`@plugin`, `@custom-variant`, `@theme inline`, etc.).
  - Keep existing brand variables and component layers compatible with Tailwind v3.
  - Add explicit CSS variable definitions for shadcn theming if needed (normal `:root` / `.dark`).

- **Tailwind Config (`tailwind.config.js`)**
  - Import and register `tailwindcss-animate` plugin alongside existing plugins.
  - Confirm brand colors/extensions remain intact.

- **Lockfile**
  - Update `package-lock.json` via `npm install` to reflect dependency adjustments.

## Validation
- [ ] `npm run build` completes without unknown utility warnings.
- [ ] Shadcn components render with expected styling post changes.
