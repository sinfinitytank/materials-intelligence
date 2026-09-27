# Milestone — Phase 0–10 stabilization and acceptance

Phase 6 baseline was verified and committed before sequential Phase 7–10 work.

| Milestone | Checkpoint | Scope |
|---|---|---|
| Phase 6 baseline | 7446dc3 | Preserved existing uncommitted research UI, tests and documentation |
| Phase 7 | ba0a8ab | Graph/Why/comparison; regressions and Release build passed |
| Phase 8 | f39f919 | Degradation workflow; synthetic cases, regressions and Release build passed |
| Phase 9 | 2ef9b99 | Shared mobile target, personal vault and sync; deterministic tests and all target builds passed |
| Phase 10 | 66fd798 | Agent, history and benchmarks; see verification below |
| Final stabilization | 2026-09-27 | Claim timestamp preservation, macOS Private Vault navigation correction, live accessibility acceptance, and current manual-gate audit |

## Verification

`Scripts/test.sh` runs eight suites: KnowledgeStore, LocalRAG, ResearchIngestion, KnowledgeGraph, DegradationAssessment, VaultSync, LibraryIntegration and AgentBenchmark. Tests include 10,000-node graph traversal, 2,002-record transactional sync/offline reopen, claim timestamp roundtrip/recovery/legacy handling, bookmark resolve/move/relink, and nine agent benchmark runs. Migration 5→6 retains sync metadata and knowledge. Existing suites were retained; schema-version expectations advance with actual migrations.

Build targets: MaterialsIntelligence Debug and Release macOS; MaterialsIntelligenceMobile Release generic iOS Simulator; MaterialsIntelligenceMobile Release generic iOS device (unsigned build verification). Mobile uses device families 1 and 2. `Scripts/ui-acceptance.sh` launches an isolated Mac app and verifies the native standard window, resizing/minimum size, 102 route transitions at three widths, six Private Vault tabs/rapid switching, reference editor open/cancel, sync status/consent lifecycle, close/reopen, and unchanged isolated vault data.

## Unverified gates

- Screenshot-based visual inspection and full light/dark, keyboard, and VoiceOver review: screen capture is unavailable (`could not create image from display`). Automated accessibility interaction and resize checks pass.
- Library's real macOS file-picker selection/open/restart/move/relink flow, plus full authoring/Research/assessment/agent UI walkthroughs: follow `MANUAL_ACCEPTANCE_REMAINING.md`.
- iPhone/iPad runtime and offline UI: no simulator runtime or device is installed; generic unsigned builds pass.
- Real iCloud: requires signing, entitlements, account, CloudKit development schema and devices; the development build explicitly reports unconfigured. No user's iCloud account was contacted.
- Real local AI output: this Mac reports Foundation Models `modelNotReady`; deterministic injected-provider tests do not establish semantic accuracy.

Claim timestamp preservation identified by the previous audit is corrected and covered by roundtrip, reviewed replacement, recovery, legacy-v1 and repeated-sync tests.

Exact small manual procedures: `PHASE_7_CHECKPOINT.md`, `ENGINEERING_TOOLS.md`, `MOBILE_SYNC.md`, `ENGINEERING_AGENT.md`, and `PHASE_6_CHECKPOINT.md`.

## Remaining work

The original read-only audit remains in `FINAL_ROADMAP_AUDIT.md`; its timestamp finding was repaired and its historical result is superseded by `FINAL_ROADMAP_AUDIT_2026-09-27.md`. ROADMAP NOT COMPLETE remains accurate because real Phase 9 signing/account/device operation and the listed manual GUI checks are still outstanding. No later product phase is authorized.
