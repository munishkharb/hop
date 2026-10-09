# Changelog

hop is developed privately and published here in releases. Each entry says what changed and why.

## v1.1.2 (2026-10-09)

- CI runs tests and the secret and SAST scans only; commit-message checks stay a local hook.

## v1.1.1 (2026-09-26)

- The picker shows which browsers open a private window while Option is held.
- After opening a private window, the browser comes to the front.
- Settings hide the Velja import when there is nothing to import.
- The README shows the picker and lists its keys.

## v1.1.0 (2026-09-25)

- General settings can set hop as the default browser; the app has its own icon.
- Picker: number keys are handled at the panel before SwiftUI sees them; Option plus a number opens privately; links that match no rule queue instead of replacing the one on screen; the borderless panel takes keyboard focus.
- Rules: path globs use a linear matcher instead of a regex, and a rule whose pattern names no domain is skipped instead of crashing.
- The launcher keeps the private-window flag when the browser is already running.
- Hop.app ships as a .dmg on tagged releases; tests run in CI on every push and pull request; pre-commit runs secret and SAST hooks.
