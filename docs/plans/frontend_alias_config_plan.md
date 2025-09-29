# Frontend Alias Configuration Plan

## Goal
Satisfy shadcn CLI requirement by defining an import alias that maps `@/*` to the JavaScript resources directory.

## Target Files
- `jsconfig.json` (new)
- `vite.config.js` (already configured with alias) — verify consistency, no change required.

## Planned Changes
- **jsconfig.json**
  - Create configuration with `compilerOptions.paths` mapping `@/*` to `./resources/js/*`.
  - Enable `baseUrl` as `.` to support relative resolution.
  - Include `include` array for `resources/js/**/*` to ensure tooling awareness.
  - Keep minimal since TypeScript not in use; provides IDE and CLI alias support.

## Validation
- [ ] shadcn CLI `npx shadcn@latest init` succeeds after adding config.
- [ ] Vite build continues to resolve alias via existing configuration.
