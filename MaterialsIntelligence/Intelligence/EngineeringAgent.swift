import Foundation

enum AgentMode: String, Codable, CaseIterable { case local, research }
enum AgentTool: String, Codable, CaseIterable {
    case recordLookup, localSearch, graphTraversal, claimAndSourceRetrieval, degradationAssessment, localExplanation, researchHandoff
}
struct AgentEvent: Codable, Identifiable {
    let tool: AgentTool
    let summary: String
    var id: String { tool.rawValue }
}
struct AgentRun: Codable, Identifiable {
    var id = UUID().uuidString
    var createdAt = ISO8601DateFormatter().string(from: Date())
    let task: String
    let mode: AgentMode
    var state = "started"
    var events: [AgentEvent] = []
    var report = ""
    var claimIDs: [String] = []
    var explanation: [String] = []
}
@MainActor struct EngineeringAgent {
    let store: KnowledgeStore
    /// Fixed, bounded workflow: the model cannot invent tools or mutate knowledge.
    func run(task: String, input: AssessmentInput, mode: AgentMode = .local, explain: Bool = false, provider: any LocalAIProvider = AppleLocalProvider()) async throws -> AgentRun {
        var run = AgentRun(task: String(task.prefix(4000)), mode: mode)
        try store.saveAgentRun(run)
        do {
            guard task.count <= 4000 else { throw KnowledgeStoreError(message: "Task exceeds 4000 characters") }
            if mode == .research {
                run.state = "research handoff"
                run.events = [AgentEvent(tool: .researchHandoff, summary: "No external access performed. Research must be obtained deliberately and imported through Research review.")]
                run.report = "Research brief: \(task)\nIdentify missing evidence, source titles/revisions and exact locators. Prepare a Phase 6 schema-v1 package. Import, review and commit through Research; new claims remain Unverified until reviewed. Do not share restricted work data externally."
            } else {
                let lower = task.lowercased()
                guard ["degradation", "corrosion", "damage", "cracking"].contains(where: lower.contains) else {
                    run.state = "unsupported task"
                    run.report = "This agent supports evidence-backed degradation assessment only. Describe a degradation, corrosion, damage or cracking assessment and provide the structured conditions. No engineering conclusion was generated."
                    try store.saveAgentRun(run); return run
                }
                let records = try store.records()
                var resolved = input
                func uniqueMatch(_ kind: RecordKind) -> String {
                    let candidates = records.filter { $0.kind == kind && lower.contains($0.name.lowercased()) }
                    return candidates.count == 1 ? candidates[0].id : ""
                }
                if resolved.materialID.isEmpty { resolved.materialID = uniqueMatch(.material) }
                if resolved.componentID.isEmpty { resolved.componentID = uniqueMatch(.component) }
                run.events.append(AgentEvent(tool: .recordLookup, summary: "Resolved material/component from explicit inputs or one exact stored-name match; ambiguous names remain missing. Structured inputs control evaluation; task prose does not silently set conditions."))
                let hits = try store.search(task)
                run.events.append(AgentEvent(tool: .localSearch, summary: "Found \(hits.count) local FTS matches; lexical context is not an engineering conclusion."))
                let graph = try KnowledgeGraph(store: store)
                let paths = graph.traverse(from: resolved.materialID, depth: 2, limit: 100)
                run.events.append(AgentEvent(tool: .graphTraversal, summary: "Inspected \(paths.paths.count) stored context paths; truncated: \(paths.truncated). Only direct connections/scoped rules determine candidates."))
                let service = DegradationAssessment(store: store)
                let report = try service.assess(resolved)
                let evidence = report.context + report.mechanisms.flatMap(\.evidence)
                run.claimIDs = Set(evidence.map(\.id)).sorted()
                run.events.append(AgentEvent(tool: .claimAndSourceRetrieval, summary: "Resolved \(run.claimIDs.count) active claims to stored sources; report retains exact status, conditions and locators. Standards are references, not asserted requirements."))
                run.events.append(AgentEvent(tool: .degradationAssessment, summary: "Ran deterministic scoped-rule screening; \(report.mechanisms.count) candidate mechanisms; \(report.mechanisms.filter(\.contradictory).count) explicit rule conflicts."))
                run.report = report.text
                let supported = report.mechanisms.contains { $0.rules.contains(where: \.matched) || !$0.evidence.isEmpty }
                run.state = supported ? "assessment with qualifications" : "insufficient evidence"
                if resolved.materialID.isEmpty || resolved.componentID.isEmpty || resolved.environment.isEmpty { run.state = "missing inputs" }
                if explain {
                    do {
                        let points = try await service.explain(report, provider: provider)
                        run.explanation = points.map { "AI inference (unverified): \($0.text) [\($0.evidence.map(\.id).joined(separator: ", "))]" }
                        run.events.append(AgentEvent(tool: .localExplanation, summary: points.isEmpty ? "No grounded explanation available; deterministic report retained." : "Local explanation returned validated citation IDs; semantic support requires engineering review."))
                    } catch { run.events.append(AgentEvent(tool: .localExplanation, summary: "Unavailable or invalid local explanation: \(error.localizedDescription). Deterministic report retained.")) }
                }
            }
            try store.saveAgentRun(run)
            return run
        } catch {
            run.state = "failed safely"; run.report = error.localizedDescription
            try store.saveAgentRun(run)
            return run
        }
    }
}
