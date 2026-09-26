# Milestone

## Current milestone

Phase 0–4 remediation and verification plus the focused UI/UX alignment pass. Phase 5 has not started.

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

## Build and test status — 2026-09-27

- Xcode 27.0 / Swift 6.4 Debug arm64 build after UI pass: **PASS**.
- Directly compiled `KnowledgeStoreTests` executable: **PASS**.
- Release app launched as a process for five seconds with no startup failure: **PASS**. This does not establish full GUI usability.
- `PRAGMA foreign_key_check` on fresh, migrated, and reopened test databases: **PASS**.
- Git checkpoint: see latest remediation commit.

## Remaining manual verification

1. Open the Release app, visit every sidebar destination, resize the window, switch macOS light/dark appearance, and use keyboard navigation and VoiceOver labels. Confirm no clipped or unreachable controls.
2. In Library, register a real local file, associate it with a record, quit/relaunch, open it, move it, use “Locate file…” to repair the reference, and confirm its metadata and association remain. Repeat with an inaccessible file if available.
3. Search `hyd` and `725 hydrogen H2S`; open a material, claim, and Library result and confirm each correct detail is selected.

These checks are **UNVERIFIED** in this Codex environment. No automated test substitutes for macOS file-panel and visual interaction.

## Known limits

The sample engineering data is illustrative. Search is lexical OR-prefix FTS5 rather than semantic retrieval; it searches document metadata, not document contents. The current record-kind and claim-state filters are broad; specialized material-family, standard-organization, tags, and date fields are not modeled yet. There is no Xcode test target; repository tests compile directly with `swiftc`. No AI, ingestion, graph explorer, or sync exists. The UI was build-verified but full visual comparison, resizing, dark/light appearance, accessibility, and end-to-end GUI workflows remain manual checks.

## Exact next action

Complete the three manual GUI checks above, including visual comparison of Overview, a record detail, Search, and Library against the repository reference images. Start Phase 5 only after separate explicit authorization.
