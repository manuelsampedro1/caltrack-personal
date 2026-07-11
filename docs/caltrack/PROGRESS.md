# Caltrack Mobile Progress

## Status: Ready for publication

## Completed

- Retrieved and inspected the source post and all three screenshots.
- Built the faithful dashboard and mobile interaction system.
- Replaced the initial server architecture with IndexedDB.
- Added bilingual food parsing, photos, weight, exercise, analysis, CSV, backup, and restore.
- Added installable PWA metadata, app icons, and offline cache.
- Added a GitHub Pages deployment workflow.

## Verification

- iPhone viewport: 390 by 844.
- Configuration and food capture completed in browser automation.
- Data survived a page reload.
- Offline reload succeeded under service worker control.
- Body width matched viewport width, with no horizontal overflow.
- No browser console errors.

## Product decision

User data stays only in the browser. GitHub hosts code and assets, not meals or photos. Full JSON backup is the portability mechanism. Automatic device sync remains out of scope unless a native CloudKit version is later justified.

