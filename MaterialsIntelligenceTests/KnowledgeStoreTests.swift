import Foundation
import SQLite3

@main struct KnowledgeStoreTests {
    static func check(_ condition: @autoclosure () throws -> Bool, _ label: String) throws {
        guard try condition() else { throw KnowledgeStoreError(message: "Test failed: \(label)") }
    }
    static func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "materials-knowledge-\(UUID().uuidString).sqlite")
    }
    static func sql(_ db: OpaquePointer?, _ statement: String) throws {
        var message: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, statement, nil, nil, &message) == SQLITE_OK else {
            let detail = message.map { String(cString: $0) } ?? "SQLite error"
            sqlite3_free(message)
            throw KnowledgeStoreError(message: detail)
        }
    }
    static func withRawDatabase(_ url: URL, _ work: (OpaquePointer?) throws -> Void) throws {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else { throw KnowledgeStoreError(message: "Cannot create fixture") }
        defer { sqlite3_close(db) }
        try work(db)
    }
    static func legacyFixture(at url: URL) throws {
        try withRawDatabase(url) { db in
            try sql(db, "PRAGMA foreign_keys=ON")
            // Exact v1 DDL from the Phase 2 checkpoint, before claim states expanded.
            try sql(db, "CREATE TABLE records (id TEXT PRIMARY KEY, kind TEXT NOT NULL CHECK(kind IN ('material','mechanism','standard','component','source')), name TEXT NOT NULL COLLATE NOCASE, detail TEXT NOT NULL DEFAULT '', secondary TEXT NOT NULL DEFAULT '', UNIQUE(kind, name))")
            try sql(db, "CREATE TABLE claims (id TEXT PRIMARY KEY, subject_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, predicate TEXT NOT NULL, statement TEXT NOT NULL, conditions TEXT NOT NULL DEFAULT '', source_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, locator TEXT NOT NULL DEFAULT '', status TEXT NOT NULL CHECK(status IN ('unverified','reviewed','verified')), evidence_level TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, modified_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)")
            try sql(db, "CREATE TABLE relationships (id TEXT PRIMARY KEY, from_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, predicate TEXT NOT NULL, to_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, supporting_claim_id TEXT REFERENCES claims(id) ON DELETE RESTRICT, CHECK(from_id <> to_id), UNIQUE(from_id, predicate, to_id))")
            try sql(db, "CREATE INDEX claims_subject_idx ON claims(subject_id)")
            try sql(db, "CREATE INDEX claims_source_idx ON claims(source_id)")
            try sql(db, "CREATE INDEX relationships_from_idx ON relationships(from_id)")
            try sql(db, "CREATE INDEX relationships_to_idx ON relationships(to_id)")
            try sql(db, "CREATE TRIGGER claims_source_kind_insert BEFORE INSERT ON claims WHEN (SELECT kind FROM records WHERE id = NEW.source_id) != 'source' BEGIN SELECT RAISE(ABORT, 'claim source must be a source record'); END")
            try sql(db, "CREATE TRIGGER claims_source_kind_update BEFORE UPDATE OF source_id ON claims WHEN (SELECT kind FROM records WHERE id = NEW.source_id) != 'source' BEGIN SELECT RAISE(ABORT, 'claim source must be a source record'); END")
            try sql(db, "CREATE TRIGGER claims_modified AFTER UPDATE ON claims BEGIN UPDATE claims SET modified_at = CURRENT_TIMESTAMP WHERE id = NEW.id; END")
            try sql(db, "INSERT INTO records(id,kind,name) VALUES ('m','material','Alloy 725'),('s','source','Legacy paper'),('d','mechanism','Hydrogen Embrittlement')")
            try sql(db, "INSERT INTO claims(id,subject_id,predicate,statement,source_id,locator,status) VALUES ('c','m','susceptibility','Hydrogen claim','s','p. 7','reviewed')")
            try sql(db, "INSERT INTO relationships(id,from_id,predicate,to_id,supporting_claim_id) VALUES ('r','m','susceptible_to','d','c')")
            try sql(db, "PRAGMA user_version=1")
        }
    }
    static func migration() throws {
        let url = temporaryURL(); defer { try? FileManager.default.removeItem(at: url) }
        try legacyFixture(at: url)
        do {
            let store = try KnowledgeStore(url: url)
            try check(try store.schemaVersion() == 3, "migration version")
            try check(try store.foreignKeyViolations() == 0, "migration foreign keys")
            try check(try store.record(id: "m")?.name == "Alloy 725", "material preserved")
            try check(try store.record(id: "s")?.kind == .source, "source preserved")
            try check(try store.claim(id: "c")?.sourceID == "s", "claim source preserved")
            try check(try store.claim(id: "c")?.locator == "p. 7", "claim locator preserved")
            try check(try store.relationships(recordID: "m").first?.supportingClaimID == "c", "supporting claim preserved")
            var edited = try store.claim(id: "c")!
            edited.status = .verified
            try store.save(edited)
        }
        let reopened = try KnowledgeStore(url: url)
        try check(try reopened.schemaVersion() == 3, "reopened migration version")
        try check(try reopened.foreignKeyViolations() == 0, "reopened foreign keys")
        try check(try reopened.claim(id: "c")?.status == .verified, "claim lifecycle persisted")
        try check(try reopened.relationships().first?.supportingClaimID == "c", "reopened relationship")
    }
    static func repositoryAndSearch() throws {
        let url = temporaryURL(); defer { try? FileManager.default.removeItem(at: url) }
        do {
            let store = try KnowledgeStore(url: url)
            try check(try store.schemaVersion() == 3, "fresh schema")
            try check(try store.foreignKeyViolations() == 0, "fresh foreign keys")
            try store.seedIfEmpty()
            let initial = try store.records().count
            try store.seedIfEmpty()
            try check(try store.records().count == initial, "seed idempotence")
            for kind in RecordKind.allCases { try check(!(try store.records(kind: kind)).isEmpty, "seed \(kind)") }
            let material = try store.records(kind: .material)[0]
            let source = try store.records(kind: .source)[0]
            try check(!(try store.claims(subjectID: material.id)).isEmpty, "seed claims")
            try check(!(try store.relationships(recordID: material.id)).isEmpty, "seed edges")
            let trial = KnowledgeRecord(kind: .material, name: "Alloy 725 H2S trial", detail: "hydrogen sour-service")
            try store.save(trial)
            try check(try store.search("hyd", entityTypes: [.record]).contains { $0.id == trial.id }, "prefix search")
            try check(try store.search("hydrogen", entityTypes: [.record]).contains { $0.id == trial.id }, "exact search")
            try check(!(try store.search("hydrogen", entityTypes: [.record], recordKind: .standard).contains { $0.id == trial.id }), "record-kind filter")
            try check(try store.search("725 hydrogen", entityTypes: [.record]).contains { $0.id == trial.id }, "multiple terms")
            try check(try store.search("725 hydrogen H2S").contains { $0.id == trial.id }, "engineering query")
            try check(try store.search("725 hydrogen H2S", entityTypes: [.record]).contains { $0.id == "demo:standard:iso-15156" }, "related standard recall")
            try check(try store.search("725 hydrogen H2S", entityTypes: [.record]).contains { $0.id == source.id }, "linked source recall")
            try check(try store.search("\"hyd* (??) H2S").contains { $0.id == trial.id }, "safe special input")
            var edited = trial; edited.name = "Alloy 926"
            try store.save(edited)
            try check(!(try store.search("725", entityTypes: [.record]).contains { $0.id == trial.id }), "record reindex")
            let claim = EngineeringClaim(subjectID: trial.id, predicate: "test", statement: "Hydrogen claim", sourceID: source.id, locator: "p. 3")
            try store.save(claim)
            try check(try store.search("hydrogen", entityTypes: [.claim]).contains { $0.id == claim.id }, "claim indexed")
            var reviewed = claim; reviewed.status = .reviewed; reviewed.statement = "Revised claim"
            try store.save(reviewed)
            try check(!(try store.search("hydrogen", entityTypes: [.claim]).contains { $0.id == claim.id }), "claim reindex")
            try check(try store.search("revised", entityTypes: [.claim], verificationStatus: .reviewed).contains { $0.id == claim.id }, "claim status filter")
            let link = KnowledgeRelationship(fromID: trial.id, predicate: "related_to", toID: material.id, supportingClaimID: claim.id)
            try store.save(link)
            try check(try store.relationships(recordID: trial.id).contains { $0.id == link.id }, "edge created")
            try check(try store.search("926", entityTypes: [.record]).contains { $0.id == material.id }, "relationship context indexed")
            do { try store.deleteRecord(id: trial.id); throw KnowledgeStoreError(message: "missing record restriction") } catch let error as KnowledgeStoreError where error.message == "missing record restriction" { throw error } catch {}
            do { try store.deleteClaim(id: claim.id); throw KnowledgeStoreError(message: "missing claim restriction") } catch let error as KnowledgeStoreError where error.message == "missing claim restriction" { throw error } catch {}
            do { try store.save(KnowledgeRecord(kind: .material, name: material.name)); throw KnowledgeStoreError(message: "missing duplicate restriction") } catch let error as KnowledgeStoreError where error.message == "missing duplicate restriction" { throw error } catch {}
            do { try store.save(EngineeringClaim(subjectID: trial.id, predicate: "bad", statement: "Bad", sourceID: material.id)); throw KnowledgeStoreError(message: "missing source restriction") } catch let error as KnowledgeStoreError where error.message == "missing source restriction" { throw error } catch {}
            var archived = reviewed; archived.status = .archived
            try store.save(archived)
            try check(!(try store.search("revised", entityTypes: [.claim]).contains { $0.id == claim.id }), "archived claim excluded")
            try store.deleteRelationship(id: link.id)
            try check(!(try store.search("926", entityTypes: [.record]).contains { $0.id == material.id }), "relationship removal reindexed")
            try store.deleteClaim(id: claim.id)
            try store.deleteRecord(id: trial.id)
            try check(try store.record(id: trial.id) == nil, "record delete")
            try check(!(try store.search("926").contains { $0.id == trial.id }), "deleted record excluded")
            let document = LibraryDocument(title: "NACE H2S Guidance", organization: "NACE", revisionYear: "2026", sourceType: "standard", notes: "Hydrogen service", fileName: "guidance.pdf", bookmark: "")
            try store.save(document, recordIDs: [material.id])
            try check(try store.recordIDs(documentID: document.id) == [material.id], "document association")
            try check(try store.search("NACE hydrogen", entityTypes: [.document]).contains { $0.id == document.id }, "document search")
            var updatedDocument = document; updatedDocument.title = "Updated H2S guidance"
            try store.save(updatedDocument, recordIDs: [source.id])
            try check(try store.recordIDs(documentID: document.id) == [source.id], "document association edit")
            try check(try store.search("updated", entityTypes: [.document]).contains { $0.id == document.id }, "document metadata reindex")
            var changed = updatedDocument; changed.title = "Revised guidance"
            do { try store.save(changed, recordIDs: ["missing-record"]); throw KnowledgeStoreError(message: "missing document rollback") } catch let error as KnowledgeStoreError where error.message == "missing document rollback" { throw error } catch {}
            try check(try store.documents().first { $0.id == document.id }?.title == updatedDocument.title, "document update rollback")
            try check(try store.recordIDs(documentID: document.id) == [source.id], "association rollback")
            try check(!(try store.search("revised", entityTypes: [.document]).contains { $0.id == document.id }), "search rollback")
            try store.deleteDocument(id: document.id)
            try check(!(try store.search("NACE", entityTypes: [.document]).contains { $0.id == document.id }), "document delete index")
            try check(try store.foreignKeyViolations() == 0, "repository foreign keys")
        }
        let reopened = try KnowledgeStore(url: url)
        try check(try reopened.records(kind: .material).contains { $0.id == "demo:material:alloy-725" }, "persistence after reopen")
    }
    static func atomicSearchFailure() throws {
        let url = temporaryURL(); defer { try? FileManager.default.removeItem(at: url) }
        let store = try KnowledgeStore(url: url)
        let from = KnowledgeRecord(kind: .material, name: "Atomic from")
        let to = KnowledgeRecord(kind: .standard, name: "Atomic to")
        try store.save(from); try store.save(to)
        let link = KnowledgeRelationship(fromID: from.id, predicate: "related_to", toID: to.id)
        try store.save(link)
        try withRawDatabase(url) { db in try sql(db, "DROP TABLE search_index") }
        let record = KnowledgeRecord(kind: .material, name: "Must roll back")
        do { try store.save(record); throw KnowledgeStoreError(message: "missing FTS rollback") } catch let error as KnowledgeStoreError where error.message == "missing FTS rollback" { throw error } catch {}
        try check(try store.record(id: record.id) == nil, "record rolled back on FTS failure")
        do { try store.deleteRelationship(id: link.id); throw KnowledgeStoreError(message: "missing relationship FTS rollback") } catch let error as KnowledgeStoreError where error.message == "missing relationship FTS rollback" { throw error } catch {}
        try check(try store.relationships().contains { $0.id == link.id }, "relationship rolled back on FTS failure")
    }
    static func realBookmarkPersistence() throws {
        let databaseURL = temporaryURL()
        let fileURL = FileManager.default.temporaryDirectory.appending(path: "materials-document-\(UUID().uuidString).txt")
        let movedURL = fileURL.deletingLastPathComponent().appending(path: "moved-\(fileURL.lastPathComponent)")
        defer {
            try? FileManager.default.removeItem(at: databaseURL)
            try? FileManager.default.removeItem(at: fileURL)
            try? FileManager.default.removeItem(at: movedURL)
        }
        try Data("Actual local document".utf8).write(to: fileURL)
        let bookmark = try fileURL.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil).base64EncodedString()
        let document = LibraryDocument(title: "Real bookmark fixture", fileName: fileURL.lastPathComponent, bookmark: bookmark)
        do {
            let store = try KnowledgeStore(url: databaseURL)
            let record = KnowledgeRecord(kind: .material, name: "Bookmark linked material")
            try store.save(record)
            try store.save(document, recordIDs: [record.id])
        }
        let reopened = try KnowledgeStore(url: databaseURL)
        let stored = try reopened.documents().first { $0.id == document.id }
        try check(stored?.bookmark == bookmark, "real bookmark persisted")
        let data = Data(base64Encoded: stored!.bookmark)!
        var stale = false
        let resolved = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale)
        let scoped = resolved.startAccessingSecurityScopedResource()
        defer { if scoped { resolved.stopAccessingSecurityScopedResource() } }
        try check(scoped && !stale && FileManager.default.isReadableFile(atPath: resolved.path), "real bookmark restored")
        try FileManager.default.moveItem(at: fileURL, to: movedURL)
        try check(!FileManager.default.fileExists(atPath: resolved.path), "moved file detected")
        try check(try reopened.documents().contains { $0.id == document.id }, "metadata survives moved file")
        try check(try reopened.recordIDs(documentID: document.id).count == 1, "association survives moved file")
    }
    static func main() throws {
        try migration()
        try repositoryAndSearch()
        try atomicSearchFailure()
        try realBookmarkPersistence()
        print("KnowledgeStore tests passed")
    }
}
