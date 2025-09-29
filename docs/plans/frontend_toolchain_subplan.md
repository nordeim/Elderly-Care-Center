# Frontend Toolchain Initialization Sub-Plan

## Objective
Establish a modern build toolchain (Vite + Tailwind CSS + shadcn/ui + Alpine.js) integrated with the Laravel app to support the redesigned landing page.

## Milestones & Tasks
- **Milestone A – Node Environment Bootstrap**
  - [ ] Verify Node.js version compatibility (>= 18). *(Command: `node -v`)*
  - [ ] Initialize `package.json` with project metadata. *(File: `package.json`)*
  - [ ] Add npm scripts for `dev`, `build`, `lint` placeholders.

- **Milestone B – Dependency Installation**
  - [ ] Install core packages: `tailwindcss`, `postcss`, `autoprefixer`, `vite`, `laravel-vite-plugin`.
  - [ ] Install UI libraries: `alpinejs`, `@phosphor-icons/vue`, `embla-carousel`.
  - [ ] Install shadcn/ui CLI (`npx shadcn-ui@latest init`).
  - [ ] Document installation commands in `README.md` (developer onboarding section).

- **Milestone C – Configuration Files**
  - [ ] Create `vite.config.js` configured for Laravel (aliases, hot module).
  - [ ] Create `postcss.config.js` with Tailwind + Autoprefixer plugins.
  - [ ] Create `tailwind.config.js` with content paths (`resources/**/*.blade.php`, `resources/js/**/*.js`, `resources/js/**/*.vue`).
  - [ ] Add `.nvmrc` (optional) pinning Node version for developers.

- **Milestone D – Source Scaffolding**
  - [ ] Create `resources/css/app.css` with Tailwind base/components/utilities.
  - [ ] Create `resources/js/app.js` importing `alpinejs`, registering shadcn components, and mounting interactions.
  - [ ] Scaffold `resources/js/lib/animations.ts` (or `.js`) for IntersectionObserver helpers.
  - [ ] Configure shadcn `components.json` (project paths, tailwind config reference).

- **Milestone E – Laravel Integration**
  - [ ] Update `resources/views/layouts/app.blade.php` to use `@vite` assets.
  - [ ] Publish Vite manifest to `public/build` on production build (update deployment docs).
  - [ ] Ensure Docker build step runs `npm ci && npm run build` (update `Dockerfile` or `docker-compose.override.yml`).
  - [ ] Adjust `.gitignore` to include `node_modules/` and `public/build/`.

- **Milestone F – Validation**
  - [ ] Run `npm run dev` and confirm hot reload works.
  - [ ] Execute `npm run build` to verify prod bundle success.
  - [ ] Run Laravel `php artisan test` to ensure no regressions.
  - [ ] Update `docs/plans/frontend_toolchain_subplan.md` status boxes as milestones complete.

## Acceptance Criteria Checklist
- [ ] Asset pipeline produces hashed output in `public/build`.
- [ ] Tailwind JIT recognizes all Blade/JS paths.
- [ ] shadcn components render correctly within Blade when invoked.
- [ ] Alpine interactions available globally via `window.Alpine`.
- [ ] Documentation updated for onboarding & deployment.
