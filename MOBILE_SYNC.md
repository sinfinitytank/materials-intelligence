# Phase 9 — mobile and personal/public sync

## Shared architecture

The universal `MaterialsIntelligenceMobile` native target supports both iPhone and iPad (device families 1,2), iOS/iPadOS 26+. It compiles the same domain, SQLite repository, FTS, research schema, graph, assessment and local-AI services as Mac. Shared source membership avoids a theoretical package refactor. Mac retains its mature AppKit/SwiftUI authoring UI. Mobile Reference uses adaptive NavigationSplitView (collapsed navigation on iPhone, list/detail on iPad), plus Ask and Sync tabs. Reading, source/claim inspection, record notes and adding references work locally; claim approval and research review remain Mac actions.

## Vault boundary

The original Mac `knowledge.sqlite` remains local and never enters this sync flow. Both platforms open a separate `personal-public.sqlite` through Personal Vault. Nothing copies automatically between them. Mac Personal Vault includes research ingestion, claims and relationship authoring so permitted knowledge can be created through the same review gate. Import only approved personal/public packages there. Restricted-labelled original or edited research packages block snapshot export. Classification is not enterprise DLP: users must not manually paste restricted information into the personal vault. Consent is per view session and defaults off.

## Schema and protocol

SQLite migration 5 adds only `sync_state` for base/recovery metadata in the existing database. Existing records, IDs, relationships and FTS remain intact. Sync wire format v1 is a canonical JSON snapshot of records, claims, relationships, Library metadata/associations and research staging/audit. Bookmarks and file contents stay device-local. Unknown wire versions, duplicate IDs and invalid references fail before application. Snapshot replacement runs transactionally with one FTS rebuild; known local bookmarks survive by document ID. Wire limit: 20 MB, 10,000 records, 20,000 claims and 30,000 relationships. Tests exercise 2,002 stored records; this is not a claim of cloud-scale performance.

The CloudKit adapter uses the private database, record type `PersonalVault`, record ID `personal-vault-v1`, a payload CKAsset and integer version. One shared snapshot is deliberately conservative for a small personal vault. Sync runs only on explicit Sync now. No background network, remote model or web backend exists. CloudKit `.ifServerRecordUnchanged` compare-and-swap rejects concurrent cloud edits. Base snapshot comparison detects independent local/remote changes. Incoming content is always reviewed, even when only remote changed; independent changes require choosing a whole snapshot. No automatic field merge or silent last-writer-wins.

The review contains the full incoming JSON and counts; explicit confirmation can replace local or remote. A pre-resolution recovery snapshot remains in local SQLite. Stale local edits invalidate resolution. Restore recovery is explicit and retains the current content as the next recovery snapshot. Deletions propagate only through reviewed replacement; archived claim states round-trip unchanged. Deleting the remote CloudKit record is a conflict, not permission to delete local data. V1 snapshots include claim `createdAt` and `modifiedAt` values, and snapshot application preserves both in SQLite. Older v1 payloads that omit them decode as empty values and receive local SQLite timestamps when applied, avoiding fabricated historical dates. Research import timestamps and IDs also remain unchanged.

## Apple setup (UNVERIFIED here)

Unsigned builds intentionally return a configuration status without constructing CKContainer. To exercise actual sync:

1. In Xcode use an Apple development team entitled to the app identifiers and register `iCloud.com.materialsintelligence.app`. Enable iCloud/CloudKit for both targets.
2. Sign both targets with `Configuration/PersonalCloud.entitlements` and a matching provisioning profile; set `CODE_SIGNING_ALLOWED=YES`, `DEVELOPMENT_TEAM` to your team, `CODE_SIGN_ENTITLEMENTS=Configuration/PersonalCloud.entitlements`, and generated Info.plist key `MICloudEnabled` to Boolean YES (`INFOPLIST_KEY_MICloudEnabled=YES`). Use the Development CloudKit environment for this test.
3. In the development container create/allow record type PersonalVault with payload Asset and version Int64. Do not deploy a production schema without reviewing this prototype protocol.
4. Run Mac and one iPhone/iPad signed into the same iCloud account. Opt in on both. Create a synthetic reference on Mac, Sync now; on mobile Sync now, review and apply. Relaunch in airplane mode and search/read it.
5. Edit notes independently on both offline; sync one, then the other. Confirm review is required and neither is silently overwritten. Resolve each direction and test recovery. Archive/delete a synthetic claim on Mac and verify reviewed propagation.
6. Run on both iPhone and iPad; check collapsed versus split navigation, source links, keyboard, VoiceOver and local Ask. Unsupported/unready model must show unavailable status.

Real iCloud transfer, signing, account failure modes and simulator/device UI are UNVERIFIED. This machine has SDKs but no simulator runtime/devices. Mac screenshot capture fails (`could not create image from display`). No network call was made to a user's iCloud account during development.

## Executable verification

VaultSyncTests cover exact claim timestamp roundtrip, repeated A→B→C snapshots without timestamp drift, independent peer edits, reviewed replacement, local recovery, legacy v1 timestamp defaults, archive/delete, version rejection, transactional rollback, FTS and larger datasets. The full `Scripts/test.sh` suite passes. macOS Debug/Release and generic iOS Simulator/device Release builds pass. A separate macOS accessibility harness verifies sync's local unavailable-configuration error, consent persistence while changing tabs, and no unsolicited incoming snapshot. These checks do not exercise CloudKit transport.
