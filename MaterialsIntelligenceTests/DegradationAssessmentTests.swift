import Foundation
@main @MainActor struct DegradationAssessmentTests {
    static func check(_ condition: @autoclosure () throws -> Bool) throws { let result = try condition(); precondition(result) }
    static func main() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "assessment-\(UUID()).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try KnowledgeStore(url: url)
        for r in [KnowledgeRecord(id:"m", kind:.material, name:"Synthetic material"), KnowledgeRecord(id:"c", kind:.component, name:"Synthetic component"), KnowledgeRecord(id:"d", kind:.mechanism, name:"Synthetic mechanism"), KnowledgeRecord(id:"s", kind:.source, name:"Synthetic report")] { try store.save(r) }
        let service = DegradationAssessment(store: store)
        let empty = try service.assess(AssessmentInput())
        try check(empty.mechanisms.isEmpty && empty.gaps.count >= 5)
        func rule(_ id: String, outcome: String, status: VerificationStatus = .reviewed) throws {
            let r = AssessmentRule(version: 1, mechanismID: "d", environment: "synthetic brine", temperatureMinC: 10, temperatureMaxC: 20, pressureMinMPa: 1, pressureMaxMPa: 2, outcome: outcome, mitigation: "Synthetic mitigation; not engineering guidance")
            let json = String(data: try JSONEncoder().encode(r), encoding: .utf8)!
            try store.save(EngineeringClaim(id: id, subjectID: "m", predicate: "assessment_rule", statement: "Synthetic scoped rule", sourceID: "s", locator: "table 1", status: status, notes: json))
        }
        try rule("r1", outcome: "relevant")
        let input = AssessmentInput(materialID: "m", componentID: "c", environment: "synthetic brine", temperatureC: 10, pressureMPa: 2)
        let normal = try service.assess(input)
        try check(normal.mechanisms.count == 1 && normal.mechanisms[0].rules[0].matched)
        try check(normal.mechanisms[0].evidence[0].source.id == "s" && normal.text.contains("table 1"))
        try check(normal.text == (try service.assess(input)).text)
        var outside = input; outside.temperatureC = 20.0001
        try check(!(try service.assess(outside)).mechanisms[0].rules[0].matched)
        outside = input; outside.environment = "unsupported environment"
        try check(!(try service.assess(outside)).mechanisms[0].rules[0].matched)
        outside = input; outside.temperatureC = nil
        try check(!(try service.assess(outside)).mechanisms[0].rules[0].matched)
        try rule("r2", outcome: "excluded")
        try check((try service.assess(input)).mechanisms[0].contradictory)
        try rule("r2", outcome: "excluded", status: .unverified)
        try check(!(try service.assess(input)).mechanisms[0].contradictory)
        var invalid = input; invalid.pressureMPa = -1
        do { _ = try service.assess(invalid); fatalError("negative pressure accepted") } catch is KnowledgeStoreError { }
        let provider = AssessmentProvider(response: "{\"points\":[{\"text\":\"Synthetic explanation\",\"claimIDs\":[\"r1\"]}]}")
        let explained = try await service.explain(normal, provider: provider)
        try check(explained.count == 1 && explained[0].evidence[0].id == "r1")
        do { _ = try await service.explain(normal, provider: AssessmentProvider(response: "{\"points\":[{\"text\":\"invented\",\"claimIDs\":[\"fake\"]}]}")); fatalError("bad citation accepted") } catch RAGError.invalidResponse { }
        print("Degradation assessment tests passed: synthetic end-to-end, bounds, gaps, conflicts, repeatability, citations")
    }
}
struct AssessmentProvider: LocalAIProvider {
    var availabilityMessage: String? { nil }
    let response: String
    func generate(prompt: String) async throws -> String { response }
}
