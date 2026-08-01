# angular-prod

A single-project Angular application (Angular 21, standalone components + signals) built with the modern `@angular/build` toolchain.

## Cursor Cloud specific instructions

### Service overview
There is one service: the Angular dev server (frontend SPA). There is no backend or database.

### Commands (see `package.json` scripts)
- Dev server: `npm start` (alias for `ng serve`, serves on `http://localhost:4200`). To reach it from outside the VM, run `npx ng serve --host 0.0.0.0 --port 4200`.
- Lint: `npm run lint` (ESLint via `angular-eslint`).
- Build: `npm run build` (production build to `dist/`).
- Unit tests: `npm test`.

### Non-obvious caveats
- Node version: this repo pins Angular 21, which supports Node `^22.12`. The VM's Node (22.14) works. Do NOT upgrade to Angular 22 — it requires Node `>=22.22.3`, which is newer than the VM runtime and will break installs/builds.
- Tests use the Vitest-based `@angular/build:unit-test` builder (jsdom environment) and run in WATCH mode by default. For a one-shot, non-interactive run use `CI=true npx ng test --watch=false`.
- Angular CLI analytics is already disabled via `"analytics": false` in `angular.json`, so `ng` commands will not block on the first-run analytics prompt. If you ever run the CLI in a context that still prompts, use `npx ng analytics disable`.
