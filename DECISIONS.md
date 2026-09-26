# Architectural Decisions

## 2026-09-27 — Native SwiftUI macOS foundation

Use a native SwiftUI macOS application with a small Xcode project and no third-party dependencies. This follows the project’s local-first Apple direction, keeps the foundation buildable, and avoids committing to web or service infrastructure prematurely.

## 2026-09-27 — Minimal Phase 0 surface

Create only the application entry point and a root view. Future source boundaries are documented but not populated with placeholder classes, preventing Phase 0 from silently implementing later phases.

## 2026-09-27 — Development build signing

The local development target disables code signing so it can be built and verified without a configured Apple development team. This does not change the native app architecture; distribution signing remains outside Phase 0.

## 2026-09-27 — Native Phase 1 application shell

Use `NavigationSplitView`, native `List` selection, SF Symbols, system typography, native toolbar placement, and SwiftUI `ContentUnavailableView` for the first product shell. This keeps navigation predictable and information-dense on macOS without introducing a web runtime, third-party design system, or future-phase backend behavior.

## 2026-09-27 — Phase 2 common record identity

Use one `records` table for the shared identity and small common fields of materials, damage mechanisms, standards, components, and sources. This gives claims and relationships real foreign keys across kinds without five nullable targets or a parallel graph store. Keep specialized attributes out of the first migration until authoring and retrieval requirements justify them. The tradeoff is that Phase 2 does not yet represent detailed chemistry, property, or standard-revision structures.

## 2026-09-27 — Claims, sources, and relationships

Store engineering claims separately from UI prose and future AI output. Every claim references a source record and stores locator, conditions, verification status, evidence level, notes, and timestamps. Relationship edges have stable IDs and can cite a supporting claim. Database foreign keys restrict deletion of referenced data; a trigger checks source kind. Unverified illustrative seed records must not be treated as engineering evidence.

## 2026-09-27 — SQLite versioning and local repository

Use system SQLite through a small Swift repository, with `PRAGMA user_version` and transactional numbered migrations. This keeps the app offline and avoids third-party dependencies. Reject databases newer than the running app. Future migrations must preserve stable IDs and source links and include upgrade tests.
