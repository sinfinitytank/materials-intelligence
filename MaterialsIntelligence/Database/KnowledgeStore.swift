import Foundation
import SQLite3

struct KnowledgeStoreError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class KnowledgeStore {
    private var db: OpaquePointer?
    static func applicationURL() throws -> URL {
        let folder = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: "MaterialsIntelligence")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: "knowledge.sqlite")
    }
    init(url: URL) throws {
        if sqlite3_open(url.path, &db) != SQLITE_OK { throw KnowledgeStoreError(message: "Cannot open database") }
        do { try execute("PRAGMA foreign_keys = ON"); try migrate() } catch { sqlite3_close(db); db = nil; throw error }
    }
    deinit { sqlite3_close(db) }
    private func execute(_ sql: String, _ values: [String?] = []) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { throw error() }
        defer { sqlite3_finalize(statement) }
        try bind(values, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else { throw error() }
    }
    private func query(_ sql: String, _ values: [String?] = [], map: (OpaquePointer?) -> Void) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { throw error() }
        defer { sqlite3_finalize(statement) }
        try bind(values, to: statement)
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { return }
            guard result == SQLITE_ROW else { throw error() }
            map(statement)
        }
    }
    private func bind(_ values: [String?], to statement: OpaquePointer?) throws {
        for (index, value) in values.enumerated() {
            let result: Int32
            if let value { result = value.withCString { sqlite3_bind_text(statement, Int32(index + 1), $0, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) } }
            else { result = sqlite3_bind_null(statement, Int32(index + 1)) }
            guard result == SQLITE_OK else { throw error() }
        }
    }
    private func error() -> KnowledgeStoreError { KnowledgeStoreError(message: String(cString: sqlite3_errmsg(db))) }
    private func text(_ statement: OpaquePointer?, _ column: Int32) -> String { sqlite3_column_text(statement, column).map { String(cString: $0) } ?? "" }
    private func optionalText(_ statement: OpaquePointer?, _ column: Int32) -> String? { sqlite3_column_type(statement, column) == SQLITE_NULL ? nil : text(statement, column) }
    func schemaVersion() throws -> Int {
        var version = 0
        try query("PRAGMA user_version") { version = Int(sqlite3_column_int($0, 0)) }
        return version
    }
    private func migrate() throws {
        let version = try schemaVersion()
        guard version <= 1 else { throw KnowledgeStoreError(message: "Database schema is newer than this app") }
        if version == 0 {
            try execute("BEGIN IMMEDIATE")
            do {
                try execute("CREATE TABLE records (id TEXT PRIMARY KEY, kind TEXT NOT NULL CHECK(kind IN ('material','mechanism','standard','component','source')), name TEXT NOT NULL COLLATE NOCASE, detail TEXT NOT NULL DEFAULT '', secondary TEXT NOT NULL DEFAULT '', UNIQUE(kind, name))")
                try execute("CREATE TABLE claims (id TEXT PRIMARY KEY, subject_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, predicate TEXT NOT NULL, statement TEXT NOT NULL, conditions TEXT NOT NULL DEFAULT '', source_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, locator TEXT NOT NULL DEFAULT '', status TEXT NOT NULL CHECK(status IN ('unverified','reviewed','verified')), evidence_level TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, modified_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)")
                try execute("CREATE TABLE relationships (id TEXT PRIMARY KEY, from_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, predicate TEXT NOT NULL, to_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, supporting_claim_id TEXT REFERENCES claims(id) ON DELETE RESTRICT, CHECK(from_id <> to_id), UNIQUE(from_id, predicate, to_id))")
                try execute("CREATE INDEX claims_subject_idx ON claims(subject_id)")
                try execute("CREATE INDEX claims_source_idx ON claims(source_id)")
                try execute("CREATE INDEX relationships_from_idx ON relationships(from_id)")
                try execute("CREATE INDEX relationships_to_idx ON relationships(to_id)")
                try execute("CREATE TRIGGER claims_source_kind_insert BEFORE INSERT ON claims WHEN (SELECT kind FROM records WHERE id = NEW.source_id) != 'source' BEGIN SELECT RAISE(ABORT, 'claim source must be a source record'); END")
                try execute("CREATE TRIGGER claims_source_kind_update BEFORE UPDATE OF source_id ON claims WHEN (SELECT kind FROM records WHERE id = NEW.source_id) != 'source' BEGIN SELECT RAISE(ABORT, 'claim source must be a source record'); END")
                try execute("CREATE TRIGGER claims_modified AFTER UPDATE ON claims BEGIN UPDATE claims SET modified_at = CURRENT_TIMESTAMP WHERE id = NEW.id; END")
                try execute("PRAGMA user_version = 1")
                try execute("COMMIT")
            } catch { try? execute("ROLLBACK"); throw error }
        }
    }
    func save(_ record: KnowledgeRecord) throws {
        try execute("INSERT INTO records(id,kind,name,detail,secondary) VALUES(?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name, detail=excluded.detail, secondary=excluded.secondary WHERE kind=excluded.kind", [record.id, record.kind.rawValue, record.name, record.detail, record.secondary])
    }
    func records(kind: RecordKind? = nil) throws -> [KnowledgeRecord] {
        var rows: [KnowledgeRecord] = []
        try query("SELECT id,kind,name,detail,secondary FROM records WHERE (? IS NULL OR kind=?) ORDER BY name", [kind?.rawValue, kind?.rawValue]) { s in
            if let kind = RecordKind(rawValue: text(s,1)) { rows.append(KnowledgeRecord(id: text(s,0), kind: kind, name: text(s,2), detail: text(s,3), secondary: text(s,4))) }
        }
        return rows
    }
    func record(id: String) throws -> KnowledgeRecord? { try records().first { $0.id == id } }
    func deleteRecord(id: String) throws { try execute("DELETE FROM records WHERE id=?", [id]) }
    func save(_ claim: EngineeringClaim) throws {
        try execute("INSERT INTO claims(id,subject_id,predicate,statement,conditions,source_id,locator,status,evidence_level,notes) VALUES(?,?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET subject_id=excluded.subject_id,predicate=excluded.predicate,statement=excluded.statement,conditions=excluded.conditions,source_id=excluded.source_id,locator=excluded.locator,status=excluded.status,evidence_level=excluded.evidence_level,notes=excluded.notes", [claim.id,claim.subjectID,claim.predicate,claim.statement,claim.conditions,claim.sourceID,claim.locator,claim.status.rawValue,claim.evidenceLevel,claim.notes])
    }
    func claims(subjectID: String? = nil) throws -> [EngineeringClaim] {
        var rows: [EngineeringClaim] = []
        try query("SELECT id,subject_id,predicate,statement,conditions,source_id,locator,status,evidence_level,notes FROM claims WHERE (? IS NULL OR subject_id=?) ORDER BY id", [subjectID,subjectID]) { s in
            rows.append(EngineeringClaim(id: text(s,0), subjectID: text(s,1), predicate: text(s,2), statement: text(s,3), conditions: text(s,4), sourceID: text(s,5), locator: text(s,6), status: VerificationStatus(rawValue: text(s,7)) ?? .unverified, evidenceLevel: text(s,8), notes: text(s,9)))
        }
        return rows
    }
    func deleteClaim(id: String) throws { try execute("DELETE FROM claims WHERE id=?", [id]) }
    func save(_ relationship: KnowledgeRelationship) throws {
        try execute("INSERT INTO relationships(id,from_id,predicate,to_id,supporting_claim_id) VALUES(?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET from_id=excluded.from_id,predicate=excluded.predicate,to_id=excluded.to_id,supporting_claim_id=excluded.supporting_claim_id", [relationship.id,relationship.fromID,relationship.predicate,relationship.toID,relationship.supportingClaimID])
    }
    func relationships(recordID: String? = nil) throws -> [KnowledgeRelationship] {
        var rows: [KnowledgeRelationship] = []
        try query("SELECT id,from_id,predicate,to_id,supporting_claim_id FROM relationships WHERE (? IS NULL OR from_id=? OR to_id=?) ORDER BY predicate", [recordID,recordID,recordID]) { s in
            rows.append(KnowledgeRelationship(id: text(s,0), fromID: text(s,1), predicate: text(s,2), toID: text(s,3), supportingClaimID: optionalText(s,4)))
        }
        return rows
    }
    func deleteRelationship(id: String) throws { try execute("DELETE FROM relationships WHERE id=?", [id]) }
    func seedIfEmpty() throws {
        guard try records().isEmpty else { return }
        let material = KnowledgeRecord(id: "demo:material:alloy-725", kind: .material, name: "Alloy 725", detail: "Nickel alloy", secondary: "UNS N07725")
        let mechanism = KnowledgeRecord(id: "demo:mechanism:hydrogen-embrittlement", kind: .mechanism, name: "Hydrogen Embrittlement", detail: "Hydrogen-related damage")
        let standard = KnowledgeRecord(id: "demo:standard:iso-15156", kind: .standard, name: "ISO 15156", detail: "Sour-service materials standard")
        let component = KnowledgeRecord(id: "demo:component:tubing", kind: .component, name: "Tubing", detail: "Well tubular")
        let source = KnowledgeRecord(id: "demo:source:illustrative", kind: .source, name: "Illustrative Phase 2 sample", detail: "Development-only example; no verified engineering source", secondary: "demo")
        try execute("BEGIN IMMEDIATE")
        do {
            for record in [material,mechanism,standard,component,source] { try save(record) }
            let claim1 = EngineeringClaim(id: "demo:claim:725-he", subjectID: material.id, predicate: "susceptibility_example", statement: "Example link between Alloy 725 and hydrogen embrittlement; requires source verification before engineering use.", sourceID: source.id, status: .unverified)
            let claim2 = EngineeringClaim(id: "demo:claim:he-15156", subjectID: mechanism.id, predicate: "standard_context_example", statement: "Example link between hydrogen-related damage and ISO 15156; applicability requires review.", sourceID: source.id, status: .unverified)
            try save(claim1); try save(claim2)
            try save(KnowledgeRelationship(id: "demo:relationship:725-he", fromID: material.id, predicate: "susceptible_to", toID: mechanism.id, supportingClaimID: claim1.id))
            try save(KnowledgeRelationship(id: "demo:relationship:he-15156", fromID: mechanism.id, predicate: "governed_by", toID: standard.id, supportingClaimID: claim2.id))
            try save(KnowledgeRelationship(id: "demo:relationship:tubing-725", fromID: component.id, predicate: "commonly_uses", toID: material.id))
            try execute("COMMIT")
        } catch { try? execute("ROLLBACK"); throw error }
    }
}
