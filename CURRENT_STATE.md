# Current State

## Phase 2 status

The project is a native SwiftUI macOS 15+ application built with Xcode 27.0 and Swift 6.4. Phases 0 and 1 were committed as `aac3dfc` and `2b9b72b`. Phase 2 adds the structured local SQLite knowledge model and read-only record pages. No web runtime or third-party dependency exists.

## Structure

- `MaterialsIntelligence/App`: app entry point.
- `MaterialsIntelligence/UI`: Phase 1 shell and read-only Phase 2 record/detail display.
- `MaterialsIntelligence/Domain`: value models for records, claims, and relationships.
- `MaterialsIntelligence/Database`: SQLite connection, versioned schema, repository methods, and illustrative seed.
- `MaterialsIntelligenceTests`: standalone repository test executable source.

SQLite schema version 1 has `records`, `claims`, and `relationships`. Claims reference sources and contain verification status and location. The source record kind is checked by database triggers. Records and relationships have stable IDs and foreign keys. The local file lives at Application Support/MaterialsIntelligence/knowledge.sqlite.

## Verification and limitations

Release arm64 build and repository tests passed. Tests compile directly with `swiftc` and cover initialization, migration version, all record kinds, CRUD, duplicate names, source kind enforcement, relationships, foreign-key deletion protection, seed idempotence, and reopening persistence. Manual visual launch was not performed in this session. The sample links are explicitly unverified and not usable as engineering advice. Specialized material properties, source file management, rich standard revisions, claim review, editing, and search are deferred.

## Next action

Manually inspect the read-only record pages, then explicitly authorize Phase 3 to design and implement knowledge authoring, verification, and connection workflows. Do not start Phase 3 automatically.
