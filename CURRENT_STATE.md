# Current State — 2026-09-27

## Implemented scope

Phases 0–10 now have native implementations: macOS 26+ workstation plus a universal iPhone/iPad iOS 26+ target. One shared domain and SQLite repository remain the foundation; no web runtime or third-party dependency was added.

- Phases 0–4: native authoring, records/claims/relationships, guarded deletion, source provenance, FTS and bookmark-referenced Library.
- Phase 5: bounded local RAG, Reviewed/Verified evidence gate, exact citation-ID validation, Apple on-device provider and honest unavailable state.
- Phase 6: schema-v1 research packages, persistent staging/review/identity reuse, transactional commit and audit. Imported claims remain Unverified.
- Phase 7: bounded graph traversal, native explorer/Why paths, related navigation and generic stored-knowledge comparison.
- Phase 8: five native engineering workflows: material comparison, source-backed degradation screening, vendor qualification record, failure investigation record, and fit-for-purpose evidence review. All expose source-linked evidence, assumptions/user-input boundaries, missing data, report export and optional local explanation (`ENGINEERING_TOOLS.md`).
- Phase 9: adaptive mobile reference/Ask/update UI and opt-in private CloudKit adapter for a separate permitted personal/public vault; conflict review and local recovery (`MOBILE_SYNC.md`).
- Phase 10: controlled local agent orchestrating all five Phase 8 workflows through existing search, graph, claim/source retrieval and deterministic rule services; structured request/report history and Research handoff remain local (`ENGINEERING_AGENT.md`).
- Private Vault navigation: Mac Reference uses a native list/detail HStack inside the app's main split view; iOS retains its adaptive split. This avoids nested macOS split views interfering with the workspace sidebar. Reference, Ask, Sync and Mac-only review tabs retain independent navigation state.
- macOS branding: a custom teal crystal-and-knowledge-graph mark appears in the sidebar and app icon. The About page is available from the toolbar, sidebar, and app menu.
- Visual system: `DesignSystem.swift` supplies shared macOS/iOS colors, semantic status and record colors, spacing, radii, typography, panels, section titles, and page headers; the main screens and Personal Vault use those shared components.

## Storage and compatibility

Original `Application Support/MaterialsIntelligence/knowledge.sqlite` stays local. `personal-public.sqlite` is a separate explicit sync vault, never an automatic copy. Schema 6 adds agent audit after schema 5 sync metadata; migrations retain existing IDs/provenance. No second search, graph or engineering database is introduced. Sync intentionally excludes files/bookmarks and agent task history. Incoming snapshot replacement needs review, including changed/deleted Verified claims.

## Validation and limitations

Nine deterministic suites cover repository/migrations, RAG, ingestion, graph, all five workflows, sync, Library bookmark lifecycle and agent benchmarks. macOS Debug and Release builds pass; the universal mobile Release target builds for generic iOS Simulator and iOS device destinations. The live macOS accessibility harness checks the standard window, resizing/minimum size, 102 global-navigation transitions at three widths, six Private Vault tabs and rapid switching, the reference editor open/cancel flow, sync error/consent lifecycle, close/reopen, and unchanged isolated vault data. The workflow forms and reports still need a user-driven visual/accessibility walkthrough.

The latest live accessibility run passes 108 workspace route transitions at three window sizes, About toolbar navigation, all six Private Vault tabs, the reference editor cancel path, sync guard/consent lifecycle, close/reopen, and isolated vault checks. Screenshots cannot be captured on this display (`could not create image from display`). Light/dark appearance, full keyboard/VoiceOver review, Library file-picker selection/open/relink, and user-driven Research/engineering-workflow walks remain manual. No iOS simulator runtime or connected iPhone/iPad is installed. CloudKit remains unconfigured in this unsigned development build; no account/device transfer was attempted. The live Foundation Models probe reports `modelNotReady`, so real on-device generation remains unverified. The earlier sync timestamp and macOS Private Vault navigation defects are corrected. See `MANUAL_ACCEPTANCE_REMAINING.md` for the outstanding checks.

Claim creation/modification timestamps round-trip through sync and survive reviewed replacement/recovery without drifting over repeated snapshots. Legacy v1 snapshots without those fields receive local SQLite timestamps. Tests verify these paths. Remaining functional limits include lexical/metadata search, narrative rather than typed material properties, exact-scope source-authored workflow rules, no semantic contradiction detection or quantitative likelihood, whole-snapshot sync conflict resolution, and no automatic external research. Original Mac authoring remains independent of iCloud.

## Ongoing work

The planned phases are implemented. Scope future tweaks and features individually. Complete the remaining manual checks in `MANUAL_ACCEPTANCE_REMAINING.md` using a model-ready Mac, Apple signing/team setup, CloudKit development container, iOS devices/runtime, and full GUI review. Operational acceptance remains open until the account/device and user-driven checks pass.
