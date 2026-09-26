# Current State

## Phase 3 status

The project is a native SwiftUI macOS 15+ application built with Xcode 27.0 and Swift 6.4. Phase 3 adds native create/edit workflows, source-linked claims, review states, relationship editing, guarded deletion, and persistence. No web runtime or third-party dependency exists.

## Structure

- `MaterialsIntelligence/App`: app entry point.
- `MaterialsIntelligence/UI`: Native authoring pages for records, claims, and relationships.
- `MaterialsIntelligence/Domain`: value models for records, claims, and relationships.
- `MaterialsIntelligence/Database`: SQLite connection, versioned schema, repository methods, and illustrative seed.
- `MaterialsIntelligenceTests`: standalone repository test executable source.

SQLite schema version 2 has `records`, `claims`, and `relationships`. Claims reference sources and contain lifecycle status and location. The source record kind is checked by database triggers. Records and relationships have stable IDs and foreign keys. The local file lives at Application Support/MaterialsIntelligence/knowledge.sqlite.

## Verification and limitations

Release arm64 build and repository tests passed. Tests compile directly with `swiftc` and cover initialization, schema version, all record kinds, CRUD, duplicate names, source kind enforcement, relationships, foreign-key deletion protection, seed idempotence, and reopening persistence. Claims use Draft, Unverified, Reviewed, Verified, Superseded, or Archived states. Records cannot be deleted while referenced. Manual visual launch remains recommended. The sample links are explicitly unverified and not usable as engineering advice. Rich specialized attributes, source files, search, AI, ingestion, graph visualization, and sync remain deferred.

## Next action

Manually exercise authoring, claim review, relationship editing, guarded deletion, and quit/relaunch persistence. Do not start Phase 4 until that review is complete.
