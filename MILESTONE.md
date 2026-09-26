# Milestone

## Current milestone

Phase 5 local RAG implementation. Deterministic tests and app build pass; real-model and Ask GUI verification remain.

## Completed

- Preserved the native SwiftUI architecture and Phase 4 Search/Library work.
- Added Ask and Settings to the established sidebar; Ask accurately identifies Phase 5 as future work.
- Repaired version 1 → 2 migration by copying cited claims and dependent relationships before dropping old tables, without disabling foreign keys.
- Added existing-claim editing and all established review states, optional supporting-claim selection, relationship removal, and confirmations for destructive UI actions.
- Corrected FTS5 prefix syntax, safe tokenization, linked standard/source recall, archived-claim indexing, result navigation, and transaction boundaries around logical writes, including relationship changes.
- Added Library metadata/association editing, file relinking, access/readability checks, and stale bookmark refresh while retaining stored knowledge.
- Added migration, FTS, rollback, lifecycle, and real bookmark regression coverage.
- Updated architecture and status documentation to reflect verified behavior and manual limits.
- Completed a presentation-only UI/UX alignment pass in `RootView.swift`: reference-led sidebar hierarchy, native material treatment, balanced window sizing, overview metric/panel composition, page headers, and shared panel primitives. No database, domain, search, bookmark, or engineering-data behavior was changed.
- Completed the full visual GUI follow-up for the implemented Phase 0–4 surfaces: Search search-bar/filter treatment, Library navigator/detail panels, and record profile/evidence/relationship panels with status badges. Concept-only Phase 5 Ask/research-review behavior remains unimplemented.

## Build and test status — 2026-09-27

- Xcode 27.0 / Swift 6.4 Debug arm64 build after UI pass: **PASS**.
- Directly compiled `KnowledgeStoreTests` executable: **PASS**.
- Full visual GUI follow-up Debug arm64 build: **PASS**.
- Release app launched as a process for five seconds with no startup failure: **PASS**. This does not establish full GUI usability.
- `PRAGMA foreign_key_check` on fresh, migrated, and reopened test databases: **PASS**.
- Git checkpoint: see latest remediation commit.

## Remaining manual verification

1. Open the Release app, visit every sidebar destination, resize the window, switch macOS light/dark appearance, and use keyboard navigation and VoiceOver labels. Confirm no clipped or unreachable controls.
2. In Library, register a real local file, associate it with a record, quit/relaunch, open it, move it, use “Locate file…” to repair the reference, and confirm its metadata and association remain. Repeat with an inaccessible file if available.
3. Search `hyd` and `725 hydrogen H2S`; open a material, claim, and Library result and confirm each correct detail is selected.

These checks are **UNVERIFIED** in this Codex environment. No automated test substitutes for macOS file-panel and visual interaction.

## Known limits

The sample engineering data is illustrative. Search is lexical OR-prefix FTS5 rather than semantic retrieval; it searches document metadata, not document contents. The current record-kind and claim-state filters are broad; specialized material-family, standard-organization, tags, and date fields are not modeled yet. There is no Xcode test target; repository tests compile directly with `swiftc`. Local AI/RAG is implemented; no ingestion, graph explorer, or sync exists. The UI was build-verified but full visual comparison, resizing, dark/light appearance, accessibility, and end-to-end GUI workflows remain manual checks.

## Exact next action

Complete the three manual GUI checks above, including visual comparison of Overview, a record detail, Search, and Library against the repository reference images. Finish Phase 5 runtime checks on a Mac with the Apple on-device model available.

## Phase 5 checkpoint — 2026-09-27

- Existing SQLite FTS5 search is the only retrieval path. `LocalRAG` resolves ranked hits to claims, subjects, and sources, gates model context to Reviewed or Verified claims, and bounds context to six claims and 7,000 characters.
- `AppleLocalProvider` uses `SystemLanguageModel.default` on macOS 26+; unavailable devices show a reason. No cloud provider, internet request, document-content extraction, or knowledge-base write was added.
- Ask presents question input, loading/error and unavailable states, generated answer points, source/claim links, and insufficient-evidence findings using native panels.
- Debug and Release arm64 builds and existing repository plus new deterministic RAG tests: **PASS**. App process launch: **PASS**. Actual model response: **UNVERIFIED** (`modelNotReady`). Ask GUI interaction/visual check: **UNVERIFIED** (display capture failed; assistive access denied). Offline-disconnected run: **UNVERIFIED**.
- Next task: on an eligible Mac with the on-device model ready, enter a genuine source-backed Reviewed/Verified Alloy 725 claim, ask the representative question while offline, inspect the answer and open each claim/source record, then make one targeted correction pass.

## Phase 6 safe checkpoint — backend only

**INCOMPLETE.** Schema/parser, persistent staging, deterministic matching, conservative decisions, atomic commit/rollback, provenance and audit backend implemented. Existing store and RAG regressions plus new deterministic ingestion tests pass through `Scripts/test.sh`; Release build passes.

Remaining: native import/review/edit/reuse/commit/cancel/history UI; additional edge-case tests listed in `RESEARCH_INGESTION.md`; actual app import/review/search/Ask workflow and visual correction pass; final architecture acceptance review. No actual-model acceptance is claimed. Exact next task is the Research UI over the tested backend. Allowance protection applies; do not start Phase 7.
