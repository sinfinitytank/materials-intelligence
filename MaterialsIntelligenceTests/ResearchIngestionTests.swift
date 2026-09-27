import Foundation
import SQLite3

private struct IngestionProvider: LocalAIProvider {
    let claimID: String
    var availabilityMessage: String? { nil }
    func generate(prompt: String) async throws -> String {
        "{\"points\":[{\"text\":\"The synthetic fixture reports susceptibility.\",\"claimIDs\":[\"\(claimID)\"]}]}"
    }
}
@main struct ResearchIngestionTests {
    static func check(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        if try !condition() { throw KnowledgeStoreError(message: "Test failed: " + message) }
    }
    static func fails(_ message: String, _ action: () throws -> Void) throws {
        do { try action() } catch { return }
        throw KnowledgeStoreError(message: "Expected rejection: " + message)
    }
    @MainActor static func main() async throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "Fixtures/alloy-725-research.json"))
        let package = try ResearchPackage.parse(data)
        try fails("malformed JSON") { _ = try ResearchPackage.parse(Data("{".utf8)) }
        try fails("missing field") { _ = try ResearchPackage.parse(Data("{}".utf8)) }
        func invalid(_ modify: (inout ResearchPackage) -> Void) throws {
            var p = package; modify(&p); try fails("validation") { try p.validate() }
        }
        try invalid { $0.schemaVersion = 99 }
        try invalid { $0.entities[0].kind = "unknown" }
        try invalid { $0.claims[0].sourceID = "material" }
        try invalid { $0.claims[0].statement = " " }
        try invalid { $0.claims[0].confidence = 2 }
        try invalid { $0.entities[1].source?.url = "file:///private/file" }
        try invalid { $0.entities[0].id = "source" }
        try invalid { $0.relationships[0].supportingClaimID = "missing" }
        try invalid { var c = $0.claims[0]; c.id = "duplicate"; $0.claims.append(c) }
        try invalid { var e = $0.entities[0]; e.id = "duplicate"; $0.entities.append(e) }
        let url = FileManager.default.temporaryDirectory.appending(path: "research-\(UUID()).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try KnowledgeStore(url: url)
        let material = KnowledgeRecord(kind: .material, name: "Alloy 725", secondary: "UNS N07725")
        try store.save(material)
        let sourceEntity = package.entities[1]
        let source = KnowledgeRecord(kind: .source, name: sourceEntity.name, detail: sourceEntity.permanentDetail)
        try store.save(source)
        let existing = EngineeringClaim(subjectID: material.id, predicate: "susceptibility", statement: "Synthetic opposing hydrogen statement.", conditions: "Synthetic condition A", sourceID: source.id, locator: "fixture section 1", status: .verified)
        try store.save(existing)
        try fails("invalid import is not staged") { _ = try store.importResearch(Data("{".utf8)) }
        try check(try store.researchSessions().isEmpty && store.records().count == 2 && store.claims().count == 1, "invalid import cannot change staging or knowledge")
        var session = try store.importResearch(data)
        try check(try store.search("Excludedfixturecomponent").isEmpty, "staging absent from FTS")
        try check(try store.researchMatches(package, itemID: "material").first?.id == material.id, "designation entity matching")
        try check(try store.researchMatches(package, itemID: "claim").first?.reason.contains("Possible conflict") == true, "potential conflict")
        try check(try store.researchMatches(package, itemID: "source").first?.canMerge == true, "source matching")
        session = try store.decideResearch(session, itemID: "claim", decision: .accept)
        try fails("missing dependency") { _ = try store.commitResearch(session) }
        try check(try store.claims().count == 1 && store.records().count == 2, "failed commit rollback")
        try check(try store.researchSessions().first?.lastError != nil, "failed attempt audit")
        let failedSnapshot = try store.researchSessions().first { $0.id == session.id }!
        var invalidEdit = package; invalidEdit.schemaVersion = 2
        try fails("invalid edit") { _ = try store.editResearch(failedSnapshot, data: JSONEncoder().encode(invalidEdit)) }
        let unchangedAfterInvalidEdit = try store.researchSessions().first { $0.id == session.id }!
        try check(unchangedAfterInvalidEdit.revision == failedSnapshot.revision && unchangedAfterInvalidEdit.package == failedSnapshot.package && unchangedAfterInvalidEdit.reviews == failedSnapshot.reviews, "invalid edit preserves staged snapshot")
        var edited = package; edited.claims[0].notes = "Edited locally before approval"
        session = try store.editResearch(session, data: JSONEncoder().encode(edited))
        try check(session.reviews.isEmpty, "editing clears approvals")
        session = try store.decideResearch(session, itemID: "material", decision: .merge, targetID: material.id)
        session = try store.decideResearch(session, itemID: "source", decision: .merge, targetID: source.id)
        for id in ["mechanism", "claim", "edge"] { session = try store.decideResearch(session, itemID: id, decision: .accept) }
        for id in ["rejectEntity", "rejectClaim"] { session = try store.decideResearch(session, itemID: id, decision: .reject) }
        // Force failure after record/claim/FTS writes, at relationship insertion.
        var raw: OpaquePointer?; sqlite3_open(url.path, &raw)
        sqlite3_exec(raw, "CREATE TRIGGER fail_research BEFORE INSERT ON relationships BEGIN SELECT RAISE(ABORT, 'forced failure'); END", nil, nil, nil)
        try fails("late transaction failure") { _ = try store.commitResearch(session) }
        try check(try store.records().count == 2 && store.claims().count == 1 && store.relationships().isEmpty, "late failure rolls back all knowledge")
        try check(try store.search("Fixture hydrogen mechanism").allSatisfy { $0.id == material.id || $0.id == source.id || $0.id == existing.id }, "FTS rollback")
        sqlite3_exec(raw, "DROP TRIGGER fail_research", nil, nil, nil); sqlite3_close(raw)
        session = try store.commitResearch(session)
        try check(session.status == "committed" && session.results.count == 5, "partial commit results")
        try check(try store.claim(id: existing.id) == existing, "verified claim unchanged")
        let importedID = session.results["claim"]!
        var imported = try store.claim(id: importedID)!
        try check(imported.status == .unverified && imported.sourceID == source.id && imported.locator == "fixture section 1" && imported.notes.contains("Edited locally"), "provenance and conservative state")
        try check(try store.search("Rejecteduniquefixtureclaim").isEmpty && store.search("Excludedfixturecomponent").isEmpty, "rejected absent from permanent search")
        try check(try store.search("susceptibility").contains { $0.id == importedID }, "approved searchable")
        try check(try store.relationships().first?.supportingClaimID == importedID, "relationship provenance")
        try check(try store.foreignKeyViolations() == 0, "integrity")
        try fails("double commit") { _ = try store.commitResearch(session) }
        let rag = LocalRAG(store: store, provider: IngestionProvider(claimID: importedID))
        try check(try rag.retrieve("Alloy 725 hydrogen").contains { $0.id == importedID }, "ordinary RAG retrieval")
        imported.status = .reviewed; try store.save(imported) // Existing explicit Claims lifecycle, not ingestion.
        let answer = try await rag.ask("Alloy 725 hydrogen")
        try check(answer.points.first?.evidence.first?.source.id == source.id, "RAG stored citation after explicit review")
        var repeatSession = try store.importResearch(data)
        try check(try store.researchMatches(package, itemID: "claim").contains { $0.id == importedID && $0.canMerge }, "duplicate claim detected")
        repeatSession = try store.decideResearch(repeatSession, itemID: "material", decision: .merge, targetID: material.id)
        repeatSession = try store.decideResearch(repeatSession, itemID: "source", decision: .merge, targetID: source.id)
        repeatSession = try store.decideResearch(repeatSession, itemID: "claim", decision: .merge, targetID: importedID)
        _ = try store.commitResearch(repeatSession)
        try check(try store.claims().count == 2, "merge reuses claim")
        let cancelled = try store.cancelResearch(store.importResearch(data))
        try fails("cancelled commit") { _ = try store.commitResearch(cancelled) }
        try check(try store.claims().count == 2 && store.records().count == 3, "cancel leaves knowledge intact")
        let reopened = try KnowledgeStore(url: url)
        try check(try reopened.researchSessions().count == 3, "audit persists")
        try check(try reopened.researchSessions().contains { $0.id == session.id && $0.originalJSON == String(decoding: data, as: UTF8.self) && $0.results["claim"] == importedID }, "original package and mapping retained")
        var restricted = package
        restricted.packageID = "restricted-fixture"
        restricted.boundary = "restricted"
        let restrictedSession = try store.importResearch(JSONEncoder().encode(restricted))
        try check(try store.researchSessions().first?.package.boundary == "restricted", "restricted label persists in staging")
        let stale = restrictedSession
        _ = try store.decideResearch(restrictedSession, itemID: "material", decision: .reject)
        try fails("stale review") { _ = try store.decideResearch(stale, itemID: "source", decision: .reject) }
        var revisedSource = package
        revisedSource.entities[1].source?.revisionYear = "synthetic later revision"
        try check(try store.researchMatches(revisedSource, itemID: "source").allSatisfy { !$0.canMerge }, "source revision cannot silently reuse identity")
        var changedConditions = package
        changedConditions.claims[0].conditions = "Synthetic condition B"
        try check(try store.researchMatches(changedConditions, itemID: "claim").allSatisfy { !$0.canMerge }, "changed conditions cannot reuse claim")
        try check(try store.researchMatches(package, itemID: "edge").contains { $0.canMerge }, "identical relationship can reuse identity")
        print("Research ingestion deterministic tests passed")
    }
}
