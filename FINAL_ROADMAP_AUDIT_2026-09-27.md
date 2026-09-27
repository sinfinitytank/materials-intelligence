# Final Roadmap Audit — stabilization follow-up, 2026-09-27

This audit follows the historical snapshot in [FINAL_ROADMAP_AUDIT.md](FINAL_ROADMAP_AUDIT.md). It records the verified corrective work and current gates without redefining the phase requirements in `Materials_Intelligence_Project_Phases.md`.

## Status

Implementations exist through Phase 10. The previously identified claim-timestamp defect is corrected. The newly reproduced macOS Private Vault navigation issue is corrected and passes live accessibility navigation. **ROADMAP NOT COMPLETE** because Phase 9 requires real signed account/device acceptance and several visual, file-picker, model and workflow checks remain unperformed.

| Phase | Current evidence | Remaining acceptance |
|---|---|---|
| 0–2 | Native shell, domain, migrations and provenance suites pass | Visual review and remaining manual workflows below |
| 3–4 | Repository lifecycle, FTS, Library bookmark service and interaction tests pass | User-driven authoring and real macOS file selection/open/relink |
| 5 | Retrieval gates and deterministic provider tests pass | Real Foundation Models generation on an eligible, model-ready device |
| 6 | Research JSON stage/review/commit/search/RAG integration tests pass | Full user-driven review workflow and real model follow-up |
| 7–8 | Graph traversal/comparison and source-backed assessment suites pass | Live visual/workflow review and report-export check |
| 9 | Universal iPhone/iPad target builds; isolated sync/recovery/timestamp logic tests pass; local UI configuration guard passes | Signed CloudKit transfer, actual phone/tablet runtime, offline/conflict/recovery acceptance; this phase remains incomplete |
| 10 | Nine deterministic agent benchmark runs pass; bounded workflow and handoff are covered | Live evidence/History/Research walkthrough and real local model explanation |

## Corrective work and root cause

- A compact-width UI sweep reproduced the outer workspace sidebar disappearing after the Personal Vault's nested macOS `NavigationSplitView` was visited and exited. The Reference tab now uses a native HStack master/detail presentation on macOS; the root split and iOS adaptive split remain. The full live accessibility sweep now passes 102 workspace route transitions at three widths.
- Empty Relationships pages show an explicit, accessible empty state.
- Claim timestamps now appear in the v1 snapshot model and are stored exactly during reviewed snapshot application. Legacy snapshots without those fields receive local database timestamps. Tests cover original roundtrip, independent peer edits, reviewed remote replacement, recovery, repeated peer transfer without timestamp drift, and legacy payloads.

The previous audit's timestamps-as-defect finding is preserved historically but is no longer a current defect.

## Verification

- `Scripts/test.sh`: all eight suites pass: KnowledgeStore, LocalRAG, ResearchIngestion, KnowledgeGraph, DegradationAssessment, VaultSync, LibraryIntegration and AgentBenchmark.
- macOS Debug and Release builds pass.
- `MaterialsIntelligenceMobile` Release builds pass for generic iOS Simulator and generic iOS device destinations.
- Live macOS accessibility interaction passes: standard window, resize/minimum-size behavior, all 17 routes forward and reverse at three sizes, all six Private Vault tabs and rapid switching, reference editor open/cancel, sync guard and consent lifecycle, close/reopen, and unchanged isolated vault database.
- `zsh -n Scripts/ui-acceptance.sh`, Swift typecheck for the harness, and `git diff --check` pass.

The current Foundation Models availability is `modelNotReady`. No iOS simulator runtime/device is installed. The development project has no signing team, attached CloudKit entitlement or enabled CloudKit flag. Accessibility interaction was possible, but screenshot capture failed with `could not create image from display`; visual review remains open. No account or CloudKit transport request was made.

## Decision

Do not mark the roadmap complete. Complete [MANUAL_ACCEPTANCE_REMAINING.md](MANUAL_ACCEPTANCE_REMAINING.md) when the required Apple model, signing/account setup, device/runtime and GUI review are available. No Phase 11 scope is authorized by this checkpoint.
