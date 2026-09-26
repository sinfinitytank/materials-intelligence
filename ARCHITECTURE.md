# Architecture

## Phase 0 boundary

The application is a native macOS SwiftUI app. Phase 0 contains only the application entry point and a minimal root view; it has no engineering data, persistence, search, AI, or research functionality.

## Current source structure

- `MaterialsIntelligence/App/`: application and scene entry point.
- `MaterialsIntelligence/UI/`: minimal root view for foundation verification.
- `MaterialsIntelligence.xcodeproj/`: Xcode project and macOS target.

The future boundaries are reserved conceptually for Domain, Database, Search, Intelligence, Research, Documents, and KnowledgeGraph. They will be created only when a phase requires useful implementation.

## Direction

Future phases will keep UI, domain logic, storage, search, and intelligence separate. SQLite/FTS5 and local AI are future architectural concerns, not Phase 0 implementations. Any engineering claim must retain source and verification context when those models are introduced. Shared Swift foundations may later support iPhone/iPad, but Phase 0 creates no mobile target.
