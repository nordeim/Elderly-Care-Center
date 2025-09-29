# Frontend Integration Plan (Laravel & Deployment)

## Overview
Detailing required changes before modifying Laravel views, ignore rules, and container workflow to support the new Vite/Tailwind toolchain.

## `resources/views/layouts/app.blade.php`
- **Objectives**
  - Replace CDN Tailwind link with Vite-powered assets.
  - Load Google Fonts via `<link rel="preconnect">` tags.
  - Include `@vite(['resources/css/app.css', 'resources/js/app.js'])` within `<head>`.
  - Ensure `<body>` retains accessibility skip link and integrates Alpine-powered mobile nav placeholder.
  - Add `<div id="app">` wrapper if needed for JS-managed components.
- **Planned Changes**
  - Remove existing Tailwind CDN `<link>`.
  - Retain accessibility stylesheet via `{{ asset('css/accessibility.css') }}` but move after `@vite` so Tailwind utilities can be overridden if needed.
  - Add `<link rel="preconnect">` for Google Fonts and `<link rel="stylesheet">` referencing fonts to match `app.css` imports (still keep to support no-JS fallback).
  - Add `<meta name="theme-color">` with brand color and `<meta name="description">` placeholder.
  - Insert `@stack('head')` before closing `</head>`.
  - Wrap main content in `<div id="app">` to give Alpine context.
  - Add placeholder mobile nav button hooking into Alpine (toggle class only, functionality to be fleshed out later).

## `.gitignore`
- **Objectives**
  - Confirm `node_modules/` already ignored (yes).
  - Add `public/build/` output and `.vite/` cache to ignore list.
  - Keep lockfiles tracked per current guidance.

## `Dockerfile`
- **Objectives**
  - Add Node installation or utilize multi-stage build to run `npm ci && npm run build`.
  - Ensure build runs after Composer install but before final copy of public build artifacts.
  - Update permissions to include `node_modules` removal if using multi-stage.
- **Planned Changes**
  - Add NodeSource setup right after base package install: `curl -fsSL https://deb.nodesource.com/setup_20.x | bash -` followed by `apt-get install -y nodejs` within same RUN to minimize layers.
  - After copying composer manifests, run `npm ci --legacy-peer-deps` as `appuser` to install dependencies.
  - After copying full source, run `npm run build` (production build) as `appuser`.
  - Remove `node_modules` and `.npm` caches before final image to reduce size while keeping `public/build` artifacts.
  - Ensure permissions (`chown/chmod`) also cover new `public/build` output.
## `docker-compose.yml`
- **Objectives**
  - Expose Vite dev server (port 5173) for hot reload.
  - Add volume mounts for `node_modules` optional (likely not needed since building inside container).
  - Possibly add command to run `npm run dev` in development service or document manual step.
- **Planned Changes**
  - Map port `5173:5173` on the `app` service.
  - Add environment variable `VITE_HOST=0.0.0.0` if necessary for HMR.
  - Update `depends_on` (if required) to ensure watchers start after initial build.
  - Leave command as `php artisan serve`, but document in README how to run `npm run dev` via `docker-compose exec app npm run dev`.

## `Makefile` (optional)
- **Objectives**
  - Add convenience targets: `npm-install`, `npm-build`, `npm-dev`.
- **Planned Changes**
  - Add phony targets executing `docker-compose exec app npm ...` for containerized workflow.
  - Ensure existing targets unaffected.

## `README.md`
- **Objectives**
  - Align documented stack versions with actual codebase (Laravel 11, PHP 8.2).
  - Update quick start to reflect Docker image now running Composer/NPM install during build.
  - Document new frontend workflow with Vite dev server (port 5173) and commands.
  - Highlight need for Node 18+ only for contributors running tooling locally (optional note).
- **Planned Changes**
  - Update badges/version strings to accurate values.
  - Adjust setup steps: remove manual `composer install`/`npm install` since Docker build handles them, but keep commands for reruns if needed.
  - Add sub-section under "Frontend Development" describing Vite server URL and mention `.env` `VITE_HOST`.
  - Include note about `npm run dev` exposing HMR via port 5173 and corresponding `docker-compose` port mapping.
  - Update project structure section removing non-existent directories (e.g., `Livewire/`).

## Validation Checklist
- [ ] `npm run dev` works, hot reload accessible via http://localhost:5173 when container running.
- [ ] `npm run build` outputs hashed assets into `public/build`.
- [ ] Laravel serves compiled assets via `@vite` without console errors.
- [ ] Docker image builds successfully with new steps.
- [ ] `.gitignore` prevents accidental commits of build artifacts.
