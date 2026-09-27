# Milestone

## Current milestone

Post-Phase-6 verification and consolidation is complete. Phase 7 has not started.

## Completed

- Audited the roadmap acceptance criteria and implementation for Phases 0–6.
- Preserved the native SwiftUI, single-SQLite-store, deterministic FTS, and guarded local-RAG architecture.
- Verified schema/package validation, staging, matching, review decisions, editing, reuse, cancellation, history, provenance, and atomic commit/rollback.
- Verified imported knowledge enters the existing records/claims/relationships tables, is indexed by the existing FTS path, and is retrieved by the existing Phase 5 RAG path after explicit claim review.
- Restored Phase 3 material add/edit/delete behavior in the specialized Materials screen and removed the inert workspace placeholder.
- Removed duplicate display of sources across Research Entities and Sources.
- Added direct Phase 5 schema 3 → Phase 6 schema 4 migration coverage.
- Added regression coverage proving malformed imports and invalid edits cannot alter staging or permanent knowledge.
- Consolidated permanent documentation through Phase 6.

## Build and test status — 2026-09-27

- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./Scripts/test.sh`: **PASS**.
- KnowledgeStore deterministic suite: **PASS**.
- LocalRAG deterministic suite: **PASS**.
- ResearchIngestion deterministic suite: **PASS**.
- Clean Release arm64 build using a fresh derived-data directory: **PASS**.
- Five-second launch/liveness check of that clean Release product: **PASS**.
- Fresh/reopened/migrated database foreign-key checks: **PASS**.
- `git diff --check`: **PASS**.

## Defects fixed

1. The custom Materials profile had replaced working Phase 3 CRUD controls with no-op buttons. Add/edit/delete and guarded-delete feedback are restored using the existing editor and repository behavior.
2. Source proposals appeared in both the Entities and Sources Research sections. Entities now shows non-source entities; Sources owns source proposals.
3. Phase 5 → 6 direct migration and invalid import/edit non-mutation behavior lacked explicit regression coverage. Focused tests now protect both paths.
4. Permanent documentation contained contradictory Phase 5/schema-3/Phase-6-incomplete statements. It now describes schema 4 and the implemented verification boundary.

## Known issues and technical debt

- No Xcode test target; deterministic suites are compiled by `Scripts/test.sh`.
- `KnowledgeStore` is a compact synchronous repository and rebuilds the complete FTS index after each logical write. This is simple and safe for the current local dataset but may become a performance limit at larger scale.
- Research history is snapshot-based rather than an event log.
- Deterministic matching is lexical and conservative; semantic equivalence, numeric contradiction analysis, and near-title source matching are not implemented.
- Boundary classification is retained as provenance but is not row-level access control.
- Full visual/accessibility/file-panel verification and real Foundation Models generation remain manual/environment-dependent.

## Manual verification still required

1. Import `Fixtures/alloy-725-research.json` through the file picker; inspect matches; accept, reject, edit, reset, and reuse proposals; test cancellation and commit confirmation; reopen the app and inspect history/result mappings.
2. Open committed records in Search and Claims, promote a genuinely checked source-backed claim to Reviewed or Verified, and ask a relevant question on an eligible Mac. Open every citation.
3. Exercise Library add/open/move/relink across restart.
4. Visit every destination at multiple window sizes in light/dark appearance and check keyboard navigation and VoiceOver labels.

## Phase 7 readiness

**Technically ready, with manual acceptance caveats.** No automated blocker, integrity defect, migration defect, or Phase 5/6 integration defect remains known. The manual checks above should be completed before relying on the app for engineering work, but they do not require a Phase 0–6 architectural change. Do not start Phase 7 until explicitly requested.
