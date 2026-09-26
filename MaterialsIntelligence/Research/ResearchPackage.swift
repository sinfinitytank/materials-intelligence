import Foundation

/// External identifiers are package-local, never production primary keys.
struct ResearchPackage: Codable, Equatable {
    var schemaVersion: Int
    var packageID: String
    var topic: String
    var summary: String?
    var boundary: String // publicPersonal or restricted; informational, never an export permission
    var entities: [ResearchEntity]
    var claims: [ResearchClaim]
    var relationships: [ResearchRelationship]

    static func parse(_ data: Data) throws -> Self {
        guard data.count <= 5_000_000 else { throw KnowledgeStoreError(message: "Package exceeds the 5 MB limit.") }
        let package: Self
        do { package = try JSONDecoder().decode(Self.self, from: data) }
        catch let DecodingError.keyNotFound(key, context) {
            throw KnowledgeStoreError(message: "Missing required field \((context.codingPath.map(\.stringValue) + [key.stringValue]).joined(separator: ".")).")
        } catch let DecodingError.typeMismatch(_, context) {
            throw KnowledgeStoreError(message: "Invalid field type at \(context.codingPath.map(\.stringValue).joined(separator: ".")). \(context.debugDescription)")
        } catch { throw KnowledgeStoreError(message: "Invalid research JSON: \(error.localizedDescription)") }
        try package.validate()
        return package
    }

    func validate() throws {
        func require(_ valid: Bool, _ message: String) throws { if !valid { throw KnowledgeStoreError(message: message) } }
        func filled(_ text: String) -> Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        try require(schemaVersion == 1, "Unsupported research schema version \(schemaVersion); expected 1.")
        try require(filled(packageID) && filled(topic), "packageID and topic must not be blank.")
        try require(["publicPersonal", "restricted"].contains(boundary), "boundary must be publicPersonal or restricted.")
        let ids = entities.map(\.id) + claims.map(\.id) + relationships.map(\.id)
        try require(!ids.isEmpty && ids.count <= 1000, "A package must contain 1–1000 proposals.")
        try require(ids.allSatisfy { filled($0) && $0.count <= 128 }, "Proposal IDs must contain 1–128 characters.")
        try require(Set(ids).count == ids.count, "Duplicate proposal ID; all IDs must be unique across the package.")
        let records = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
        let claimIDs = Set(claims.map(\.id))
        var signatures = Set<String>()
        for entity in entities {
            try require(RecordKind(rawValue: entity.kind) != nil && filled(entity.name), "Entity \(entity.id): invalid kind or blank name.")
            let signature = entity.kind + ":" + researchNormalize(entity.name)
            try require(signatures.insert(signature).inserted, "Duplicate entity name in package: \(entity.name). Use one ID and reference it.")
            if entity.kind == "source" {
                try require(entity.source != nil, "Source \(entity.id) requires source metadata (an empty object is allowed).")
            } else { try require(entity.source == nil, "Only source entities may carry source metadata: \(entity.id).") }
            if let url = entity.source?.url {
                let parsed = URLComponents(string: url)
                try require(["https", "http"].contains(parsed?.scheme ?? "") && !(parsed?.host ?? "").isEmpty, "Source \(entity.id): URL must be an absolute HTTP(S) URL.")
            }
        }
        signatures.removeAll()
        for claim in claims {
            try require(records[claim.subjectID] != nil && records[claim.subjectID]?.kind != "source", "Claim \(claim.id): unknown or source-only subjectID.")
            try require(records[claim.sourceID]?.kind == "source", "Claim \(claim.id): sourceID must reference a source entity.")
            try require(filled(claim.predicate) && filled(claim.statement), "Claim \(claim.id): predicate and statement are required.")
            if let confidence = claim.confidence { try require((0...1).contains(confidence), "Claim \(claim.id): confidence must be 0–1.") }
            let signature = [claim.subjectID, researchNormalize(claim.predicate), researchNormalize(claim.statement), claim.conditions ?? "", claim.sourceID, claim.locator ?? ""].joined(separator: "\u{1f}")
            try require(signatures.insert(signature).inserted, "Duplicate claim in package: \(claim.id).")
        }
        signatures.removeAll()
        for edge in relationships {
            try require(records[edge.fromID] != nil && records[edge.toID] != nil && edge.fromID != edge.toID && filled(edge.predicate), "Relationship \(edge.id): invalid endpoints or blank predicate.")
            try require(edge.supportingClaimID == nil || claimIDs.contains(edge.supportingClaimID!), "Relationship \(edge.id): unknown supportingClaimID.")
            try require(signatures.insert([edge.fromID, researchNormalize(edge.predicate), edge.toID].joined(separator: "\u{1f}")).inserted, "Duplicate relationship: \(edge.id).")
        }
    }
}
struct ResearchSource: Codable, Equatable {
    var organization: String?
    var documentType: String?
    var revisionYear: String?
    var url: String?
    var publication: String?
}
struct ResearchEntity: Codable, Equatable, Identifiable {
    var id: String
    var kind: String
    var name: String
    var secondary: String?
    var detail: String?
    var aliases: [String]?
    var source: ResearchSource?
    var permanentDetail: String {
        var lines = [detail ?? ""]
        if let source { lines += [source.organization, source.documentType, source.revisionYear, source.url, source.publication].compactMap { $0 } }
        if let aliases, !aliases.isEmpty { lines.append("Aliases: " + aliases.joined(separator: "; ")) }
        return lines.filter { !$0.isEmpty }.joined(separator: "\n")
    }
}
struct ResearchClaim: Codable, Equatable, Identifiable {
    var id: String
    var subjectID: String
    var predicate: String
    var statement: String
    var conditions: String?
    var sourceID: String
    var locator: String?
    var confidence: Double?
    var notes: String?
}
struct ResearchRelationship: Codable, Equatable, Identifiable {
    var id: String
    var fromID: String
    var predicate: String
    var toID: String
    var supportingClaimID: String?
}
func researchNormalize(_ value: String) -> String {
    value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")).filter { $0.isLetter || $0.isNumber }
}
enum ResearchDecision: String, Codable, CaseIterable { case pending, accept, reject, merge }
struct ResearchReview: Codable, Equatable {
    var decision: ResearchDecision = .pending
    var targetID: String? = nil
}
struct ResearchSession: Codable, Identifiable {
    var id: String = UUID().uuidString
    var importedAt: String = ISO8601DateFormatter().string(from: Date())
    var originalJSON: String
    var package: ResearchPackage
    var reviews: [String: ResearchReview] = [:]
    var results: [String: String] = [:]
    var status: String = "staged"
    var revision: Int = 0
    var lastError: String? = nil
}
struct ResearchMatch: Identifiable {
    let id: String
    let title: String
    let reason: String
    let canMerge: Bool
}
