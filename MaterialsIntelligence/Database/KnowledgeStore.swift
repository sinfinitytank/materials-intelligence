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
    private func transaction(_ work: () throws -> Void) throws {
        // Savepoints also work when seed data is inserted inside its own transaction.
        try execute("SAVEPOINT knowledge_write")
        do {
            try work()
            try execute("RELEASE SAVEPOINT knowledge_write")
        } catch {
            try? execute("ROLLBACK TO SAVEPOINT knowledge_write")
            try? execute("RELEASE SAVEPOINT knowledge_write")
            throw error
        }
    }
    func foreignKeyViolations() throws -> Int {
        var count = 0
        try query("PRAGMA foreign_key_check") { _ in count += 1 }
        return count
    }
    func schemaVersion() throws -> Int {
        var version = 0
        try query("PRAGMA user_version") { version = Int(sqlite3_column_int($0, 0)) }
        return version
    }
    private func migrate() throws {
        let version = try schemaVersion()
        guard version <= 3 else { throw KnowledgeStoreError(message: "Database schema is newer than this app") }
        if version == 0 {
            try execute("BEGIN IMMEDIATE")
            do {
                try execute("CREATE TABLE records (id TEXT PRIMARY KEY, kind TEXT NOT NULL CHECK(kind IN ('material','mechanism','standard','component','source')), name TEXT NOT NULL COLLATE NOCASE, detail TEXT NOT NULL DEFAULT '', secondary TEXT NOT NULL DEFAULT '', UNIQUE(kind, name))")
                try execute("CREATE TABLE claims (id TEXT PRIMARY KEY, subject_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, predicate TEXT NOT NULL, statement TEXT NOT NULL, conditions TEXT NOT NULL DEFAULT '', source_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, locator TEXT NOT NULL DEFAULT '', status TEXT NOT NULL CHECK(status IN ('draft','unverified','reviewed','verified','superseded','archived')), evidence_level TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, modified_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)")
                try execute("CREATE TABLE relationships (id TEXT PRIMARY KEY, from_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, predicate TEXT NOT NULL, to_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, supporting_claim_id TEXT REFERENCES claims(id) ON DELETE RESTRICT, CHECK(from_id <> to_id), UNIQUE(from_id, predicate, to_id))")
                try execute("CREATE INDEX claims_subject_idx ON claims(subject_id)")
                try execute("CREATE INDEX claims_source_idx ON claims(source_id)")
                try execute("CREATE INDEX relationships_from_idx ON relationships(from_id)")
                try execute("CREATE INDEX relationships_to_idx ON relationships(to_id)")
                try execute("CREATE TRIGGER claims_source_kind_insert BEFORE INSERT ON claims WHEN (SELECT kind FROM records WHERE id = NEW.source_id) != 'source' BEGIN SELECT RAISE(ABORT, 'claim source must be a source record'); END")
                try execute("CREATE TRIGGER claims_source_kind_update BEFORE UPDATE OF source_id ON claims WHEN (SELECT kind FROM records WHERE id = NEW.source_id) != 'source' BEGIN SELECT RAISE(ABORT, 'claim source must be a source record'); END")
                try execute("CREATE TRIGGER claims_modified AFTER UPDATE ON claims BEGIN UPDATE claims SET modified_at = CURRENT_TIMESTAMP WHERE id = NEW.id; END")
                try execute("PRAGMA user_version = 2")
                try execute("COMMIT")
            } catch { try? execute("ROLLBACK"); throw error }
        }
        if version == 1 {
            try execute("BEGIN IMMEDIATE")
            do {
                try execute("CREATE TABLE claims_v2 (id TEXT PRIMARY KEY, subject_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, predicate TEXT NOT NULL, statement TEXT NOT NULL, conditions TEXT NOT NULL DEFAULT '', source_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, locator TEXT NOT NULL DEFAULT '', status TEXT NOT NULL CHECK(status IN ('draft','unverified','reviewed','verified','superseded','archived')), evidence_level TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, modified_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)")
                try execute("INSERT INTO claims_v2 SELECT * FROM claims")
                // Rebuild dependent edges first. RESTRICT disallows dropping a cited claim,
                // even during an explicit transaction with foreign keys enabled.
                try execute("CREATE TABLE relationships_v2 (id TEXT PRIMARY KEY, from_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, predicate TEXT NOT NULL, to_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, supporting_claim_id TEXT REFERENCES claims_v2(id) ON DELETE RESTRICT, CHECK(from_id <> to_id), UNIQUE(from_id, predicate, to_id))")
                try execute("INSERT INTO relationships_v2 SELECT * FROM relationships")
                try execute("DROP TABLE relationships")
                try execute("DROP TABLE claims")
                try execute("ALTER TABLE claims_v2 RENAME TO claims")
                try execute("ALTER TABLE relationships_v2 RENAME TO relationships")
                try execute("CREATE INDEX claims_subject_idx ON claims(subject_id)")
                try execute("CREATE INDEX claims_source_idx ON claims(source_id)")
                try execute("CREATE INDEX relationships_from_idx ON relationships(from_id)")
                try execute("CREATE INDEX relationships_to_idx ON relationships(to_id)")
                try execute("CREATE TRIGGER claims_source_kind_insert BEFORE INSERT ON claims WHEN (SELECT kind FROM records WHERE id = NEW.source_id) != 'source' BEGIN SELECT RAISE(ABORT, 'claim source must be a source record'); END")
                try execute("CREATE TRIGGER claims_source_kind_update BEFORE UPDATE OF source_id ON claims WHEN (SELECT kind FROM records WHERE id = NEW.source_id) != 'source' BEGIN SELECT RAISE(ABORT, 'claim source must be a source record'); END")
                try execute("CREATE TRIGGER claims_modified AFTER UPDATE ON claims BEGIN UPDATE claims SET modified_at = CURRENT_TIMESTAMP WHERE id = NEW.id; END")
                try execute("PRAGMA user_version = 2")
                guard try foreignKeyViolations() == 0 else { throw KnowledgeStoreError(message: "Foreign-key violations after claim migration") }
                try execute("COMMIT")
            } catch { try? execute("ROLLBACK"); throw error }
        }
        if version <= 2 {
            try execute("BEGIN IMMEDIATE")
            do {
                try execute("CREATE TABLE documents (id TEXT PRIMARY KEY, title TEXT NOT NULL, organization TEXT NOT NULL DEFAULT '', revision_year TEXT NOT NULL DEFAULT '', source_type TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', file_name TEXT NOT NULL DEFAULT '', bookmark TEXT NOT NULL DEFAULT '', added_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, modified_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)")
                try execute("CREATE TABLE document_records (document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE, record_id TEXT NOT NULL REFERENCES records(id) ON DELETE RESTRICT, PRIMARY KEY(document_id, record_id))")
                try execute("CREATE INDEX document_records_record_idx ON document_records(record_id)")
                try execute("CREATE VIRTUAL TABLE search_index USING fts5(entity_id UNINDEXED, entity_type UNINDEXED, title, body, kind UNINDEXED, tokenize='unicode61')")
                try execute("PRAGMA user_version = 3")
                try rebuildSearchIndex()
                try execute("COMMIT")
            } catch { try? execute("ROLLBACK"); throw error }
        }
    }
    func save(_ record: KnowledgeRecord) throws {
        try transaction {
            try execute("INSERT INTO records(id,kind,name,detail,secondary) VALUES(?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name, detail=excluded.detail, secondary=excluded.secondary WHERE kind=excluded.kind", [record.id, record.kind.rawValue, record.name, record.detail, record.secondary])
            try rebuildSearchIndex()
        }
    }
    func records(kind: RecordKind? = nil) throws -> [KnowledgeRecord] {
        var rows: [KnowledgeRecord] = []
        try query("SELECT id,kind,name,detail,secondary FROM records WHERE (? IS NULL OR kind=?) ORDER BY name", [kind?.rawValue, kind?.rawValue]) { s in
            if let kind = RecordKind(rawValue: text(s,1)) { rows.append(KnowledgeRecord(id: text(s,0), kind: kind, name: text(s,2), detail: text(s,3), secondary: text(s,4))) }
        }
        return rows
    }
    func record(id: String) throws -> KnowledgeRecord? { try records().first { $0.id == id } }
    func deleteRecord(id: String) throws { try transaction { try execute("DELETE FROM records WHERE id=?", [id]); try rebuildSearchIndex() } }
    func save(_ claim: EngineeringClaim) throws {
        try transaction {
            try execute("INSERT INTO claims(id,subject_id,predicate,statement,conditions,source_id,locator,status,evidence_level,notes) VALUES(?,?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET subject_id=excluded.subject_id,predicate=excluded.predicate,statement=excluded.statement,conditions=excluded.conditions,source_id=excluded.source_id,locator=excluded.locator,status=excluded.status,evidence_level=excluded.evidence_level,notes=excluded.notes", [claim.id,claim.subjectID,claim.predicate,claim.statement,claim.conditions,claim.sourceID,claim.locator,claim.status.rawValue,claim.evidenceLevel,claim.notes])
            try rebuildSearchIndex()
        }
    }
    func claims(subjectID: String? = nil) throws -> [EngineeringClaim] {
        var rows: [EngineeringClaim] = []
        try query("SELECT id,subject_id,predicate,statement,conditions,source_id,locator,status,evidence_level,notes FROM claims WHERE (? IS NULL OR subject_id=?) ORDER BY modified_at DESC", [subjectID,subjectID]) { s in
            rows.append(EngineeringClaim(id: text(s,0), subjectID: text(s,1), predicate: text(s,2), statement: text(s,3), conditions: text(s,4), sourceID: text(s,5), locator: text(s,6), status: VerificationStatus(rawValue: text(s,7)) ?? .unverified, evidenceLevel: text(s,8), notes: text(s,9)))
        }
        return rows
    }
    func deleteClaim(id: String) throws { try transaction { try execute("DELETE FROM claims WHERE id=?", [id]); try rebuildSearchIndex() } }
    func claim(id: String) throws -> EngineeringClaim? { try claims().first { $0.id == id } }
    func save(_ relationship: KnowledgeRelationship) throws {
        try transaction {
            try execute("INSERT INTO relationships(id,from_id,predicate,to_id,supporting_claim_id) VALUES(?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET from_id=excluded.from_id,predicate=excluded.predicate,to_id=excluded.to_id,supporting_claim_id=excluded.supporting_claim_id", [relationship.id,relationship.fromID,relationship.predicate,relationship.toID,relationship.supportingClaimID])
            try rebuildSearchIndex()
        }
    }
    func relationships(recordID: String? = nil) throws -> [KnowledgeRelationship] {
        var rows: [KnowledgeRelationship] = []
        try query("SELECT id,from_id,predicate,to_id,supporting_claim_id FROM relationships WHERE (? IS NULL OR from_id=? OR to_id=?) ORDER BY predicate", [recordID,recordID,recordID]) { s in
            rows.append(KnowledgeRelationship(id: text(s,0), fromID: text(s,1), predicate: text(s,2), toID: text(s,3), supportingClaimID: optionalText(s,4)))
        }
        return rows
    }
    func deleteRelationship(id: String) throws { try transaction { try execute("DELETE FROM relationships WHERE id=?", [id]); try rebuildSearchIndex() } }
    func save(_ document: LibraryDocument, recordIDs: [String]) throws {
        try transaction {
            try execute("INSERT INTO documents(id,title,organization,revision_year,source_type,notes,file_name,bookmark) VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET title=excluded.title,organization=excluded.organization,revision_year=excluded.revision_year,source_type=excluded.source_type,notes=excluded.notes,file_name=excluded.file_name,bookmark=excluded.bookmark,modified_at=CURRENT_TIMESTAMP", [document.id,document.title,document.organization,document.revisionYear,document.sourceType,document.notes,document.fileName,document.bookmark])
            try execute("DELETE FROM document_records WHERE document_id=?", [document.id])
            for recordID in Set(recordIDs) { try execute("INSERT INTO document_records(document_id,record_id) VALUES(?,?)", [document.id,recordID]) }
            try rebuildSearchIndex()
        }
    }
    func documents() throws -> [LibraryDocument] {
        var rows:[LibraryDocument]=[]
        try query("SELECT id,title,organization,revision_year,source_type,notes,file_name,bookmark,added_at FROM documents ORDER BY added_at DESC", []) { s in rows.append(LibraryDocument(id:text(s,0),title:text(s,1),organization:text(s,2),revisionYear:text(s,3),sourceType:text(s,4),notes:text(s,5),fileName:text(s,6),bookmark:text(s,7),addedAt:text(s,8))) }
        return rows
    }
    func recordIDs(documentID: String) throws -> [String] { var ids:[String]=[]; try query("SELECT record_id FROM document_records WHERE document_id=?", [documentID]) { ids.append(text($0,0)) }; return ids }
    func deleteDocument(id: String) throws { try transaction { try execute("DELETE FROM documents WHERE id=?", [id]); try rebuildSearchIndex() } }
    func search(_ queryText: String, entityTypes: Set<SearchEntityType> = Set(SearchEntityType.allCases), recordKind: RecordKind? = nil, verificationStatus: VerificationStatus? = nil) throws -> [SearchResult] {
        // FTS5 requires the prefix operator outside the quoted token: "hyd"*.
        // Splitting to unicode words also makes punctuation and quotes harmless.
        let terms = queryText.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map { "\"\($0)\"*" }.joined(separator: " OR ")
        guard !terms.isEmpty else { return [] }
        var rows:[SearchResult]=[]
        try query("SELECT entity_id,entity_type,title,body,kind,bm25(search_index) FROM search_index WHERE search_index MATCH ? ORDER BY bm25(search_index), title COLLATE NOCASE", [terms]) { s in
            guard let type=SearchEntityType(rawValue:text(s,1)), entityTypes.contains(type) else{return}
            let kind=text(s,4)
            if let recordKind, type == .record, kind != recordKind.rawValue { return }
            if let verificationStatus, type == .claim, kind != verificationStatus.rawValue { return }
            rows.append(SearchResult(id:text(s,0),entityType:type,title:text(s,2),detail:text(s,3),kind:kind,score:sqlite3_column_double(s,5)))
        }; return rows
    }
    private func rebuildSearchIndex() throws {
        try execute("DELETE FROM search_index")
        try execute("""
            INSERT INTO search_index(entity_id,entity_type,title,body,kind)
            SELECT r.id,'record',r.name,
                r.detail || ' ' || r.secondary || ' ' ||
                COALESCE((SELECT group_concat(other.name || ' ' || rel.predicate, ' ')
                          FROM relationships rel
                          JOIN records other ON other.id = CASE WHEN rel.from_id = r.id THEN rel.to_id ELSE rel.from_id END
                          WHERE rel.from_id = r.id OR rel.to_id = r.id), '') || ' ' ||
                COALESCE((SELECT group_concat(c.statement || ' ' || subject.name || ' ' || src.name || ' ' || c.conditions, ' ')
                          FROM claims c
                          JOIN records subject ON subject.id = c.subject_id
                          JOIN records src ON src.id = c.source_id
                          WHERE (c.subject_id = r.id OR c.source_id = r.id) AND c.status != 'archived'), ''),
                r.kind
            FROM records r
            """)
        try execute("INSERT INTO search_index(entity_id,entity_type,title,body,kind) SELECT c.id,'claim',c.statement,c.predicate || ' ' || c.conditions || ' ' || c.locator || ' ' || c.evidence_level || ' ' || c.notes || ' ' || r.name || ' ' || src.name,c.status FROM claims c JOIN records r ON r.id=c.subject_id JOIN records src ON src.id=c.source_id WHERE c.status != 'archived'")
        try execute("INSERT INTO search_index(entity_id,entity_type,title,body,kind) SELECT id,'document',title,organization || ' ' || revision_year || ' ' || source_type || ' ' || notes || ' ' || file_name,source_type FROM documents")
    }
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
