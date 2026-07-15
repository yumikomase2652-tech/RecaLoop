# RecaLoop maintenance report

Date: 2026-07-15

## Project structure observed

- Current app is a Next.js App Router project, not Vite.
- Supabase browser/server clients are in `lib/supabase/client.ts` and `lib/supabase/server.ts`.
- Main app state, deck screens, study screens, assignments, calendar, and settings currently live mostly in `components/personal-app.tsx`.
- Supabase data access is centralized in `lib/recaloop-data.ts`.
- Local media storage and `.recaloop` package helpers are in `lib/local-media.ts` and `lib/recaloop-package.ts`.

## Changes made

### Login

- Normalized login email with `trim().toLowerCase()`.
- Kept password value unchanged, with a visible warning if leading/trailing spaces are present.
- Added Japanese user-facing Supabase auth error messages.
- Kept developer-facing `console.error` logs for Supabase auth failures.
- Added password show/hide toggle.
- Added Caps Lock warning.
- Added autocomplete attributes for email and password fields.
- Prevented duplicate submits while auth is running.

### Deck loading

- Deck detail opening now skips Supabase re-fetch when the full deck is already cached in memory.
- Added developer `console.info` timing for deck detail load:
  - deck type
  - deck id
  - elapsed ms
  - request count
  - item/card count
  - cache hit/miss

### Study screen

- Added a skip button.
- Skipping does not save rating/check state.
- Skipped cards are moved to the end of the current study queue.
- Skip count is held in the active session and shown as short feedback.

### Hierarchical selection

- Added select all / clear all controls.
- Added selected count display.
- Parent folders can select/deselect all child items.
- Parent checkbox now supports indeterminate state when only part of a subtree is selected.
- Open/closed state remains separate from selected state.

### UI/CSS

- Added styling for password field controls.
- Added styling for study skip action.
- Added styling for selection-tree bulk controls.

## Verification

Commands run successfully:

```bash
npm run lint
npm run build
```

## Notes

- The codebase still has a very large `components/personal-app.tsx`. A safer future refactor would split it by feature after behavior is stabilized:
  - `features/study`
  - `features/decks`
  - `features/assignments`
  - `features/calendar`
  - `components/ui`
- This change intentionally avoided a broad file split because the current task also required behavior fixes and preserving existing data flows.
