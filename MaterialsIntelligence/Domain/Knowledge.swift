import Foundation

enum RecordKind: String, CaseIterable, Sendable { case material, mechanism, standard, component, source }
struct KnowledgeRecord: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let kind: RecordKind
    var name: String
    var detail: String
    var secondary: String
    init(id: String = UUID().uuidString, kind: RecordKind, name: String, detail: String = "", secondary: String = "") {
        self.id = id; self.kind = kind; self.name = name; self.detail = detail; self.secondary = secondary
    }
}
enum VerificationStatus: String, CaseIterable, Sendable { case draft, unverified, reviewed, verified, superseded, archived
    var title: String { rawValue.capitalized }
}
struct EngineeringClaim: Identifiable, Equatable, Hashable, Sendable {
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
    init(id: String = UUID().uuidString, subjectID: String, predicate: String, statement: String, conditions: String = "", sourceID: String, locator: String = "", status: VerificationStatus = .unverified, evidenceLevel: String = "", notes: String = "") {
        self.id = id; self.subjectID = subjectID; self.predicate = predicate; self.statement = statement; self.conditions = conditions; self.sourceID = sourceID; self.locator = locator; self.status = status; self.evidenceLevel = evidenceLevel; self.notes = notes
    }
}
struct KnowledgeRelationship: Identifiable, Equatable, Sendable {
    let id: String
    var fromID: String
    var predicate: String
    var toID: String
    var supportingClaimID: String?
    init(id: String = UUID().uuidString, fromID: String, predicate: String, toID: String, supportingClaimID: String? = nil) {
        self.id = id; self.fromID = fromID; self.predicate = predicate; self.toID = toID; self.supportingClaimID = supportingClaimID
    }
}
