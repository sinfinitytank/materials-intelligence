# Milestone — remaining roadmap implementation

Phase 6 baseline was verified and committed before sequential Phase 7–10 work.

| Milestone | Checkpoint | Scope |
|---|---|---|
| Phase 6 baseline | 7446dc3 | Preserved existing uncommitted research UI, tests and documentation |
| Phase 7 | ba0a8ab | Graph/Why/comparison; regressions and Release build passed |
| Phase 8 | f39f919 | Degradation workflow; synthetic cases, regressions and Release build passed |
| Phase 9 | 2ef9b99 | Shared mobile target, personal vault and sync; deterministic tests and all target builds passed |
| Phase 10 | 66fd798 | Agent, history and benchmarks; see verification below |

## Verification

`Scripts/test.sh` runs KnowledgeStore, LocalRAG, ResearchIngestion, KnowledgeGraph, DegradationAssessment, VaultSync and AgentBenchmark tests. Tests include 10,000-node graph traversal, 2,002-record transactional sync/offline reopen, and nine agent benchmark runs. Migration 5→6 retains sync metadata and knowledge. Existing suites were retained; schema-version expectations advance with actual migrations.

Build targets: MaterialsIntelligence Release macOS; MaterialsIntelligenceMobile Release generic iOS Simulator; MaterialsIntelligenceMobile Release generic iOS device (unsigned build verification). Mobile uses device families 1 and 2. Mac app launch is verified independently from GUI acceptance.

## Unverified gates

- Native GUI interaction, resize/appearance/accessibility: screen capture unavailable.
- iPhone/iPad runtime/offline UI: no simulator runtime or device installed.
- Real iCloud: requires signing, entitlements, account and two devices; development build explicitly reports unconfigured.
- Real local AI output: needs model-ready Apple device; deterministic injected-provider tests do not establish semantic accuracy.

Exact small manual procedures: `PHASE_7_CHECKPOINT.md`, `ENGINEERING_TOOLS.md`, `MOBILE_SYNC.md`, `ENGINEERING_AGENT.md`, and `PHASE_6_CHECKPOINT.md`.

## Remaining work

Final read-only-style audit is recorded in `FINAL_ROADMAP_AUDIT.md`: ROADMAP NOT COMPLETE due to Phase 9 operational acceptance and timestamp preservation. No implementation repairs were made during the audit. Complete reviewed corrective work and external/manual validation before an unqualified roadmap-complete claim. Preserve any audit findings for the user's next decision. No later product phase is authorized.
