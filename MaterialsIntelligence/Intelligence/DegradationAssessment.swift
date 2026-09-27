import Foundation

struct AssessmentInput: Equatable {
    var materialID: String = ""
    var componentID: String = ""
    var environment: String = ""
    var temperatureC: Double? = nil
    var pressureMPa: Double? = nil
    var notes: String = ""
}
/// Explicit rules are authored as JSON in the notes of a source-backed `assessment_rule` claim.
/// No built-in engineering threshold or material-specific rule exists.
struct AssessmentRule: Codable {
    let version: Int
    let mechanismID: String
    let environment: String
    let temperatureMinC: Double?
    let temperatureMaxC: Double?
    let pressureMinMPa: Double?
    let pressureMaxMPa: Double?
    let outcome: String // relevant or excluded, only within this rule's scope
    let mitigation: String?
    func validate() -> Bool {
        version == 1 && !environment.isEmpty && ["relevant", "excluded"].contains(outcome)
        && [temperatureMinC, temperatureMaxC, pressureMinMPa, pressureMaxMPa].compactMap { $0 }.allSatisfy(\.isFinite)
        && (temperatureMinC ?? -.infinity) <= (temperatureMaxC ?? .infinity)
        && (pressureMinMPa ?? -.infinity) <= (pressureMaxMPa ?? .infinity)
    }
}
struct RuleEvaluation: Identifiable {
    let claim: EngineeringClaim
    let result: String
    let matched: Bool
    let outcome: String?
    let mitigation: String?
    var id: String { claim.id }
}
struct MechanismAssessment: Identifiable {
    let record: KnowledgeRecord
    let relationships: [KnowledgeGraph.Edge]
    let evidence: [AnswerEvidence]
    let rules: [RuleEvaluation]
    let standards: [KnowledgeRecord]
    var id: String { record.id }
    var contradictory: Bool { Set(rules.filter(\.matched).compactMap(\.outcome)).count > 1 }
    var conclusion: String {
        if contradictory { return "Conflicting explicit rules — engineering review required" }
        if rules.contains(where: { $0.matched && $0.outcome == "relevant" }) { return "Relevant within matched stored rule scope; likelihood not quantified" }
        if rules.contains(where: { $0.matched && $0.outcome == "excluded" }) { return "Excluded only within matched stored rule scope; not a general safety finding" }
        return "Candidate from stored context; applicability and likelihood unresolved"
    }
}
struct DegradationReport {
    let input: AssessmentInput
    let mechanisms: [MechanismAssessment]
    let assumptions: [String]
    let gaps: [String]
    let context: [AnswerEvidence]
    var text: String {
        var lines = ["LOCAL — Degradation screening", "Material ID: \(input.materialID)", "Component ID: \(input.componentID)", "Environment: \(input.environment)", "Temperature °C: \(input.temperatureC.map(String.init(describing:)) ?? "missing")", "Pressure MPa: \(input.pressureMPa.map(String.init(describing:)) ?? "missing")", "User notes / assumptions: \(input.notes)"]
        lines += assumptions.map { "Assumption: \($0)" } + gaps.map { "Gap: \($0)" }
        for item in mechanisms {
            lines += ["\n\(item.record.name): \(item.conclusion)"]
            lines += item.rules.map { "Deterministic rule [\($0.id)]: \($0.result)\nControlling variables / stored rule: \($0.claim.notes)" }
            lines += item.rules.filter(\.matched).compactMap { $0.mitigation.map { "Stored mitigation (rule scope only): \($0)" } }
            lines += item.evidence.map { "Evidence [\($0.id)] \($0.claim.status.title): \($0.claim.statement) | Conditions: \($0.claim.conditions) | \($0.source.name) [\($0.source.id)] \($0.claim.locator)" }
            lines += item.standards.map { "Standard to review: \($0.name) [\($0.id)]" }
        }
        lines += context.map { "Context evidence [\($0.id)] \($0.claim.status.title): \($0.claim.statement) | \($0.source.name) \($0.claim.locator)" }
        return lines.joined(separator: "\n")
    }
}
@MainActor struct DegradationAssessment {
    let store: KnowledgeStore
    func assess(_ input: AssessmentInput) throws -> DegradationReport {
        let graph = try KnowledgeGraph(store: store)
        var gaps: [String] = []
        if graph.records[input.materialID]?.kind != .material { gaps.append("Select a stored material.") }
        if graph.records[input.componentID]?.kind != .component { gaps.append("Select a stored component.") }
        if input.environment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { gaps.append("Environment is missing.") }
        if input.temperatureC == nil { gaps.append("Temperature is missing (°C).") }
        if input.pressureMPa == nil { gaps.append("Pressure is missing (MPa).") }
        if let t = input.temperatureC, !t.isFinite { throw KnowledgeStoreError(message: "Temperature must be finite") }
        if let p = input.pressureMPa, !p.isFinite || p < 0 { throw KnowledgeStoreError(message: "Pressure must be finite and nonnegative") }
        let subjects = Set([input.materialID, input.componentID].filter { graph.records[$0] != nil })
        let direct = graph.edges.filter { !$0.derived && (subjects.contains($0.from) || subjects.contains($0.to)) }
        var mechanismIDs = Set(direct.flatMap { [$0.from, $0.to] }.filter { graph.records[$0]?.kind == .mechanism })
        let active = graph.claims.values.filter { $0.status != .archived && $0.status != .superseded }.sorted { $0.id < $1.id }
        var parsed: [(EngineeringClaim, AssessmentRule)] = []
        for claim in active where subjects.contains(claim.subjectID) && claim.predicate == "assessment_rule" {
            guard let rule = try? JSONDecoder().decode(AssessmentRule.self, from: Data(claim.notes.utf8)), rule.validate(), graph.records[rule.mechanismID]?.kind == .mechanism else { gaps.append("Invalid rule in claim \(claim.id); not evaluated."); continue }
            parsed.append((claim, rule)); mechanismIDs.insert(rule.mechanismID)
        }
        func evidence(_ claim: EngineeringClaim) -> AnswerEvidence? {
            guard let subject = graph.records[claim.subjectID], let source = graph.records[claim.sourceID] else { return nil }
            return AnswerEvidence(claim: claim, subject: subject, source: source)
        }
        let mechanisms = mechanismIDs.sorted().compactMap { id -> MechanismAssessment? in
            guard let record = graph.records[id] else { return nil }
            let edges = direct.filter { $0.from == id || $0.to == id }
            let relatedClaims = Set(edges.compactMap(\.claimID) + parsed.filter { $0.1.mechanismID == id }.map { $0.0.id })
            let evidenceItems = active.filter { $0.subjectID == id || relatedClaims.contains($0.id) }.compactMap(evidence)
            let evaluations = parsed.filter { $0.1.mechanismID == id }.map { claim, rule -> RuleEvaluation in
                var reasons: [String] = []
                if claim.status != .reviewed && claim.status != .verified { reasons.append("Rule is not Reviewed or Verified") }
                if rule.environment.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != input.environment.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() { reasons.append("Environment does not exactly match rule scope") }
                func bounds(_ value: Double?, _ low: Double?, _ high: Double?, _ label: String) {
                    guard low != nil || high != nil else { return }
                    guard let value else { reasons.append("Missing \(label)"); return }
                    if value < (low ?? -.infinity) || value > (high ?? .infinity) { reasons.append("\(label) outside stored inclusive bounds") }
                }
                bounds(input.temperatureC, rule.temperatureMinC, rule.temperatureMaxC, "temperature")
                bounds(input.pressureMPa, rule.pressureMinMPa, rule.pressureMaxMPa, "pressure")
                let matched = reasons.isEmpty
                return RuleEvaluation(claim: claim, result: matched ? "Matched explicit rule: \(rule.outcome)" : reasons.joined(separator: "; "), matched: matched, outcome: matched ? rule.outcome : nil, mitigation: matched ? rule.mitigation : nil)
            }
            let standardIDs = Set(graph.neighbors(id).flatMap { [$0.from, $0.to] } + subjects.flatMap { graph.neighbors($0).flatMap { [$0.from, $0.to] } })
            let standards = standardIDs.compactMap { graph.records[$0] }.filter { $0.kind == .standard }.sorted { $0.id < $1.id }
            if evidenceItems.isEmpty { gaps.append("\(record.name): no source-backed active evidence.") }
            if !evaluations.contains(where: \.matched) { gaps.append("\(record.name): no reviewed explicit rule matches the supplied conditions.") }
            return MechanismAssessment(record: record, relationships: edges, evidence: evidenceItems, rules: evaluations, standards: standards)
        }
        if mechanisms.isEmpty { gaps.append("Insufficient local knowledge: no directly connected mechanism or scoped assessment rule.") }
        gaps.append("Semantic contradictions in narrative claims require human review; only opposite matched explicit rule outcomes are detected.")
        return DegradationReport(input: input, mechanisms: mechanisms,
            assumptions: ["User inputs are accepted as supplied, not measured or verified.", "Stored relationships identify candidates, not causation or quantified risk.", "Rule bounds are inclusive; unmatched conditions remain unsupported.", "Standards are references to review, not fabricated requirements."], gaps: gaps, context: active.filter { subjects.contains($0.subjectID) }.compactMap(evidence))
    }
    func explain(_ report: DegradationReport, provider: any LocalAIProvider) async throws -> [AnswerPoint] {
        let all = report.mechanisms.flatMap(\.evidence) + report.context
        var seen = Set<String>()
        let evidence = all.filter { ($0.claim.status == .reviewed || $0.claim.status == .verified) && seen.insert($0.id).inserted }.prefix(LocalRAG.maxClaims).map { $0 }
        guard !evidence.isEmpty else { return [] }
        let rag = LocalRAG(store: store, provider: provider)
        let prompt = rag.buildContext(question: "Explain this screening without adding conclusions: " + String(report.text.prefix(350)), evidence: evidence)
        return try rag.parse(try await provider.generate(prompt: prompt), evidence: evidence)
    }
}
