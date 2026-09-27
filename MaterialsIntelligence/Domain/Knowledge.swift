import Foundation

enum RecordKind: String, CaseIterable, Codable, Sendable { case material, mechanism, standard, component, source }
struct KnowledgeRecord: Identifiable, Equatable, Hashable, Codable, Sendable {
    let id: String
    let kind: RecordKind
    var name: String
    var detail: String
    var secondary: String
    init(id: String = UUID().uuidString, kind: RecordKind, name: String, detail: String = "", secondary: String = "") {
        self.id = id; self.kind = kind; self.name = name; self.detail = detail; self.secondary = secondary
    }
}
enum VerificationStatus: String, CaseIterable, Codable, Sendable { case draft, unverified, reviewed, verified, superseded, archived
    var title: String { rawValue.capitalized }
}
struct EngineeringClaim: Identifiable, Equatable, Hashable, Codable, Sendable {
    let id: String
    var subjectID: String
    var predicate: String
    var statement: String
    var conditions: String
    var sourceID: String
    var locator: String
    var status: VerificationStatus
    var evidenceLevel: String
    var notes: String
    var createdAt: String
    var modifiedAt: String
    init(id: String = UUID().uuidString, subjectID: String, predicate: String, statement: String, conditions: String = "", sourceID: String, locator: String = "", status: VerificationStatus = .unverified, evidenceLevel: String = "", notes: String = "", createdAt: String = "", modifiedAt: String = "") {
        self.id = id; self.subjectID = subjectID; self.predicate = predicate; self.statement = statement; self.conditions = conditions; self.sourceID = sourceID; self.locator = locator; self.status = status; self.evidenceLevel = evidenceLevel; self.notes = notes; self.createdAt = createdAt; self.modifiedAt = modifiedAt
    }
    private enum CodingKeys: String, CodingKey {
        case id, subjectID, predicate, statement, conditions, sourceID, locator, status, evidenceLevel, notes, createdAt, modifiedAt
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        subjectID = try values.decode(String.self, forKey: .subjectID)
        predicate = try values.decode(String.self, forKey: .predicate)
        statement = try values.decode(String.self, forKey: .statement)
        conditions = try values.decode(String.self, forKey: .conditions)
        sourceID = try values.decode(String.self, forKey: .sourceID)
        locator = try values.decode(String.self, forKey: .locator)
        status = try values.decode(VerificationStatus.self, forKey: .status)
        evidenceLevel = try values.decode(String.self, forKey: .evidenceLevel)
        notes = try values.decode(String.self, forKey: .notes)
        // Wire format v1 snapshots created before timestamp preservation omitted
        // these fields. Empty values intentionally ask SQLite to assign local time.
        createdAt = try values.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        modifiedAt = try values.decodeIfPresent(String.self, forKey: .modifiedAt) ?? ""
    }
}
struct KnowledgeRelationship: Identifiable, Equatable, Hashable, Codable, Sendable {
    let id: String
    var fromID: String
    var predicate: String
    var toID: String
    var supportingClaimID: String?
    init(id: String = UUID().uuidString, fromID: String, predicate: String, toID: String, supportingClaimID: String? = nil) {
        self.id = id; self.fromID = fromID; self.predicate = predicate; self.toID = toID; self.supportingClaimID = supportingClaimID
    }
}

enum SearchEntityType: String, CaseIterable, Identifiable, Sendable { case record, claim, document
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct SearchResult: Identifiable, Equatable, Sendable {
    let id: String
    let entityType: SearchEntityType
    let title: String
    let detail: String
    let kind: String
    let score: Double
}

struct LibraryDocument: Identifiable, Equatable, Hashable, Codable, Sendable {
    let id: String
    var title: String
    var organization: String
    var revisionYear: String
    var sourceType: String
    var notes: String
    var fileName: String
    var bookmark: String
    var addedAt: String
    init(id: String = UUID().uuidString, title: String, organization: String = "", revisionYear: String = "", sourceType: String = "", notes: String = "", fileName: String = "", bookmark: String = "", addedAt: String = "") {
        self.id = id; self.title = title; self.organization = organization; self.revisionYear = revisionYear; self.sourceType = sourceType; self.notes = notes; self.fileName = fileName; self.bookmark = bookmark; self.addedAt = addedAt
    }
}
