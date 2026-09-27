import Foundation
struct VaultSnapshot: Codable {
    let version: Int
    let records: [KnowledgeRecord]
    let claims: [EngineeringClaim]
    let relationships: [KnowledgeRelationship]
    let documents: [LibraryDocument]
    let documentLinks: [String: [String]]
    let research: [ResearchSession]
    init(store: KnowledgeStore) throws {
        version = 1
        records = try store.records().sorted { $0.id < $1.id }
        claims = try store.claims().sorted { $0.id < $1.id }
        relationships = try store.relationships().sorted { $0.id < $1.id }
        documents = try store.documents().sorted { $0.id < $1.id }.map { var d = $0; d.bookmark = ""; return d }
        var links: [String: [String]] = [:]
        for d in documents { links[d.id] = try store.recordIDs(documentID: d.id).sorted() }
        documentLinks = links
        research = try store.researchSessions().sorted { $0.id < $1.id }
    }
    func encoded() throws -> Data { let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]; return try encoder.encode(self) }
    static func decode(_ data: Data) throws -> Self {
        guard data.count <= 20_000_000 else { throw KnowledgeStoreError(message: "Vault exceeds 20 MB sync limit") }
        let value = try JSONDecoder().decode(Self.self, from: data); try value.validate(); return value
    }
    func validate() throws {
        func require(_ value: Bool, _ message: String) throws { if !value { throw KnowledgeStoreError(message: message) } }
        try require(version == 1, "Unsupported sync data version")
        try require(records.count <= 10000 && claims.count <= 20000 && relationships.count <= 30000, "Vault exceeds supported sync size")
        try require(Set(records.map(\.id)).count == records.count && Set(claims.map(\.id)).count == claims.count && Set(relationships.map(\.id)).count == relationships.count && Set(documents.map(\.id)).count == documents.count && Set(research.map(\.id)).count == research.count, "Duplicate identities in sync data")
        let ids = Set(records.map(\.id)), sources = Set(records.filter { $0.kind == .source }.map(\.id)), claimIDs = Set(claims.map(\.id))
        for claim in claims { try require(ids.contains(claim.subjectID) && sources.contains(claim.sourceID), "Broken claim provenance") }
        for edge in relationships { try require(ids.contains(edge.fromID) && ids.contains(edge.toID) && edge.fromID != edge.toID && (edge.supportingClaimID == nil || claimIDs.contains(edge.supportingClaimID!)), "Broken relationship provenance") }
        for document in documents { try require(document.bookmark.isEmpty && (documentLinks[document.id] ?? []).allSatisfy { ids.contains($0) }, "Device bookmark or broken document association in sync data") }
        for session in research {
            try session.package.validate()
            let original = try JSONDecoder().decode(ResearchPackage.self, from: Data(session.originalJSON.utf8))
            try require(session.package.boundary == "publicPersonal" && original.boundary == "publicPersonal", "Restricted research cannot leave this device")
        }
        try require(try encoded().count <= 20_000_000, "Vault exceeds 20 MB sync limit")
    }
    func reviewCompared(to local: VaultSnapshot) throws -> String {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let old = Set(local.records.map(\.id)), new = Set(records.map(\.id))
        return "Remote records: \(records.count); claims: \(claims.count); relationships: \(relationships.count)\nRecords removed: \(old.subtracting(new).count); added: \(new.subtracting(old).count)\nReview the complete incoming content before replacing this personal vault. Claims, including Verified claims, may change or be removed. Local content remains saved as a recovery snapshot.\n\n" + String(decoding: try encoder.encode(self), as: UTF8.self)
    }
}
enum SyncDecision: Equatable { case unchanged, upload, download, conflict }
struct VaultReconciliation {
    static func decision(local: Data, remote: Data?, base: Data?) -> SyncDecision {
        guard let remote else { return base == nil ? .upload : .conflict }
        if local == remote { return .unchanged }
        guard let base else { return .conflict }
        if remote == base { return .upload }
        if local == base { return .download }
        return .conflict
    }
}
