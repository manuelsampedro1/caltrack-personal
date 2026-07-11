# Caltrack Mobile Implementation

## Objective

Deliver an installable phone-first web app with no server-side runtime and no user-maintained infrastructure.

## Phase 1: On-device data

- [x] IndexedDB stores profile, food, weight, exercise, and photos.
- [x] Bilingual food parser runs in the browser.
- [x] Daily, weekly, and 14-day calculations run locally.
- [x] Reload preserves all data.

## Phase 2: Mobile product

- [x] Faithful responsive dashboard.
- [x] First-run setup and fast capture.
- [x] Photos, weight, exercise, correction, and CSV.
- [x] Full JSON backup and restore.

## Phase 3: Installation and hosting

- [x] Web app manifest and 512 px icon.
- [x] Apple touch icon.
- [x] Service worker and offline shell.
- [x] GitHub Pages deployment workflow.

## Success criteria

- No VPS, token, account, or backend is required.
- A fresh iPhone-sized browser can configure a plan and log food.
- Data survives a full reload.
- The app opens offline after its first visit.
- No horizontal overflow or browser console errors.

