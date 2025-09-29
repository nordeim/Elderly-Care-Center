# Icon Integration Update Plan

## Context
Vite build failed resolving `@phosphor-icons/web` package. To ensure icons remain available without bundler issues, switch to CDN-based stylesheet and remove ESM import.

## Target Files
- `resources/views/layouts/app.blade.php`
- `resources/js/app.js`

## Planned Changes
- **`resources/views/layouts/app.blade.php`**
  - Add `<link>` tag referencing Phosphor Icons CDN stylesheet after font preconnects.
  - Ensure ordering before `@vite` assets for icon classes used across pages.

- **`resources/js/app.js`**
  - Remove `import '@phosphor-icons/web'` statement as icons will load via CDN.
  - No other logic changes required.

## Validation
- [ ] `npm run build` succeeds after updates.
- [ ] Icons using `ph` classes render correctly in browser.
