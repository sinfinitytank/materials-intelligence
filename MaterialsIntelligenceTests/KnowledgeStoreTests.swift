import Foundation

@main struct KnowledgeStoreTests {
    static func check(_ condition: @autoclosure () throws -> Bool) throws { let result = try condition(); precondition(result) }
    static func main() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "materials-knowledge-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            let store = try KnowledgeStore(url: url)
            try check(try store.schemaVersion() == 1)
            try store.seedIfEmpty()
            let firstCount = try store.records().count
            try store.seedIfEmpty()
            try check(try store.records().count == firstCount)
            for kind in RecordKind.allCases { try check(!(try store.records(kind: kind)).isEmpty) }
            let material = try store.records(kind: .material)[0]
            try check((try store.claims(subjectID: material.id)).count >= 1)
            try check((try store.relationships(recordID: material.id)).count >= 1)
            let source = try store.records(kind: .source)[0]
            let trial = KnowledgeRecord(kind: .material, name: "Trial")
            try store.save(trial)
            try check(try store.record(id: trial.id)?.name == "Trial")
            var edited = trial; edited.name = "Trial updated"; try store.save(edited)
            try check(try store.record(id: trial.id)?.name == "Trial updated")
            let claim = EngineeringClaim(subjectID: trial.id, predicate: "test", statement: "Test claim", sourceID: source.id)
            try store.save(claim)
            try check((try store.claims(subjectID: trial.id)).count == 1)
            let link = KnowledgeRelationship(fromID: trial.id, predicate: "related_to", toID: material.id, supportingClaimID: claim.id)
            try store.save(link)
            try check((try store.relationships(recordID: trial.id)).count == 1)
            do { try store.deleteRecord(id: trial.id); fatalError("Missing foreign-key restriction") } catch {}
            do { try store.save(KnowledgeRecord(kind: .material, name: material.name)); fatalError("Missing duplicate protection") } catch {}
            do { try store.save(EngineeringClaim(subjectID: trial.id, predicate: "invalid", statement: "Invalid", sourceID: material.id)); fatalError("Missing source-kind check") } catch {}
            try store.deleteRelationship(id: link.id)
            try store.deleteClaim(id: claim.id)
            try store.deleteRecord(id: trial.id)
            try check(try store.record(id: trial.id) == nil)
        }
        let reopened = try KnowledgeStore(url: url)
        try check(try reopened.schemaVersion() == 1)
        try check(try reopened.records(kind: .material).contains { $0.id == "demo:material:alloy-725" })
        print("KnowledgeStore tests passed")
    }
}
