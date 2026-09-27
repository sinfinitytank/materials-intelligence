import Foundation
import SQLite3
@main struct VaultSyncTests {
    static func check(_ value: @autoclosure () throws -> Bool, _ label: String) throws { guard try value() else { throw KnowledgeStoreError(message: label) } }
    static func main() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "sync-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let a = try KnowledgeStore(url: dir.appending(path: "a.sqlite")), b = try KnowledgeStore(url: dir.appending(path: "b.sqlite")), c = try KnowledgeStore(url: dir.appending(path: "c.sqlite"))
        try a.save(KnowledgeRecord(id: "m", kind: .material, name: "Synthetic sync material"))
        try a.save(KnowledgeRecord(id: "s", kind: .source, name: "Synthetic source"))
        let originalClaim = EngineeringClaim(id: "claim-1", subjectID: "m", predicate: "test", statement: "Synthetic evidence", sourceID: "s", status: .verified, createdAt: "2020-01-02 03:04:05", modifiedAt: "2024-05-06 07:08:09")
        try a.save(originalClaim, preservingTimestamps: true)
        try a.save(LibraryDocument(id: "d", title: "Local file", bookmark: "device-private"), recordIDs: ["m"])
        let researchFixture = try Data(contentsOf: URL(fileURLWithPath: "Fixtures/alloy-725-research.json"))
        let researchSession = try a.importResearch(researchFixture)
        let snapshot = try VaultSnapshot(store: a), data = try snapshot.encoded()
        try check(snapshot.documents[0].bookmark.isEmpty, "bookmarks cannot upload")
        try b.replacePersonalSnapshot(VaultSnapshot.decode(data))
        try check(try b.claim(id: "claim-1") == originalClaim && b.foreignKeyViolations() == 0, "claim identity, lifecycle and timestamps roundtrip")
        try check(try b.researchSessions().first?.importedAt == researchSession.importedAt, "research import timestamp survives sync")
        try check(try !b.search("Synthetic").isEmpty, "FTS after remote apply")
        try check(VaultReconciliation.decision(local: data, remote: data, base: nil) == .unchanged, "equal")
        try check(VaultReconciliation.decision(local: data, remote: nil, base: nil) == .upload, "fresh upload")
        let alternate = Data("changed".utf8)
        try check(VaultReconciliation.decision(local: alternate, remote: data, base: data) == .upload, "local edit")
        try check(VaultReconciliation.decision(local: data, remote: alternate, base: data) == .download, "remote edit requires review")
        try check(VaultReconciliation.decision(local: alternate, remote: Data("other".utf8), base: data) == .conflict, "two device edit")
        try check(VaultReconciliation.decision(local: data, remote: nil, base: data) == .conflict, "remote deletion")

        // Two isolated peers edit independently from a common snapshot. Conflict
        // review preserves the selected peer's exact claim timestamps and recovery.
        try c.replacePersonalSnapshot(VaultSnapshot.decode(data))
        var localMaterial = try b.record(id: "m")!
        localMaterial.detail = "offline local edit"
        try b.save(localMaterial)
        var remoteClaim = try a.claim(id: "claim-1")!
        remoteClaim.statement = "Synthetic evidence changed on peer A"
        try a.save(remoteClaim)
        remoteClaim = try a.claim(id: "claim-1")!
        try check(remoteClaim.createdAt == originalClaim.createdAt && remoteClaim.modifiedAt != originalClaim.modifiedAt, "ordinary claim edits preserve creation time and advance modification time")
        let localData = try VaultSnapshot(store: b).encoded()
        let remoteData = try VaultSnapshot(store: a).encoded()
        try check(VaultReconciliation.decision(local: localData, remote: remoteData, base: data) == .conflict, "independent peer edits require review")
        try b.setSyncMetadata("recovery", localData.base64EncodedString())
        try b.replacePersonalSnapshot(VaultSnapshot.decode(remoteData))
        let selectedRemoteClaim = try b.claim(id: "claim-1")!
        try check(selectedRemoteClaim.createdAt == remoteClaim.createdAt && selectedRemoteClaim.modifiedAt == remoteClaim.modifiedAt, "reviewed remote resolution preserves claim timestamps")
        try b.replacePersonalSnapshot(VaultSnapshot.decode(Data(base64Encoded: try b.syncMetadata("recovery")!)!))
        try check(try b.record(id: "m")?.detail == "offline local edit", "recovery restores the pre-resolution local snapshot")
        let repeated = try VaultSnapshot(store: b).encoded()
        try c.replacePersonalSnapshot(VaultSnapshot.decode(repeated))
        try check(try c.claim(id: "claim-1")?.createdAt == originalClaim.createdAt && c.claim(id: "claim-1")?.modifiedAt == originalClaim.modifiedAt, "repeated A to B to C roundtrip does not drift claim timestamps")

