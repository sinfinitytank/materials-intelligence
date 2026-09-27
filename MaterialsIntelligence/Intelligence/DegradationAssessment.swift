import Foundation

struct AssessmentInput: Equatable, Codable {
    var materialID: String = ""
    var componentID: String = ""
    var environment: String = ""
    var temperatureC: Double? = nil
    var pressureMPa: Double? = nil
    var notes: String = ""
}

enum EngineeringWorkflowKind: String, Codable, CaseIterable, Identifiable {
    case degradation, materialSelection, vendorQualification, failureInvestigation, fitForPurpose
    var id: Self { self }
    var title: String {
        switch self {
        case .degradation: "Degradation assessment"
        case .materialSelection: "Material comparison"
        case .vendorQualification: "Vendor qualification"
        case .failureInvestigation: "Failure investigation"
        case .fitForPurpose: "Fit-for-purpose review"
        }
    }
}

struct MaterialSelectionInput: Codable, Equatable {
    var candidateMaterialIDs: [String] = []
    var componentID = ""
    var serviceEnvironment = ""
    var operatingConditions = ""
    var designRequirements = ""
}

struct MaterialSelectionRule: Codable, Equatable {
    let version: Int
    let serviceEnvironment: String
    let operatingConditions: String
    let designRequirements: String
    let outcome: String // consider or exclude, only within this exact scope
    func validate() -> Bool {
        version == 1 && !serviceEnvironment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !operatingConditions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !designRequirements.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && ["consider", "exclude"].contains(outcome)
    }
}

struct VendorQualificationInput: Codable, Equatable {
    var vendor = ""
    var facility = ""
    var product = ""
    var materialID = ""
    var manufacturingRoute = ""
    var heatTreatment = ""
    var testing = ""
    var observations = ""
    var findings = ""
    var correctiveActions = ""
    var qualificationHistory = ""
}

struct FailureInvestigationInput: Codable, Equatable {
    var materialID = ""
    var componentID = ""
    var environment = ""
    var damageLocation = ""
    var morphology = ""
    var hardness = ""
    var metallography = ""
    var fractureFeatures = ""
    var chemistry = ""
    var operatingHistory = ""
    var observationsSupportingMechanisms = ""
    var observationsContradictingMechanisms = ""
    var candidateMechanismIDs: [String] = []
}

struct FitForPurposeInput: Codable, Equatable {
    var materialID = ""
    var componentID = ""
    var intendedService = ""
    var designBasis = ""
    var proposedDeviation = ""
    var acceptanceCriteria = ""
    var parameterValues = ""
    var standardIDs: [String] = []
}

