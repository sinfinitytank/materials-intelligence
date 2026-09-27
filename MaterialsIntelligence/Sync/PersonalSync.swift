import Foundation
import CloudKit
import Combine

@MainActor final class PersonalSync: ObservableObject {
    @Published var status = "Offline · sync disabled"
    @Published var review = ""
    @Published var pending = false
    @Published var busy = false
    let store: KnowledgeStore
    private var remoteRecord: CKRecord?
    private var remoteSnapshot: VaultSnapshot?
    private var capturedLocal: Data?
    private var database: CKDatabase?
    private let recordID = CKRecord.ID(recordName: "personal-vault-v1")
    init(store: KnowledgeStore) { self.store = store }
    static func openStore() throws -> KnowledgeStore {
        let url = try KnowledgeStore.applicationURL().deletingLastPathComponent().appending(path: "personal-public.sqlite")
        return try KnowledgeStore(url: url)
    }
    func synchronize(consent: Bool) async {
        guard consent, !busy else { return }
        busy = true; pending = false; review = ""; defer { busy = false }
        do {
            guard Bundle.main.object(forInfoDictionaryKey: "MICloudEnabled") as? Bool == true else {
                throw KnowledgeStoreError(message: "CloudKit is not configured in this development build. Sign with the documented iCloud container and enable MICloudEnabled; offline use remains available.")
            }
            let container = CKContainer(identifier: "iCloud.com.materialsintelligence.app")
            guard try await container.accountStatus() == .available else { throw KnowledgeStoreError(message: "Sign in to an available iCloud account") }
            let db = container.privateCloudDatabase; database = db
            let local = try VaultSnapshot(store: store); try local.validate()
            let localData = try local.encoded(); capturedLocal = localData
            let record: CKRecord?
            do { record = try await db.record(for: recordID) }
            catch let error as CKError where error.code == .unknownItem { record = nil }
            remoteRecord = record
            let remote: Data?
            if let record {
                guard let asset = record["payload"] as? CKAsset, let url = asset.fileURL else { throw KnowledgeStoreError(message: "Cloud snapshot has no readable payload") }
                remote = try Data(contentsOf: url)
                remoteSnapshot = try VaultSnapshot.decode(remote!)
            } else { remote = nil; remoteSnapshot = nil }
            let base = try store.syncMetadata("base").flatMap { Data(base64Encoded: $0) }
            switch VaultReconciliation.decision(local: localData, remote: remote, base: base) {
            case .unchanged:
                try store.setSyncMetadata("base", localData.base64EncodedString()); status = "Up to date"
            case .upload: try await upload(localData)
            case .download, .conflict:
                pending = true
                review = try remoteSnapshot?.reviewCompared(to: local) ?? "Cloud record was removed. Explicitly keep local to recreate it."
                status = "Review required — no data overwritten"
            }
        } catch { status = "Sync paused: \(error.localizedDescription)" }
    }
    func useRemote() throws {
        guard !busy, pending, let remoteSnapshot, let capturedLocal else { throw KnowledgeStoreError(message: "No remote snapshot to apply") }
        guard try VaultSnapshot(store: store).encoded() == capturedLocal else { throw KnowledgeStoreError(message: "Local vault changed; sync again before resolving") }
        try store.setSyncMetadata("recovery", capturedLocal.base64EncodedString())
        try store.replacePersonalSnapshot(remoteSnapshot)
        pending = false; review = ""; status = "Remote snapshot applied after review"
    }
    func keepLocal() async {
        guard !busy, pending, let capturedLocal else { return }
        busy = true; defer { busy = false }
        do {
            guard try VaultSnapshot(store: store).encoded() == capturedLocal else { throw KnowledgeStoreError(message: "Local vault changed; sync again") }
            if let remoteSnapshot { try store.setSyncMetadata("recovery", try remoteSnapshot.encoded().base64EncodedString()) }
            try await upload(capturedLocal)
        } catch { status = "Conflict retained: \(error.localizedDescription)" }
    }
    func restoreRecovery() throws {
        guard !busy, let data = try store.syncMetadata("recovery").flatMap({ Data(base64Encoded: $0) }) else { throw KnowledgeStoreError(message: "No recovery snapshot") }
        let previous = try VaultSnapshot(store: store).encoded()
        let oldBase = try store.syncMetadata("base") ?? ""
        try store.replacePersonalSnapshot(VaultSnapshot.decode(data))
        try store.setSyncMetadata("base", oldBase)
        try store.setSyncMetadata("recovery", previous.base64EncodedString())
        pending = false; review = ""; status = "Recovery restored locally; sync to review differences"
    }
    private func upload(_ data: Data) async throws {
        guard let database else { throw KnowledgeStoreError(message: "Cloud unavailable") }
        let file = FileManager.default.temporaryDirectory.appending(path: "vault-\(UUID()).json")
        try data.write(to: file, options: .atomic); defer { try? FileManager.default.removeItem(at: file) }
        let record = remoteRecord ?? CKRecord(recordType: "PersonalVault", recordID: recordID)
        record["payload"] = CKAsset(fileURL: file)
        record["version"] = 1 as CKRecordValue
        let results = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .ifServerRecordUnchanged, atomically: false)
        guard let saved = results.saveResults[recordID] else { throw KnowledgeStoreError(message: "Cloud did not acknowledge snapshot") }
        _ = try saved.get()
        try store.setSyncMetadata("base", data.base64EncodedString())
        pending = false; review = ""; status = "Synchronized personal/public vault"
    }
}
