# hop

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

## License
MIT — see LICENSE.
