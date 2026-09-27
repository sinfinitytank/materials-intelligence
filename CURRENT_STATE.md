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
- Private Vault navigation: Mac Reference uses a native list/detail HStack inside the app's main split view; iOS retains its adaptive split. This avoids nested macOS split views interfering with the workspace sidebar. Reference, Ask, Sync and Mac-only review tabs retain independent navigation state.

## Storage and compatibility

Original `Application Support/MaterialsIntelligence/knowledge.sqlite` stays local. `personal-public.sqlite` is a separate explicit sync vault, never an automatic copy. Schema 6 adds agent audit after schema 5 sync metadata; migrations retain existing IDs/provenance. No second search, graph or engineering database is introduced. Sync intentionally excludes files/bookmarks and agent task history. Incoming snapshot replacement needs review, including changed/deleted Verified claims.

## Validation and limitations

Eight deterministic suites cover repository/migrations, RAG, ingestion, graph, degradation, sync, Library bookmark lifecycle and agent benchmarks. macOS Debug and Release builds pass; the universal mobile Release target builds for generic iOS Simulator and iOS device destinations. The live macOS accessibility harness checks the standard window, resizing/minimum size, 102 global-navigation transitions at three widths, six Private Vault tabs and rapid switching, the reference editor open/cancel flow, sync error/consent lifecycle, close/reopen, and unchanged isolated vault data.

The final accessibility run passes, but screenshots cannot be captured on this display (`could not create image from display`). Light/dark appearance, full keyboard/VoiceOver review, Library file-picker selection/open/relink, and complete user-driven Research/assessment/agent workflows remain manual. No iOS simulator runtime or device is installed. CloudKit remains unconfigured in this development build; no signed account/device transfer was attempted. Foundation Models reports `modelNotReady`, so real on-device generation remains unverified. See `FINAL_ACCEPTANCE_REPORT.md` and `MANUAL_ACCEPTANCE_REMAINING.md`.

The sync timestamp defect from the earlier audit is corrected: claim creation/modification timestamps now round-trip, survive reviewed replacement/recovery and do not drift over repeated snapshots. Legacy v1 snapshots without those fields receive local SQLite timestamps. Tests verify these paths. Remaining functional limits include lexical/metadata search, narrative rather than typed material properties, conservative exact-scope rules, no semantic contradiction detection or quantitative likelihood, whole-snapshot sync conflict resolution, and no automatic external research. Original Mac authoring remains independent of iCloud.

## Exact next action

Complete the remaining manual checks in `MANUAL_ACCEPTANCE_REMAINING.md` when a model-ready Mac, signing/team setup, CloudKit development container, iOS devices/runtime, and full GUI review are available. Until real Phase 9 device/account acceptance is complete, keep the roadmap marked incomplete. No development beyond Phase 10 is authorized.