        // Prior v1 snapshots omit claim timestamp fields; decode defaults them
        // safely, and SQLite supplies timestamps when that snapshot is applied.
        var legacyObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        var legacyClaims = legacyObject["claims"] as! [[String: Any]]
        legacyClaims[0].removeValue(forKey: "createdAt")
        legacyClaims[0].removeValue(forKey: "modifiedAt")
        legacyObject["claims"] = legacyClaims
        let legacySnapshot = try VaultSnapshot.decode(JSONSerialization.data(withJSONObject: legacyObject))
        try check(legacySnapshot.claims[0].createdAt.isEmpty && legacySnapshot.claims[0].modifiedAt.isEmpty, "legacy v1 timestamp defaults")
        let legacyStore = try KnowledgeStore(url: dir.appending(path: "legacy.sqlite"))
        try legacyStore.replacePersonalSnapshot(legacySnapshot)
        try check(try !(legacyStore.claim(id: "claim-1")?.createdAt.isEmpty ?? true) && !(legacyStore.claim(id: "claim-1")?.modifiedAt.isEmpty ?? true), "legacy snapshots receive safe local timestamps")

        var archived = try a.claim(id: "claim-1")!; archived.status = .archived; try a.save(archived)
        try b.replacePersonalSnapshot(VaultSnapshot(store: a))
        try check(try b.claim(id: "claim-1")?.status == .archived, "archive survives sync")
        try a.deleteClaim(id: "claim-1"); try b.replacePersonalSnapshot(VaultSnapshot(store: a))
        try check(try b.claim(id: "claim-1") == nil, "explicit snapshot deletion")
        var invalid = try JSONSerialization.jsonObject(with: data) as! [String: Any]; invalid["version"] = 99
        do { _ = try VaultSnapshot.decode(JSONSerialization.data(withJSONObject: invalid)); fatalError("new schema accepted") } catch is KnowledgeStoreError { }
        // Bulk representative snapshot exercises a single transactional FTS rebuild.
        var large = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        var rows = large["records"] as! [[String: Any]]
        rows += (0..<2000).map { ["id":"large\($0)","kind":"material","name":"Large synthetic \($0)","detail":"","secondary":""] }
        large["records"] = rows
        let before = Date(); try b.replacePersonalSnapshot(VaultSnapshot.decode(JSONSerialization.data(withJSONObject: large)))
        try check(try b.records().count == 2002 && b.foreignKeyViolations() == 0, "large local database")
        try check(Date().timeIntervalSince(before) < 15, "bulk sync performance")
        try check(try VaultSnapshot(store: b).documents[0].addedAt == snapshot.documents[0].addedAt, "document date preserved")
        let old = try VaultSnapshot(store: b).encoded()
        var db: OpaquePointer?; sqlite3_open(dir.appending(path: "b.sqlite").path, &db)
        sqlite3_exec(db, "CREATE TRIGGER fail_sync BEFORE INSERT ON records WHEN NEW.id='m' BEGIN SELECT RAISE(ABORT,'forced sync failure'); END", nil, nil, nil); sqlite3_close(db)
        do { try b.replacePersonalSnapshot(snapshot); fatalError("expected transaction failure") } catch { }
        try check(try VaultSnapshot(store: b).encoded() == old, "late failure rolls back all tables and FTS")
        let reopened = try KnowledgeStore(url: dir.appending(path: "b.sqlite"))
        try check(try reopened.records().count == 2002, "offline reopen")
        try reopened.setSyncMetadata("migration-check", "preserve")
        sqlite3_open(dir.appending(path: "b.sqlite").path, &db)
        sqlite3_exec(db, "DROP TABLE agent_runs; PRAGMA user_version=5", nil, nil, nil); sqlite3_close(db)
        let migrated = try KnowledgeStore(url: dir.appending(path: "b.sqlite"))
        try check(try migrated.schemaVersion() == 6 && migrated.syncMetadata("migration-check") == "preserve" && migrated.records().count == 2002, "schema 5 to 6 preserves sync and knowledge")
        print("Vault sync tests passed: timestamp roundtrip/recovery/legacy, conflicts, archive/delete, provenance, atomic rollback, 2002 records, offline reopen")
    }
}
