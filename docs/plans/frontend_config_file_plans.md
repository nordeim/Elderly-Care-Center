# Frontend Configuration File Plans

Documenting intended structure and content before file creation per instructions.

## `tailwind.config.js`
- **Purpose**: Configure Tailwind JIT with project-specific paths, theme extensions, plugins.
- **Structure Plan**:
  - Export default config via ESM (since `type: module`).
  - `content`: include `./resources/views/**/*.blade.php`, `./resources/js/**/*.js`, `./resources/js/**/*.ts`, `./resources/js/**/*.vue`, `./resources/js/**/*.tsx`, `./vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php` (pagination templates) and `./storage/framework/views/*.php` for compiled Blade safeguards.
  - `theme.extend`:
    - Custom colors from master plan (deep blue, warm accents, greens, neutrals).
    - Font families `playfair` and `inter` referencing CSS variables.
    - Box shadows for cards (`xl-soft`).
    - Keyframes + animation definitions (fade-in-up, marquee scroll).
  - `plugins`: `@tailwindcss/forms`, `@tailwindcss/typography`.
  - `safelist`: classes used dynamically via JS (e.g., `bg-emerald-500`, `text-amber-500`).

## `postcss.config.js`
- **Purpose**: Process Tailwind and autoprefixer during build.
- **Structure Plan**:
  - Export default config object.
  - `plugins`: `tailwindcss`, `autoprefixer`.
  - Include placeholder comment for future plugin additions.

## `vite.config.js`
- **Purpose**: Configure Vite for Laravel integration and asset bundling.
- **Structure Plan**:
  - Import `laravel` plugin from `laravel-vite-plugin` and `defineConfig` from `vite`.
  - Export `defineConfig({ plugins: [...] })`.
  - Configure plugin with input: `resources/css/app.css`, `resources/js/app.js`.
  - Enable refresh for Blade/PHP/JS files.
  - Set resolve alias `@` → `resources/js`.
  - Add server host/port defaults (host: `0.0.0.0`, port `5173`) to support Docker port forwarding.
  - Build options: manifest enabled (default), chunk size warning high threshold.

## `.gitignore` updates
- **Purpose**: Ensure Node artifacts excluded.
- **Structure Plan**:
  - Add entries for `node_modules/`, `public/build/`, `pnpm-lock.yaml`, `yarn.lock`. (preserve existing Laravel entries).

## `resources/css/app.css`
- **Purpose**: Tailwind entrypoint with custom CSS.
- **Structure Plan**:
  - Import Google Fonts via `@import` for `Playfair Display` and `Inter` (with `display=swap`).
  - `@tailwind base;`, `@tailwind components;`, `@tailwind utilities;`.
  - Define CSS variables for fonts (`--font-display`, `--font-sans`).
  - Base styles: set `body` font family, background color, text color.
  - Component layer: custom classes for hero overlay, card transitions, marquee.
  - Utilities: `.animation-delay-*` classes, `.backdrop-blur-sm` fallback.

## `resources/js/app.js`
- **Purpose**: JS entry initializing Alpine, shadcn components, animations.
- **Structure Plan**:
  - Import `./bootstrap` placeholder? (Laravel default) – none currently, so create simple structure.
  - Import `alpinejs` and set `window.Alpine = Alpine; Alpine.start();`.
  - Import icons via `@phosphor-icons/web` for CSS usage (or register components).
  - Import `./lib/animations`; initialize function on DOMContentLoaded.
  - Import carousel setup `import { setupTestimonialsCarousel } from './lib/testimonials';` (future file, to be created later).
  - Export nothing (entrypoint for Vite).

## `resources/js/lib/animations.js`
- **Purpose**: IntersectionObserver to reveal sections.
- **Structure Plan**:
  - Export function `initScrollAnimations()`.
  - Query elements with `[data-animate]`.
  - Check `window.matchMedia('(prefers-reduced-motion: reduce)')` to disable animations.
  - Observer adds classes `opacity-100 translate-y-0` etc.
  - Called from `app.js` on DOMContentLoaded.

## `resources/js/lib/testimonials.js`
- **Purpose**: Manage Embla carousel for testimonials.
- **Structure Plan**:
  - Import Embla: `import EmblaCarousel from 'embla-carousel';`.
  - Export `setupTestimonialsCarousel()` retrieving container by ID.
  - Configure auto-play, pause-on-hover, add keyboard controls.

## `components.json` (shadcn)
- **Purpose**: shadcn CLI configuration.
- **Structure Plan**:
  - JSON with `style: "default"`, `rsc: false`, `tsx: false`, `tailwind.config` path, `components` dir `resources/js/components`.
  - Document path for alias `@/components`.

## `resources/js/components/ui` directory
- **Purpose**: store generated shadcn components (JS/TS).
- **Structure Plan**:
  - CLI-generated files (likely `.tsx`), consider using .jsx or .tsx. Since Laravel uses Vite, we can enable TypeScript.
  - Need to plan TypeScript support (maybe add `typescript` later). For now, plan to configure CLI to output `.ts`/`.tsx` for consumption via Vite.

## README Documentation Updates
- **Purpose**: Onboard devs to new tooling.
- **Structure Plan**:
  - Add new section "Frontend Tooling" with setup instructions: `npm install`, `npm run dev`, mention Node version.
  - Note Docker adjustments once implemented.
