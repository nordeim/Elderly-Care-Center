# PostCSS Migration Plan

## Reason
Vite build now requires the dedicated Tailwind CSS PostCSS plugin. Update tooling to use `@tailwindcss/postcss` instead of the legacy `tailwindcss` plugin entry.

## Tasks
- **Dependencies**
  - Install `@tailwindcss/postcss` as a dev dependency.
- **`postcss.config.js`**
  - Swap existing plugin configuration to import `@tailwindcss/postcss` (no options required).
- **Validation**
  - Re-run `npm run build` to confirm Tailwind compilation succeeds.
