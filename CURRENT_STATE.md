# Current State — 2026-09-27

## Implemented scope

Phases 0–10 now have native implementations: macOS 26+ workstation plus a universal iPhone/iPad iOS 26+ target. One shared domain and SQLite repository remain the foundation; no web runtime or third-party dependency was added.

- Phases 0–4: native authoring, records/claims/relationships, guarded deletion, source provenance, FTS and bookmark-referenced Library.
- Phase 5: bounded local RAG, Reviewed/Verified evidence gate, exact citation-ID validation, Apple on-device provider and honest unavailable state.
- Phase 6: schema-v1 research packages, persistent staging/review/identity reuse, transactional commit and audit. Imported claims remain Unverified.
- Phase 7: bounded graph traversal, native explorer/Why paths, related navigation and generic stored-knowledge comparison (`PHASE_7_CHECKPOINT.md`).
- Phase 8: end-to-end degradation screening with source-backed explicit rules, contradictions, assumptions, data gaps, report export and optional local explanation (`ENGINEERING_TOOLS.md`).
- Phase 9: adaptive mobile reference/Ask/update UI and opt-in private CloudKit adapter for a separate permitted personal/public vault; conflict review and local recovery (`MOBILE_SYNC.md`).
- Phase 10: controlled local degradation agent using existing services, limited explicit tools, structured reports, local history and research handoff through the Phase 6 boundary (`ENGINEERING_AGENT.md`).

## Storage and compatibility

Original `Application Support/MaterialsIntelligence/knowledge.sqlite` stays local. `personal-public.sqlite` is a separate explicit sync vault, never an automatic copy. Schema 6 adds agent audit after schema 5 sync metadata; migrations retain existing IDs/provenance. No second search, graph or engineering database is introduced. Sync intentionally excludes files/bookmarks and agent task history. Incoming snapshot replacement needs review, including changed/deleted Verified claims.

## Validation and limitations

Seven deterministic suites cover repository/migrations, RAG, ingestion, graph, degradation, sync and agent benchmarks. Mac, generic iOS Simulator and generic iOS device builds are supported. Mac process launch is testable. Actual GUI screenshots cannot be captured on this display; no mobile simulator runtime/device is installed. Real iCloud account/entitlement behavior and actual on-device model generation are UNVERIFIED. Exact manual checks are in the phase documents; do not treat build success as visual acceptance.

Known functional scope limits: lexical/metadata search, narrative rather than typed material properties, conservative exact-scope rules, no semantic contradiction detection or quantitative likelihood, no field-level sync merge, no automatic external research. Snapshot sync regenerates internal claim timestamps; original research timestamps and Library added dates remain. Claims and sources retain IDs and engineering content. Original Mac authoring remains independent of iCloud.

## Exact next action

Final read-only audit reports ROADMAP NOT COMPLETE; see `FINAL_ROADMAP_AUDIT.md`. Review the sync timestamp-preservation defect before corrective work. Complete the genuine account/device/GUI checks in `MOBILE_SYNC.md`, `ENGINEERING_AGENT.md` and earlier checkpoints before declaring the full product operationally verified. Review final audit findings before any corrective work. No development beyond Phase 10 is authorized. If allowance requires stopping, this state and phase guides are the continuation handoff.
