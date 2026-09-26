# Current State

## Scope and build

Phases 0–4 are implemented in a native SwiftUI macOS 15+ app. The sole Xcode target is `MaterialsIntelligence`; it uses system SQLite/FTS5 and AppKit file panels, with no web runtime, third-party dependency, AI, embeddings, document extraction, network service, or Phase 5 implementation. Xcode 27.0 / Swift 6.4 Release arm64 build and standalone repository tests passed on 2026-09-27. A five-second process launch of the Release app stayed alive without an initialization failure. Visual navigation, resizing, appearance, and full document open interaction still require human checks.

## Structure and data

- `App`: SwiftUI entry point and local database startup.
- `UI`: `NavigationSplitView`, native record/claim/relationship authoring, Search, Library, Ask placeholder, Settings.
- `Domain`: stable-ID value models for records, claims, relationships, search results, and documents.
- `Database`: SQLite connection, numbered migrations, foreign keys, repository methods, and local FTS5.
- `MaterialsIntelligenceTests`: directly compiled repository regression executable; there is no Xcode test target.

The local file is `Application Support/MaterialsIntelligence/knowledge.sqlite`. Current schema version is 3. A version 1 database upgrades by copying claims and their dependent relationships into replacement tables in one transaction with foreign keys enabled, then advances through the version 3 document/search migration. The upgrade is tested with the original version 1 DDL, source, claim, and a relationship citing that claim, followed by reopening and `foreign_key_check`.

The UI can create/edit records and claims; existing claims can move among Draft, Unverified, Reviewed, Verified, Superseded, and Archived. Claim source and locator remain attached. Relationships can be created with an optional supporting claim and removed with confirmation. Deletion of records or claims that would orphan references is blocked with actionable UI text. Record, claim, and Library removal require confirmation. Archived claims remain stored and are omitted from FTS results.

Search is offline FTS5 over record names/details with directly linked relationship and active-claim context, claims plus subject/source context, and document metadata. Queries split into Unicode letter/number tokens, escape them as quoted FTS5 prefix terms (`"hyd"*`), and join terms with OR. Results rank by SQLite BM25, then title, with type, record-kind, and claim-status filters. The representative `725 hydrogen H2S` query can surface linked standards and sources through that indexed context. Search results open the corresponding record, claim, or Library detail. Logical writes that include FTS or document associations use SQLite savepoints so failed writes roll back together, including relationship changes.

Library stores metadata, associations, original filename, and a base64 security-scoped bookmark. It references the original file without copying or extracting it. Metadata and associations can be edited after registration. Opening resolves the bookmark, starts and stops security-scoped access, checks readability, and asks macOS to open it. A stale bookmark is refreshed when possible. The user can use “Locate file…” to replace a broken reference while preserving the same metadata and associations. A missing or inaccessible file never deletes stored knowledge.

## Verified and unverified

The regression executable covers fresh initialization, exact/prefix/multiple-term search, the `725 hydrogen H2S` query, arbitrary punctuation, reindex on update/delete/archive, foreign keys, claim lifecycle persistence, relationship restriction/removal, document associations, transactional rollback, real bookmark creation/resolution after database reopen, and moved-file metadata retention. Actual GUI file selection, opening through `NSWorkspace`, sandbox permission behavior across a real app restart, stale bookmark refresh, window resizing, dark/light rendering, and keyboard/accessibility use are **UNVERIFIED** pending manual inspection.

The seed data is illustrative and unverified engineering knowledge. Phase 5 remains unstarted.

## Exact next action

Run the short manual GUI checks in `MILESTONE.md`. If they pass, Phases 0–4 have no known implementation defect blocking a separately authorized Phase 5.
