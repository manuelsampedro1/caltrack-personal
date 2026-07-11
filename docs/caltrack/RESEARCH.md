# Caltrack Mobile Research

## Overview

Caltrack is a mobile-first calorie and protein tracker inspired by Pieter Levels' July 10, 2026 post. The useful core is durable history, fast food capture, calorie and protein targets, weekly visibility, and deeper observations from accumulated data.

## Updated requirement

The user does not want to operate a VPS. The product must be a web app that is easy to reach from a phone.

## Options considered

1. A server running on the Mac. Simple, but the Mac must stay awake and the phone must usually share its network.
2. A hosted app with accounts and a managed database. It syncs devices, but adds authentication, privacy surface, cost, and third-party dependency.
3. A static installable PWA with IndexedDB. It can be hosted free, works offline, keeps health-adjacent data on the phone, and needs no maintenance.
4. A native iOS app with CloudKit. Best long-term platform fit, but slower to ship than the requested web.

## Recommended approach

Use option 3 now. GitHub Pages hosts only the static application. IndexedDB stores profile, meals, weight, exercise, and photos in the browser. JSON backup and restore provide portability. CSV supports external analysis. A service worker caches the app shell for offline use.

## UX direction

- Preserve the source screenshots' near-black canvas, charcoal cards, green success, coral warning, blue protein, and dense daily rows.
- Make capture the first action.
- Provide first-run setup, visible estimation assumptions, corrections, backup, and installation guidance.
- Respect mobile safe areas, touch targets, and Reduce Motion.

## Risks and mitigations

- Browser data is device-specific. Mitigation: full JSON backup including photos, with an explicit iCloud Drive workflow.
- Safari can remove website data under unusual storage pressure or user cleanup. Mitigation: make backup prominent in settings.
- There is no automatic multi-device sync. This is an intentional privacy and simplicity tradeoff. Native CloudKit is the recommended future path if sync becomes essential.
- Nutrition is approximate. Unknown foods require explicit macros and estimates disclose their assumed quantity.

## References

- [Source post on X](https://x.com/levelsio/status/2075642972243190039)
- Source screenshots inspected at original resolution.
- [Web App Manifest](https://developer.mozilla.org/en-US/docs/Web/Manifest)
- [IndexedDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API)

