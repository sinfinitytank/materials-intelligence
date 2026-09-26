# Current State

## Scope and build

Phases 0–4 are implemented in a native SwiftUI macOS 26+ app. The sole Xcode target is `MaterialsIntelligence`; it uses system SQLite/FTS5 and AppKit file panels, with no web runtime, third-party dependency, embeddings, document extraction, or network service. Phase 5 adds an Apple on-device model provider and local RAG pipeline. Xcode 27.0 / Swift 6.4 Release arm64 build and standalone repository tests passed on 2026-09-27. A five-second process launch of the Release app stayed alive without an initialization failure. The presentation layer now includes a reference-led native shell with grouped sidebar navigation, local database status, balanced window sizing, overview metric panels, shared page headers/panel primitives, and a cool neutral canvas/material treatment. Visual navigation, resizing, appearance, and full document open interaction still require human checks.

## Structure and data

- `App`: SwiftUI entry point and local database startup.
- `UI`: `NavigationSplitView`, native record/claim/relationship authoring, Search, Library, local Ask, Settings.
- `Domain`: stable-ID value models for records, claims, relationships, search results, and documents.
- `Database`: SQLite connection, numbered migrations, foreign keys, repository methods, and local FTS5.
- `AI`: existing-FTS retrieval, bounded context, citation validation, and on-device Apple provider.
- `MaterialsIntelligenceTests`: directly compiled repository and RAG regression executables; there is no Xcode test target.

The local file is `Application Support/MaterialsIntelligence/knowledge.sqlite`. Current schema version is 3. A version 1 database upgrades by copying claims and their dependent relationships into replacement tables in one transaction with foreign keys enabled, then advances through the version 3 document/search migration. The upgrade is tested with the original version 1 DDL, source, claim, and a relationship citing that claim, followed by reopening and `foreign_key_check`.

The UI can create/edit records and claims; existing claims can move among Draft, Unverified, Reviewed, Verified, Superseded, and Archived. Claim source and locator remain attached. Relationships can be created with an optional supporting claim and removed with confirmation. Deletion of records or claims that would orphan references is blocked with actionable UI text. Record, claim, and Library removal require confirmation. Archived claims remain stored and are omitted from FTS results.

Search is offline FTS5 over record names/details with directly linked relationship and active-claim context, claims plus subject/source context, and document metadata. Queries split into Unicode letter/number tokens, escape them as quoted FTS5 prefix terms (`"hyd"*`), and join terms with OR. Results rank by SQLite BM25, then title, with type, record-kind, and claim-status filters. The representative `725 hydrogen H2S` query can surface linked standards and sources through that indexed context. Search results open the corresponding record, claim, or Library detail. Logical writes that include FTS or document associations use SQLite savepoints so failed writes roll back together, including relationship changes.

Library stores metadata, associations, original filename, and a base64 security-scoped bookmark. It references the original file without copying or extracting it. Metadata and associations can be edited after registration. Opening resolves the bookmark, starts and stops security-scoped access, checks readability, and asks macOS to open it. A stale bookmark is refreshed when possible. The user can use “Locate file…” to replace a broken reference while preserving the same metadata and associations. A missing or inaccessible file never deletes stored knowledge.

## UI/UX alignment pass

The current native UI follows the repository reference images as closely as the existing Phase 0–4 surface allows: a translucent grouped sidebar, icon-led sections, compact native toolbar actions, a cool neutral canvas, bordered panels with restrained corner radii, rounded typography for major headings, overview metrics, a sketch-style Search bar/filter row, a Library navigator/detail split, and record profile/evidence/relationship panels. Sidebar, overview coverage/quick-action controls, and Materials, Claims, and Library browser rows use explicit clickable native buttons with selected/pressed states. The pass does not implement the future Ask/research-review functionality depicted in concept imagery.

## Verified and unverified

The regression executable covers fresh initialization, exact/prefix/multiple-term search, the `725 hydrogen H2S` query, arbitrary punctuation, reindex on update/delete/archive, foreign keys, claim lifecycle persistence, relationship restriction/removal, document associations, transactional rollback, real bookmark creation/resolution after database reopen, and moved-file metadata retention. Actual GUI file selection, opening through `NSWorkspace`, sandbox permission behavior across a real app restart, stale bookmark refresh, window resizing, dark/light rendering, and keyboard/accessibility use are **UNVERIFIED** pending manual inspection.

The seed data is illustrative and unverified engineering knowledge. Phase 5 code is implemented; real-model and visual GUI verification remain outstanding.

## Exact next action

On an eligible Mac with the on-device Apple model ready, store a genuine Reviewed or Verified Alloy 725 claim with source and locator; ask the representative question offline; inspect the answer, claim/source navigation, and Ask layout. Also run the outstanding Phase 0–4 GUI checks in `MILESTONE.md`.

## Phase 5 verification — 2026-09-27

Debug and Release arm64 app builds, existing `KnowledgeStoreTests`, and deterministic `LocalRAGTests` pass. The RAG tests cover a known fixture answer, no evidence, unverified evidence, claim/source ID mapping, invalid citations, unavailable model handling, context limits, and stored instruction strings. The app launched as a process. On this Mac, `SystemLanguageModel.default.availability` returned `modelNotReady`, so actual local-model generation is **UNVERIFIED**. `screencapture` returned “could not create image from display” and System Events denied assistive access, so Ask visual and interactive inspection is **UNVERIFIED**. A disconnected-network GUI run is **UNVERIFIED**; the implementation contains no network path or cloud fallback. Claim-ID validation does not prove semantic faithfulness of model prose; a reviewer must check the answer against opened claims and sources.

## Phase 6 backend checkpoint — 2026-09-27 (supersedes next action above)

Phase 6 is **INCOMPLETE**. Research schema v1, local parser/validation, persisted staging/audit snapshots, deterministic matching/conflict suggestions, per-item decision/edit/cancel APIs, and atomic approved commits are implemented. Database schema is now **4**. Existing source records/claims/relationships, FTS and RAG remain authoritative. New imported claims are always Unverified. No Research UI exists yet; the backend cannot be exercised through the app.

`Scripts/test.sh` passes all three suites: KnowledgeStore, LocalRAG and ResearchIngestion. A Release app build passes. Synthetic ingestion tests verify rollback, provenance, explicit reuse, rejection, cancellation, search and stored RAG citations after explicit claim review. Actual UI ingestion and on-device answers are **UNVERIFIED**.

Exact next task: implement the native Research import/session/proposal-review/history UI over the existing backend, then perform full real-app acceptance and targeted corrections. See `RESEARCH_INGESTION.md` for the schema, policies, test coverage and remaining cases. The user-requested allowance protection caused a backend checkpoint before starting this major UI unit. Phase 7 is not started and is not ready. Pre-existing UI/documentation edits and Xcode user data remain outside this checkpoint.
