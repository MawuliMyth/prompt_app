# Prompt App Architecture

## Goals
- Keep UI and product taxonomy maintainable as the app expands.
- Make backend-managed content editable without shipping a new app build.
- Keep secrets, premium rules, and quota rules on the backend.
- Treat design and architecture documents as implementation constraints.

## Frontend Structure
- `lib/core/`
  - design tokens
  - themes
  - platform helpers
  - reusable shared widgets
- `lib/providers/`
  - UI/session coordination
  - shell navigation state
  - config bootstrap state
  - auth and premium state
- `lib/data/models/`
  - typed backend contracts
  - screen-independent data shapes
- `lib/data/services/`
  - HTTP clients
  - native service wrappers
- `lib/data/repositories/`
  - persistence and remote data orchestration
- `lib/screens/`
  - route-level containers only
- Large route UIs should extract feature widgets instead of keeping monolithic screen files.

## Backend Structure
- `backend/` is the active product backend.
- `functions/` is legacy and must not receive new product logic.
- Server-rendered business rules stay in the backend, not in Flutter.

## Config and Content Rules
- Categories, tones, templates, quick templates, home feature cards, and visual metadata must be backend-driven.
- Flutter may keep a bootstrap fallback only for development resilience, but the backend remains the primary source of truth.
- Use stable IDs, never display names as business identifiers.

## API Rules
- Responses must be typed and explicit.
- Error payloads should preserve server error codes/messages where possible.
- Flutter should distinguish transport failures from backend validation or access failures.
- New config bootstrap endpoint:
  - `GET /api/app-config`

## Security Rules
- Firebase Admin is backend-only.
- Secrets must come from env vars or hosted secret stores.
- Do not log tokens or sensitive credentials.
- Guest usage hashing must use an env-provided salt outside local development.
- Premium access and quota enforcement remain server-owned.

## Navigation Rules
- The app must maintain one persistent shell instance.
- No feature route may push a second shell instance.
- Template/application shortcuts must switch shell state instead of recreating the shell.
- Composer and voice flows are dedicated routes opened from shell state.

## Maintainability Rules
- Every new UX change should map back to `design_document.md`.
- Every new API/model/state change should map back to this document.
- Keep screen state small and feature-specific.
- Prefer typed config models over ad hoc maps.