/// An explicitly authored, source-backed requirement. Values are compared as
/// normalized text only; this contract performs no engineering calculation.
struct FitRequirementRule: Codable, Equatable {
    let version: Int
    let scope: String
    let field: String
    let expected: String
    func validate() -> Bool {
        version == 1 && !scope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !field.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !expected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct EngineeringWorkflowInput: Codable, Equatable {
    var workflow: EngineeringWorkflowKind = .degradation
    var degradation = AssessmentInput()
    var materialSelection = MaterialSelectionInput()
    var vendorQualification = VendorQualificationInput()
    var failureInvestigation = FailureInvestigationInput()
    var fitForPurpose = FitForPurposeInput()
}

struct EngineeringWorkflowResult {
    let workflow: EngineeringWorkflowKind
    let text: String
    let evidence: [AnswerEvidence]
    var claimIDs: [String] { evidence.map(\.id).sorted() }
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

/// Source-led workflows that organize local evidence without inventing material limits,
/// qualification verdicts, failure causes, or fitness decisions.
@MainActor struct EngineeringWorkflowAssessment {
    let store: KnowledgeStore
    private static let maxEvidence = 60
    private static let maxFieldLength = 4_000

    static func searchQuery(_ text: String) -> String {
        let ignored: Set<String> = ["and", "the", "with", "for", "from", "that", "this", "into", "using", "about", "local"]
        var seen = Set<String>()
        let terms = text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 1 && !ignored.contains($0) && seen.insert($0).inserted }
        return terms.prefix(48).joined(separator: " ")
    }

    func assess(_ input: EngineeringWorkflowInput) throws -> EngineeringWorkflowResult {
        switch input.workflow {
        case .degradation:
            let report = try DegradationAssessment(store: store).assess(input.degradation)
            let evidence = unique(report.context + report.mechanisms.flatMap(\.evidence))
            return EngineeringWorkflowResult(workflow: .degradation, text: report.text, evidence: evidence)
        case .materialSelection:
            return try materialSelection(input.materialSelection)
        case .vendorQualification:
            return try vendorQualification(input.vendorQualification)
        case .failureInvestigation:
            return try failureInvestigation(input.failureInvestigation)
        case .fitForPurpose:
            return try fitForPurpose(input.fitForPurpose)
        }
    }

    func explain(_ result: EngineeringWorkflowResult, provider: any LocalAIProvider) async throws -> [AnswerPoint] {
        let reviewed = result.evidence.filter { $0.claim.status == .reviewed || $0.claim.status == .verified }
        guard !reviewed.isEmpty else { return [] }
        let rag = LocalRAG(store: store, provider: provider)
        let prompt = rag.buildContext(
            question: "Summarize only what these stored claims state for this (result.workflow.title). Do not make a suitability, qualification, cause, risk, or acceptance decision. State uncertainty plainly.",
            evidence: Array(reviewed.prefix(LocalRAG.maxClaims))
        )
        return try rag.parse(try await provider.generate(prompt: prompt), evidence: Array(reviewed.prefix(LocalRAG.maxClaims)))
    }

    private func materialSelection(_ input: MaterialSelectionInput) throws -> EngineeringWorkflowResult {
        try validateFields([input.serviceEnvironment, input.operatingConditions, input.designRequirements])
        let graph = try KnowledgeGraph(store: store)
        let selectedIDs = Array(Set(input.candidateMaterialIDs)).sorted()
        let candidates = selectedIDs.compactMap { graph.records[$0] }.filter { $0.kind == .material }
        var gaps: [String] = []
        if candidates.count != selectedIDs.count { gaps.append("One or more selected candidates are missing or are not material records.") }
        if candidates.count < 2 { gaps.append("Select at least two stored materials for a comparison.") }
        if input.serviceEnvironment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { gaps.append("Service environment was not supplied.") }
        if input.operatingConditions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { gaps.append("Operating conditions were not supplied.") }
        if input.designRequirements.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { gaps.append("Design requirements were not supplied.") }
        let component = graph.records[input.componentID].flatMap { $0.kind == .component ? $0 : nil }
        if !input.componentID.isEmpty && component == nil { gaps.append("Selected component is missing or is not a component record.") }
        let context = [input.serviceEnvironment, input.operatingConditions, input.designRequirements, component?.name ?? ""].joined(separator: " ")
        var sections = ["LOCAL — material evidence comparison", "No material is ranked or recommended. Evidence coverage is not proof of suitability."]
        sections += ["Component: \(component?.name ?? "not selected")", "Service environment: \(emptyLabel(input.serviceEnvironment))", "Operating conditions: \(emptyLabel(input.operatingConditions))", "Design requirements: \(emptyLabel(input.designRequirements))"]
        var evidenceSubjects = Set(selectedIDs + (component.map { [$0.id] } ?? []))
        for id in selectedIDs {
            let linked = graph.neighbors(id).flatMap { [$0.from, $0.to] }
            evidenceSubjects.formUnion(linked.filter { graph.records[$0]?.kind == .mechanism })
        }
        let allEvidence = try evidence(subjectIDs: evidenceSubjects, query: context, graph: graph)
            .filter { evidenceSubjects.contains($0.claim.subjectID) }
        for material in candidates {
            sections.append("\n\(material.name) [\(material.id)] — candidate only")
            let relatedMechanisms = Set(graph.neighbors(material.id).flatMap { [$0.from, $0.to] }.filter { graph.records[$0]?.kind == .mechanism })
            let relatedEvidence = allEvidence.filter { $0.claim.subjectID == material.id || relatedMechanisms.contains($0.claim.subjectID) }
            if relatedEvidence.isEmpty { sections.append("No matching source-backed claims were found in the selected local context.") }
            sections += relatedEvidence.map { evidenceLine($0, category: selectionCategory($0.claim.predicate)) }
            let scopedRules = graph.claims.values.filter { $0.subjectID == material.id && $0.predicate == "material_selection_rule" && active($0) }.sorted { $0.id < $1.id }
            var matchedOutcomes: Set<String> = []
            for claim in scopedRules {
                guard let rule = try? JSONDecoder().decode(MaterialSelectionRule.self, from: Data(claim.notes.utf8)), rule.validate() else {
                    sections.append("Invalid material-selection rule in claim [\(claim.id)]; not evaluated.")
                    continue
                }
                guard claim.status == .reviewed || claim.status == .verified else {
                    sections.append("Material-selection rule [\(claim.id)] \(claim.status.title): not applied until reviewed.")
                    continue
                }
                guard scopeKey(rule.serviceEnvironment) == scopeKey(input.serviceEnvironment),
                      scopeKey(rule.operatingConditions) == scopeKey(input.operatingConditions),
                      scopeKey(rule.designRequirements) == scopeKey(input.designRequirements) else {
                    sections.append("Material-selection rule [\(claim.id)] \(claim.status.title): not applied because the entered scope does not exactly match the stored scope.")
                    continue
                }
                matchedOutcomes.insert(rule.outcome)
                let result = rule.outcome == "exclude"
                    ? "Explicitly excluded only within this exact reviewed source scope; confirm before rejecting the candidate."
                    : "Supported for consideration only within this exact reviewed source scope; not an approval."
                sections.append("Stored rule [\(claim.id)] \(claim.status.title): \(result)")
            }
            if matchedOutcomes.count > 1 {
                sections.append("Conflicting explicit selection rules match this scope; no candidate disposition is produced.")
            } else if scopedRules.isEmpty {
                sections.append("No explicit reviewed material-selection rule matches the supplied scope.")
            } else if matchedOutcomes.isEmpty {
                sections.append("No reviewed material-selection rule matched the entered scope.")
            }
            let adjacentEdges = graph.neighbors(material.id)
            let adjacentIDs = Set(adjacentEdges.flatMap { edge -> [String] in [edge.from, edge.to] })
            let standards = adjacentIDs.compactMap { graph.records[$0] }
                .filter { $0.kind == .standard }
                .sorted { $0.name < $1.name }
            sections += standards.map { "Stored standard reference to review: \($0.name) [\($0.id)]" }
        }
        sections += gaps.map { "Gap: \($0)" }
        sections.append("Interpret each claim against its recorded conditions and source. No property normalization, threshold comparison, optimization, or automatic rejection is performed.")
        return EngineeringWorkflowResult(workflow: .materialSelection, text: sections.joined(separator: "\n"), evidence: allEvidence)
    }

    private func vendorQualification(_ input: VendorQualificationInput) throws -> EngineeringWorkflowResult {
        try validateFields([input.vendor, input.facility, input.product, input.manufacturingRoute, input.heatTreatment, input.testing, input.observations, input.findings, input.correctiveActions, input.qualificationHistory])
        let graph = try KnowledgeGraph(store: store)
        let material = graph.records[input.materialID].flatMap { $0.kind == .material ? $0 : nil }
        var gaps: [String] = []
        if input.vendor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { gaps.append("Vendor is missing.") }
        if input.facility.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { gaps.append("Facility is missing.") }
        if input.product.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { gaps.append("Product is missing.") }
        if material == nil { gaps.append("Select a stored material or record why no material was selected.") }
        if input.manufacturingRoute.isEmpty { gaps.append("Manufacturing route is not recorded.") }
        if input.heatTreatment.isEmpty { gaps.append("Heat treatment is not recorded.") }
        if input.testing.isEmpty { gaps.append("Testing performed is not recorded.") }
        if input.observations.isEmpty { gaps.append("Observations are not recorded.") }
        let query = [input.vendor, input.facility, input.product, material?.name ?? "", input.manufacturingRoute, input.heatTreatment, input.testing].joined(separator: " ")
        let found = try evidence(subjectIDs: Set([material?.id].compactMap { $0 }), query: query, graph: graph)
        var sections = ["LOCAL — vendor qualification record", "This record organizes submitted information and local evidence. It does not approve or qualify a vendor."]
        sections += ["Vendor: \(emptyLabel(input.vendor))", "Facility: \(emptyLabel(input.facility))", "Product: \(emptyLabel(input.product))", "Material: \(material?.name ?? "not selected")", "Manufacturing route: \(emptyLabel(input.manufacturingRoute))", "Heat treatment: \(emptyLabel(input.heatTreatment))", "Testing: \(emptyLabel(input.testing))", "User observations: \(emptyLabel(input.observations))", "User findings: \(emptyLabel(input.findings))", "Corrective actions: \(emptyLabel(input.correctiveActions))", "Qualification history: \(emptyLabel(input.qualificationHistory))"]
        sections += evidenceSection(found)
        sections += gaps.map { "Gap: \($0)" }
        sections.append("Submitted findings and observations are user-provided and are not verified knowledge until separately sourced and reviewed.")
        return EngineeringWorkflowResult(workflow: .vendorQualification, text: sections.joined(separator: "\n"), evidence: found)
    }

    private func failureInvestigation(_ input: FailureInvestigationInput) throws -> EngineeringWorkflowResult {
        try validateFields([input.environment, input.damageLocation, input.morphology, input.hardness, input.metallography, input.fractureFeatures, input.chemistry, input.operatingHistory, input.observationsSupportingMechanisms, input.observationsContradictingMechanisms])
        let graph = try KnowledgeGraph(store: store)
        let material = graph.records[input.materialID].flatMap { $0.kind == .material ? $0 : nil }
        let component = graph.records[input.componentID].flatMap { $0.kind == .component ? $0 : nil }
        let directIDs = Set([material?.id, component?.id].compactMap { $0 })
        let linkedMechanisms = Set(graph.edges.filter { directIDs.contains($0.from) || directIDs.contains($0.to) }.flatMap { [$0.from, $0.to] }.filter { graph.records[$0]?.kind == .mechanism })
        let chosenMechanisms = Set(input.candidateMechanismIDs).union(linkedMechanisms).filter { graph.records[$0]?.kind == .mechanism }
        var gaps: [String] = []
        if material == nil { gaps.append("Select a stored material or document that it is unknown.") }
        if component == nil { gaps.append("Select a stored component or document that it is unknown.") }
        if input.environment.isEmpty { gaps.append("Environment and operating chemistry are incomplete.") }
        if input.damageLocation.isEmpty { gaps.append("Damage location is missing.") }
        if input.morphology.isEmpty { gaps.append("Damage morphology is missing.") }
        if input.hardness.isEmpty { gaps.append("Hardness data is missing.") }
        if input.metallography.isEmpty { gaps.append("Metallography is missing.") }
        if input.fractureFeatures.isEmpty { gaps.append("Fracture-feature observations are missing.") }
        if input.chemistry.isEmpty { gaps.append("Chemistry data is missing.") }
        if input.operatingHistory.isEmpty { gaps.append("Operating history is missing.") }
        if input.observationsSupportingMechanisms.isEmpty { gaps.append("No user-identified observations supporting candidate mechanisms were entered.") }
        if input.observationsContradictingMechanisms.isEmpty { gaps.append("No user-identified observations contradicting candidate mechanisms were entered.") }
        let query = [input.environment, input.damageLocation, input.morphology, input.hardness, input.metallography, input.fractureFeatures, input.chemistry, input.operatingHistory].joined(separator: " ")
        let subjectIDs = directIDs.union(chosenMechanisms)
        let found = try evidence(subjectIDs: subjectIDs, query: query, graph: graph)
        var sections = ["LOCAL — failure investigation record", "Candidate mechanisms are navigation leads from stored relationships or explicit user selection, not diagnosed causes."]
        sections += ["Material: \(material?.name ?? "unknown / not selected")", "Component: \(component?.name ?? "unknown / not selected")", "Environment: \(emptyLabel(input.environment))", "Damage location: \(emptyLabel(input.damageLocation))", "Morphology: \(emptyLabel(input.morphology))", "Hardness: \(emptyLabel(input.hardness))", "Metallography: \(emptyLabel(input.metallography))", "Fracture features: \(emptyLabel(input.fractureFeatures))", "Chemistry: \(emptyLabel(input.chemistry))", "Operating history: \(emptyLabel(input.operatingHistory))"]
        sections.append("User-identified supporting observations: \(emptyLabel(input.observationsSupportingMechanisms))")
        sections.append("User-identified contradicting observations: \(emptyLabel(input.observationsContradictingMechanisms))")
        sections.append("Candidate mechanisms (not conclusions):")
        if chosenMechanisms.isEmpty { sections.append("No directly connected or explicitly selected mechanism was found.") }
        for id in chosenMechanisms.sorted() { if let record = graph.records[id] { sections.append("• \(record.name) [\(id)]") } }
        sections += evidenceSection(found)
        sections += gaps.map { "Gap: \($0)" }
        sections.append("Human metallurgical review is required to determine whether any observation supports or contradicts a mechanism. No cause is assigned and no likelihood is calculated.")
        return EngineeringWorkflowResult(workflow: .failureInvestigation, text: sections.joined(separator: "\n"), evidence: found)
    }

    private func fitForPurpose(_ input: FitForPurposeInput) throws -> EngineeringWorkflowResult {
        try validateFields([input.intendedService, input.designBasis, input.proposedDeviation, input.acceptanceCriteria, input.parameterValues])
        let graph = try KnowledgeGraph(store: store)
        let material = graph.records[input.materialID].flatMap { $0.kind == .material ? $0 : nil }
        let component = graph.records[input.componentID].flatMap { $0.kind == .component ? $0 : nil }
        let standards = Array(Set(input.standardIDs)).compactMap { graph.records[$0] }.filter { $0.kind == .standard }.sorted { $0.name < $1.name }
        var gaps: [String] = []
        if material == nil { gaps.append("Select the material or document that it is unknown.") }
        if component == nil { gaps.append("Select the component or document that it is unknown.") }
        if input.intendedService.isEmpty { gaps.append("Intended service is missing.") }
        if input.designBasis.isEmpty { gaps.append("Design basis is missing.") }
        if input.proposedDeviation.isEmpty { gaps.append("Proposed deviation or condition is missing.") }
        if input.acceptanceCriteria.isEmpty { gaps.append("Applicable acceptance criteria have not been supplied.") }
        if standards.isEmpty { gaps.append("No stored standard was selected; applicability and current revision need human confirmation.") }
        let query = [input.intendedService, input.designBasis, input.proposedDeviation, input.acceptanceCriteria, standards.map(\.name).joined(separator: " ")].joined(separator: " ")
        let ids = Set([material?.id, component?.id].compactMap { $0 } + standards.map(\.id))
        let found = try evidence(subjectIDs: ids, query: query, graph: graph)
        let suppliedValues = try parseParameterValues(input.parameterValues)
        let activeClaims = graph.claims.values.filter { ids.contains($0.subjectID) && active($0) && $0.predicate == "fit_for_purpose_requirement" }.sorted { $0.id < $1.id }
        var requirementLines: [String] = ["\nStored fit-for-purpose requirements (exact text checks only):"]
        if activeClaims.isEmpty { requirementLines.append("No explicit fit_for_purpose_requirement claims are stored for the selected records.") }
        for claim in activeClaims {
            guard let rule = try? JSONDecoder().decode(FitRequirementRule.self, from: Data(claim.notes.utf8)), rule.validate() else {
                requirementLines.append("Claim [\(claim.id)] has an invalid requirement rule and was not evaluated.")
                continue
            }
            guard claim.status == .reviewed || claim.status == .verified else {
                requirementLines.append("Claim [\(claim.id)] \(claim.status.title): not evaluated until reviewed.")
                continue
            }
            guard scopeKey(rule.scope) == scopeKey(input.intendedService) else {
                requirementLines.append("Claim [\(claim.id)] \(claim.status.title): not evaluated; intended-service scope does not exactly match the stored scope.")
                continue
            }
            guard let observed = suppliedValues[scopeKey(rule.field)] else {
                requirementLines.append("Claim [\(claim.id)] \(claim.status.title): \(rule.field) is missing; stored value is \(rule.expected).")
                continue
            }
            if scopeKey(observed) == scopeKey(rule.expected) {
                requirementLines.append("Claim [\(claim.id)] \(claim.status.title): \(rule.field) matches the exact stored text \(rule.expected); this is not a fit verdict.")
            } else {
                requirementLines.append("Claim [\(claim.id)] \(claim.status.title): \(rule.field) differs from the exact stored text \(rule.expected); human review is required.")
            }
        }
        var sections = ["LOCAL — fit-for-purpose evidence review", "No fit, acceptance, or compliance verdict is generated. Compare the proposed case with controlled source requirements and obtain responsible engineering approval."]
        sections += ["Material: \(material?.name ?? "unknown / not selected")", "Component: \(component?.name ?? "unknown / not selected")", "Intended service: \(emptyLabel(input.intendedService))", "Design basis: \(emptyLabel(input.designBasis))", "Proposed deviation / condition: \(emptyLabel(input.proposedDeviation))", "User-supplied acceptance criteria: \(emptyLabel(input.acceptanceCriteria))", "Parameter values supplied as key = value: \(emptyLabel(input.parameterValues))", "Standards selected for review: \(standards.map(\.name).joined(separator: ", ").isEmpty ? "none" : standards.map(\.name).joined(separator: ", "))"]
        sections += requirementLines
        sections += evidenceSection(found)
        sections += gaps.map { "Gap: \($0)" }
        sections.append("Stored claim conditions, status, source and locator remain controlling context. This workflow does not establish the governing code edition or interpret unprovided requirements.")
        return EngineeringWorkflowResult(workflow: .fitForPurpose, text: sections.joined(separator: "\n"), evidence: found)
    }

    private func evidence(subjectIDs: Set<String>, query: String, graph: KnowledgeGraph) throws -> [AnswerEvidence] {
        var claimIDs = Set(graph.claims.values.filter { subjectIDs.contains($0.subjectID) && active($0) }.map(\.id))
        for relationship in graph.edges where subjectIDs.contains(relationship.from) || subjectIDs.contains(relationship.to) {
            if let id = relationship.claimID, graph.claims[id].map(active) == true { claimIDs.insert(id) }
        }
        let cleanedQuery = Self.searchQuery(String(query.prefix(16_000)))
        if !cleanedQuery.isEmpty {
            for hit in try store.search(cleanedQuery).prefix(50) {
                if hit.entityType == .claim { claimIDs.insert(hit.id) }
                else if hit.entityType == .record {
                    claimIDs.formUnion(graph.claims.values.filter { active($0) && ($0.subjectID == hit.id || $0.sourceID == hit.id) }.map(\.id))
                }
            }
        }
        return claimIDs.sorted().prefix(Self.maxEvidence).compactMap { id in
            guard let claim = graph.claims[id], active(claim),
                  let subject = graph.records[claim.subjectID], let source = graph.records[claim.sourceID] else { return nil }
            return AnswerEvidence(claim: claim, subject: subject, source: source)
        }
    }

    private func active(_ claim: EngineeringClaim) -> Bool { claim.status != .archived && claim.status != .superseded }
    private func unique(_ evidence: [AnswerEvidence]) -> [AnswerEvidence] {
        var seen = Set<String>()
        return evidence.filter { seen.insert($0.id).inserted }.sorted { $0.id < $1.id }
    }
    private func evidenceSection(_ evidence: [AnswerEvidence]) -> [String] {
        guard !evidence.isEmpty else { return ["\nLocal evidence: no matching source-backed claims were found."] }
        return ["\nLocal evidence:"] + evidence.map { evidenceLine($0) }
    }
    private func evidenceLine(_ item: AnswerEvidence, category: String? = nil) -> String {
        let label = category.map { " · \($0)" } ?? ""
        let locator = item.claim.locator.isEmpty ? "locator not recorded" : item.claim.locator
        let conditions = item.claim.conditions.isEmpty ? "conditions not recorded" : item.claim.conditions
        return "Claim [\(item.id)] \(item.claim.status.title)\(label) · \(item.subject.name): \(item.claim.statement) | Conditions: \(conditions) | Source: \(item.source.name) [\(item.source.id)] · \(locator)"
    }
    private func selectionCategory(_ predicate: String) -> String? {
        switch predicate {
        case "selection_advantage": "stored advantage claim"
        case "selection_limit": "stored limitation claim"
        case "selection_exclusion": "stored exclusion claim; review its exact scope"
        default: nil
        }
    }
    private func emptyLabel(_ value: String) -> String {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "not supplied" : value
    }
    private func validateFields(_ fields: [String]) throws {
        guard fields.allSatisfy({ $0.count <= Self.maxFieldLength }) else {
            throw KnowledgeStoreError(message: "Each workflow field is limited to 4,000 characters.")
        }
    }
    private func parseParameterValues(_ text: String) throws -> [String: String] {
        var values: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { throw KnowledgeStoreError(message: "Enter fit-for-purpose parameter values one per line as key = value.") }
            let key = scopeKey(String(parts[0])), value = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !value.isEmpty else { throw KnowledgeStoreError(message: "Fit-for-purpose parameter keys and values cannot be blank.") }
            guard values[key] == nil else { throw KnowledgeStoreError(message: "Each fit-for-purpose parameter key must appear only once.") }
            values[key] = value
        }
        return values
    }
    private func scopeKey(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
