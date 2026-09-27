# Manual Acceptance Remaining — 2026-09-27

Automated coverage is recorded in [FINAL_ACCEPTANCE_REPORT.md](FINAL_ACCEPTANCE_REPORT.md). Mark each item PASS, FAIL, or BLOCKED with the device, OS/Xcode version and a short note. Use synthetic, non-sensitive data only. Do not treat a build or accessibility route sweep as visual or engineering acceptance.

## macOS visual and accessibility review

- [ ] Capture the actual app at the reference window sizes and compare against the UI sketches. Check clipping, hierarchy, spacing, contrast, empty states, scrolling, and overflow controls.
- [ ] Review Light and Dark appearance on Overview, records, Library, Research, Claims, Relationships, Explorer, Assessment, Agent and all Personal Vault tabs.
- [ ] Complete keyboard-only navigation, focus order, Return/Space actions, and VoiceOver labels/announcements.
- [ ] Walk through record, claim, relationship and deletion flows using synthetic data; confirm content persists after relaunch and guarded deletion remains clear.
- [ ] Import a synthetic research fixture, inspect proposals, accept/reject/reuse/edit, cancel one session, then commit another and inspect history/search results.
- [ ] Run Explorer/Why/comparison, a bounded degradation assessment/report export, and the Engineering Agent deterministic workflow, history and Research handoff from the live app.

Use the detailed steps in [MANUAL_VERIFICATION_GUIDE.md](MANUAL_VERIFICATION_GUIDE.md). The automated UI harness already covers window mechanics, navigation routes, Private Vault tab switching, its reference editor open/cancel flow, sync status/consent lifecycle, and close/reopen.

## Library file interaction

- [ ] Select a synthetic local PDF or text file through the Library document picker and register it.
- [ ] Open it through the app and confirm the expected macOS application opens it.
- [ ] Relaunch and confirm the Library item remains available.
- [ ] Move the file, confirm the app retains its metadata and reports the broken reference, then use Locate file to relink it.

The bookmark service tests cover persistence, missing/moved files and relinking. The user-driven macOS panel and default-app flow remains outstanding.

## Foundation Models

- [ ] On an Apple device whose Foundation Models status is available, run Ask and the optional Agent explanation against reviewed synthetic evidence; check that displayed claim IDs resolve to retrieved evidence.
- [ ] Record the exact result when the model is unavailable. The current Mac reports `modelNotReady`; this is an environment status, not a test pass for real generation.

## CloudKit and iPhone/iPad

- [ ] Configure and sign both targets using the steps in [MOBILE_SYNC.md](MOBILE_SYNC.md), including the Development container, entitlements and `MICloudEnabled` setting.
- [ ] Transfer a synthetic personal/public reference between the Mac and an iPhone/iPad, explicitly review the incoming snapshot, then relaunch offline and search/read locally.
- [ ] Make independent offline edits, verify conflict review and both whole-snapshot resolution directions, restore recovery, and review archive/deletion propagation.
- [ ] Run on both iPhone and iPad; inspect collapsed phone navigation, tablet list/detail, keyboard and VoiceOver behavior.

The current unsigned development build returns the CloudKit configuration guard. No simulator runtime or device was available for this checkpoint, and no user's iCloud account was contacted.
