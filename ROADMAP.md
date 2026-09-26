# Roadmap

Current work: **Phase 5 implementation build and deterministic tests pass; actual on-device model and GUI verification remain.**

| Phase | Status |
|---|---|
| 0 — Project Foundation | Complete; GUI launch appearance check pending |
| 1 — Native Mac App Shell | Complete; manual resizing/appearance/accessibility check pending |
| 2 — Engineering Knowledge Model | Complete; migration and integrity regression verified |
| 3 — Knowledge Management | Complete; manual workflow check pending |
| 4 — Local Search & Document Library | Complete with manual macOS file/open checks pending |
| 5 — Local AI and RAG | Implemented; real-model and GUI acceptance checks remain |
| 6–10 | Planned; none implemented |

Phase 4 provides offline SQLite FTS5 search, record/claim/document result navigation, filters, and a bookmark-referenced local document library. See `CURRENT_STATE.md` and `MILESTONE.md` for verified behavior and remaining manual checks.

Phase 5 uses Apple on-device Foundation Models when available and reuses Phase 4 FTS5. See `ARCHITECTURE.md`, `CURRENT_STATE.md`, and `MILESTONE.md` for the exact verification boundary. Phase 6 has not begun.
