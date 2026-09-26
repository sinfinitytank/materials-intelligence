# Architectural Decisions

## 2026-09-27 — Native SwiftUI macOS foundation

Use a native SwiftUI macOS application with a small Xcode project and no third-party dependencies. This follows the project’s local-first Apple direction, keeps the foundation buildable, and avoids committing to web or service infrastructure prematurely.

## 2026-09-27 — Minimal Phase 0 surface

Create only the application entry point and a root view. Future source boundaries are documented but not populated with placeholder classes, preventing Phase 0 from silently implementing later phases.

## 2026-09-27 — Development build signing

The local development target disables code signing so it can be built and verified without a configured Apple development team. This does not change the native app architecture; distribution signing remains outside Phase 0.

## 2026-09-27 — Native Phase 1 application shell

Use `NavigationSplitView`, native `List` selection, SF Symbols, system typography, native toolbar placement, and SwiftUI `ContentUnavailableView` for the first product shell. This keeps navigation predictable and information-dense on macOS without introducing a web runtime, third-party design system, or future-phase backend behavior.
