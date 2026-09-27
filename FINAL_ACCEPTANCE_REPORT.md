# Final Acceptance Report — 2026-09-27

## Result

The Phase 0–10 implementation checkpoint passes its deterministic suites, macOS Debug/Release builds, generic iOS Simulator/device Release builds, and an automated live macOS accessibility interaction run. The macOS Personal Vault navigation defect found during final acceptance was corrected, and the earlier claim-timestamp preservation defect is fixed and regression-tested.

**ROADMAP NOT COMPLETE.** Real CloudKit operation, iPhone/iPad runtime behavior, real Foundation Models generation, screenshot-based visual review, and several user-driven workflows remain unverified. No Phase 11 work was performed.

## Corrections completed

- The nested `NavigationSplitView` in the macOS Personal Vault Reference tab caused the outer workspace sidebar to disappear after visiting and leaving the vault in compact-width navigation. The Mac reference pane now uses a native list/detail HStack within the existing outer split. iOS retains its adaptive split view.
- Empty Relationships pages now explain that no relationships exist and how the user can begin.
- Engineering-claim creation and modification timestamps are included in sync snapshots and preserved by reviewed replacement and recovery. Older v1 snapshots without timestamps receive local SQLite timestamps. Roundtrip, peer-conflict, recovery, legacy and repeated-sync tests cover the behavior.
- The macOS Personal Vault reference editor exposes stable accessibility identifiers for its Add and Cancel controls.

## Verification results

| Check | Result |
|---|---|
| `Scripts/test.sh` | Pass: KnowledgeStore, LocalRAG, ResearchIngestion, KnowledgeGraph, DegradationAssessment, VaultSync, LibraryIntegration and AgentBenchmark |
| macOS Debug build | Pass |
| macOS Release build | Pass |
| `MaterialsIntelligenceMobile` generic iOS Simulator Release build | Pass |
| `MaterialsIntelligenceMobile` generic iOS device Release build | Pass, unsigned build verification |
| UI harness syntax/typecheck and `git diff --check` | Pass |
| Live macOS accessibility UI acceptance | Pass, details below |

The deterministic suites cover a 10,000-record graph, 2,002-record sync snapshot/rollback/offline reopen, claim timestamp preservation, research import through commit/search/RAG, Library bookmark resolve/move/relink/persistence, and nine agent benchmark runs.

The live UI harness used an isolated application-support directory and verified:

- A standard, windowed, resizable Materials Intelligence window.
- Window sizes of 1120×732, 1320×820 and 1436×900; an undersized 900×600 request was clamped to 1040×732.
- 17 workspace routes in forward and reverse order at each of three sizes: 102 route transitions total.
- All six Private Vault tabs in both directions, rapid tab switching, opening and cancelling the reference editor, and isolated database counts unchanged.
- Offline sync status, the unconfigured CloudKit guard, consent and sync status surviving tab changes, and no unsolicited remote snapshot.
- Closing and reopening the window while the app process remained alive.

The Foundation Models runtime probe returned `unavailable(FoundationModels.SystemLanguageModel.Availability.UnavailableReason.modelNotReady)`. Deterministic injected-provider tests do not verify real model output.

## Environment limits

- No iOS simulator runtime or available simulator/device is installed. Both generic iOS builds pass; no mobile UI was run.
- The checked development build has code signing disabled, no development team, no attached CloudKit entitlements, and no `MICloudEnabled` flag. The UI test exercised the configuration guard only. No CloudKit account or transport request was used.
- `screencapture -x` failed with `could not create image from display`. Accessibility-based UI interaction passed, but screenshots and visual comparison were unavailable.
- The Library bookmark integration suite exercises synthetic file references and relinking at the service boundary. A user-selected file was not opened through the full macOS file-picker workflow.

See [MANUAL_ACCEPTANCE_REMAINING.md](MANUAL_ACCEPTANCE_REMAINING.md) for the remaining account-, hardware-, and visual-dependent work. Passing builds and tests do not establish scientific validity, semantic support of generated explanations, or zero hallucinations.
