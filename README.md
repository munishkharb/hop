# hop

[![CI](https://github.com/munishkharb/hop/actions/workflows/ci.yml/badge.svg)](https://github.com/munishkharb/hop/actions/workflows/ci.yml)

A macOS browser picker. hop catches every link you open and either sends it straight to the right browser by your rules, or shows a fast picker so you choose in one keystroke.

- **Rules** — match a link by domain, path, or the app it came from, and route it to a specific browser, or fall through to the picker.
- **Picker** — a lightweight panel to pick a browser (and remember the choice as a rule).
- **History** — see what opened where.
- **Velja import** — bring your existing rules over.

## Requirements
macOS 13+. Set hop as your default browser in System Settings, and it takes over link handling.

## Build
```
swift build -c release
```
Built with Swift and SwiftUI (SwiftPM executable target; needs Xcode 15+ for the SwiftUI macros).

## Development
Run `pre-commit install` once per clone. On every commit this then runs, against staged files:

- **betterleaks**: secrets scan (redacted output), blocks the commit on a hit. This is the main gate for this repo.
- **opengrep**: SAST against a small pinned rule pack vendored at `.opengrep/rules` (four Swift-specific rules, no registry fetch at commit time; secrets are covered by betterleaks). Opengrep's Swift coverage is thin, so treat it as a secondary check behind betterleaks.
- the standard pre-commit-hooks set: end-of-file-fixer, trailing-whitespace, check-merge-conflict, detect-private-key.

Both scanners run as already-installed binaries (`brew install betterleaks`; opengrep via its install script) rather than something pre-commit builds for you. Run everything on demand with `pre-commit run --all-files`. `main` is protected, so this file lands through a pull request rather than a direct push.

## License
MIT — see LICENSE.
