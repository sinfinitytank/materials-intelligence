# Roadmap

Current work: **Phase 8 checkpoint complete; Phase 9 next.**

Platform baseline: macOS 26 or later. The project does not preserve compatibility with earlier macOS releases.

| Phase | Status |
|---|---|
| 0 — Project Foundation | Complete; clean build and process launch verified |
| 1 — Native Mac App Shell | Complete; manual resizing/appearance/accessibility check remains |
| 2 — Engineering Knowledge Model | Complete; schema 1 and schema 3 migration/integrity regressions pass |
| 3 — Knowledge Management | Complete; automated persistence/integrity pass, manual GUI workflow remains |
| 4 — Local Search & Document Library | Complete; automated FTS/bookmark persistence pass, OS file-panel/open check remains |
| 5 — Local AI and RAG | Complete in code; deterministic RAG passes, real on-device generation remains environment-blocked |
| 6 — Research Ingestion | Complete in code; deterministic acceptance coverage passes, full GUI walkthrough remains manual |
| 7 — Knowledge Graph | Implemented; regression/build pass; GUI check UNVERIFIED |
| 8 — Engineering Tools | Degradation workflow implemented; deterministic tests/build pass; GUI/model UNVERIFIED |
| 9–10 | Not started |

Phase 4 provides offline SQLite FTS5 search, record/claim/document result navigation, filters, and a bookmark-referenced local document library. See `CURRENT_STATE.md` and `MILESTONE.md` for verified behavior and remaining manual checks.

Phase 5 uses Apple on-device Foundation Models when available and reuses Phase 4 FTS5. Phase 6 adds versioned packages, persisted staging/audit, native review UI, and atomic reviewed-decision commits without adding network research. See `PHASE_6_CHECKPOINT.md` for the verified boundary and remaining manual checks. The repository is technically ready for Phase 7, and Phase 7 is now implemented following explicit authorization.
