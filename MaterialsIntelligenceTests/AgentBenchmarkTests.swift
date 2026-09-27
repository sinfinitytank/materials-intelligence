import Foundation
@main @MainActor struct AgentBenchmarkTests {
    static func check(_ value: @autoclosure () throws -> Bool, _ label: String) throws { guard try value() else { throw KnowledgeStoreError(message: label) } }
    static func main() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "agent-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "knowledge.sqlite")
        let store = try KnowledgeStore(url: url)
        for r in [KnowledgeRecord(id:"m", kind:.material, name:"Synthetic Alloy"), KnowledgeRecord(id:"c", kind:.component, name:"Synthetic Pipe"), KnowledgeRecord(id:"d", kind:.mechanism, name:"Synthetic Damage"), KnowledgeRecord(id:"s", kind:.source, name:"Synthetic Lab Evidence"), KnowledgeRecord(id:"std", kind:.standard, name:"Synthetic Standard")] { try store.save(r) }
        func rule(_ id: String, _ outcome: String) throws {
            let rule = AssessmentRule(version: 1, mechanismID: "d", environment: "synthetic", temperatureMinC: 10, temperatureMaxC: 20, pressureMinMPa: nil, pressureMaxMPa: nil, outcome: outcome, mitigation: nil)
            try store.save(EngineeringClaim(id: id, subjectID: "m", predicate: "assessment_rule", statement: "Synthetic scope only", sourceID: "s", locator: "test section", status: .reviewed, notes: String(decoding: try JSONEncoder().encode(rule), as: UTF8.self)))
        }
        try rule("r", "relevant")
        try store.save(KnowledgeRelationship(fromID: "m", predicate: "context", toID: "d", supportingClaimID: "r"))
        try store.save(KnowledgeRelationship(fromID: "d", predicate: "reference", toID: "std"))
        let agent = EngineeringAgent(store: store)
        let input = AssessmentInput(environment: "synthetic", temperatureC: 15, pressureMPa: 1)
        let task = "Assess degradation of Synthetic Alloy in Synthetic Pipe"
        let baseline = try VaultSnapshot(store: store).encoded()
        let normal = try await agent.run(task: task, input: input)
        try check(normal.state == "assessment with qualifications", "normal workflow")
        try check(normal.claimIDs == ["r"] && normal.report.contains("Synthetic Lab Evidence") && normal.report.contains("test section") && normal.report.contains("Synthetic Standard"), "retrieval and source correctness")
        try check(normal.events.map(\.tool) == [.recordLookup,.localSearch,.graphTraversal,.claimAndSourceRetrieval,.degradationAssessment], "tool selection")
        let repeatRun = try await agent.run(task: task, input: input)
        try check(repeatRun.report == normal.report && repeatRun.claimIDs == normal.claimIDs, "reproducibility")
        let missing = try await agent.run(task: "Assess degradation", input: AssessmentInput())
        try check(missing.state == "missing inputs" && missing.report.contains("Select a stored material"), "missing data")
        let unsupported = try await agent.run(task: "Write a purchase order", input: input)
        try check(unsupported.state == "unsupported task" && unsupported.events.isEmpty, "unsupported question")
        let noModel = try await agent.run(task: task, input: input, explain: true, provider: UnavailableAgentProvider())
        try check(noModel.report == normal.report && noModel.explanation.isEmpty, "offline deterministic fallback")
        let malicious = try await agent.run(task: task, input: input, explain: true, provider: InvalidAgentProvider())
        try check(malicious.explanation.isEmpty && malicious.report == normal.report, "unsupported citation rejected")
        let handoff = try await agent.run(task: task, input: input, mode: .research)
        try check(handoff.events.map(\.tool) == [.researchHandoff] && handoff.report.contains("Phase 6"), "research boundary")
        try check(try VaultSnapshot(store: store).encoded() == baseline, "agent never mutates knowledge or bypasses ingestion")
        try rule("opposed", "excluded")
        let conflict = try await agent.run(task: task, input: input)
        try check(conflict.report.contains("Conflicting explicit rules") && conflict.claimIDs == ["opposed","r"], "contradictory evidence")
        var outside = input; outside.temperatureC = 21
        let outOfScope = try await agent.run(task: task, input: outside)
        try check(outOfScope.report.contains("outside stored inclusive bounds") && outOfScope.report.contains("applicability and likelihood unresolved"), "unsupported operating conditions")
        let reopened = try KnowledgeStore(url: url)
        try check(try reopened.agentRuns().count == 9 && reopened.foreignKeyViolations() == 0, "durable audit and integrity")
        print("Agent benchmarks passed: 9 runs; tool selection, sources, repeatability, missing inputs, unsupported task, offline fallback, invalid citations, research gate, conflicts and history")
    }
}
struct UnavailableAgentProvider: LocalAIProvider {
    var availabilityMessage: String? { "unavailable" }
    func generate(prompt: String) async throws -> String { throw RAGError.modelUnavailable("unavailable") }
}
struct InvalidAgentProvider: LocalAIProvider {
    var availabilityMessage: String? { nil }
    func generate(prompt: String) async throws -> String { "{\"points\":[{\"text\":\"unsupported\",\"claimIDs\":[\"invented\"]}]}" }
}
