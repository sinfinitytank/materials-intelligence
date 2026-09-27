import Foundation

enum AgentMode: String, Codable, CaseIterable { case local, research }
enum AgentTool: String, Codable, CaseIterable {
    case recordLookup, localSearch, graphTraversal, claimAndSourceRetrieval
    case degradationAssessment, materialComparison, vendorQualification, failureInvestigation, fitForPurpose
    case localExplanation, researchHandoff
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
    var workflow: EngineeringWorkflowKind? = nil
    var requestSnapshot: String? = nil
    var state = "started"
    var events: [AgentEvent] = []
    var report = ""
    var claimIDs: [String] = []
    var explanation: [String] = []
}
@MainActor struct EngineeringAgent {
    let store: KnowledgeStore
    /// Fixed, bounded workflow: the model cannot invent tools or mutate knowledge.
    func run(task: String, input: AssessmentInput, workflowInput: EngineeringWorkflowInput? = nil, mode: AgentMode = .local, explain: Bool = false, provider: any LocalAIProvider = AppleLocalProvider()) async throws -> AgentRun {
        var run = AgentRun(task: String(task.prefix(4000)), mode: mode)
        var request = workflowInput ?? EngineeringWorkflowInput()
        if workflowInput == nil { request.degradation = input }
        request = scopedRequest(request)
        run.workflow = request.workflow
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        if let data = try? encoder.encode(request) { run.requestSnapshot = String(decoding: data, as: UTF8.self) }
        try store.saveAgentRun(run)
        do {
            guard task.count <= 4000 else { throw KnowledgeStoreError(message: "Task exceeds 4000 characters") }
            if mode == .research {
                run.state = "research handoff"
                run.events = [AgentEvent(tool: .researchHandoff, summary: "No external access performed. Research must be obtained deliberately and imported through Research review.")]
                run.report = "Research brief: \(task)\nIdentify missing evidence, source titles/revisions and exact locators. Prepare a Phase 6 schema-v1 package. Import, review and commit through Research; new claims remain Unverified until reviewed. Do not share restricted work data externally."
            } else {
                let lower = task.lowercased()
                guard taskSupports(lower, workflow: request.workflow) else {
                    run.state = "unsupported task"
                    run.report = "The task does not match the selected \(request.workflow.title.lowercased()) workflow. Rephrase it or choose the matching workflow. No engineering conclusion was generated."
                    try store.saveAgentRun(run)
                    return run
                }
                if request.workflow == .degradation {
                    let records = try store.records()
                    var resolved = request.degradation
                    func uniqueMatch(_ kind: RecordKind) -> String {
                        let candidates = records.filter { $0.kind == kind && lower.contains($0.name.lowercased()) }
                        return candidates.count == 1 ? candidates[0].id : ""
                    }
                    if resolved.materialID.isEmpty { resolved.materialID = uniqueMatch(.material) }
                    if resolved.componentID.isEmpty { resolved.componentID = uniqueMatch(.component) }
                    request.degradation = resolved
                }
                let searchQuery = EngineeringWorkflowAssessment.searchQuery(task)
                let hits = searchQuery.isEmpty ? [] : try store.search(searchQuery)
                run.events.append(AgentEvent(tool: .recordLookup, summary: "Used explicit stable record selections; only the degradation workflow also resolves one exact stored-name match from task text."))
                run.events.append(AgentEvent(tool: .localSearch, summary: "Found \(hits.count) local FTS matches. Lexical matches are context only, not conclusions."))
                let graph = try KnowledgeGraph(store: store)
                let rootID = workflowRootID(request)
                let paths = graph.traverse(from: rootID, depth: 2, limit: 100)
                run.events.append(AgentEvent(tool: .graphTraversal, summary: "Inspected \(paths.paths.count) stored context paths; truncated: \(paths.truncated). Stored connections provide navigation context, not causation."))
                let service = EngineeringWorkflowAssessment(store: store)
                let report = try service.assess(request)
                run.claimIDs = report.claimIDs
                run.events.append(AgentEvent(tool: .claimAndSourceRetrieval, summary: "Resolved \(run.claimIDs.count) active claims to stored subjects and sources with exact status, conditions and locators."))
                run.events.append(AgentEvent(tool: tool(for: request.workflow), summary: toolSummary(for: report)))
                run.report = report.text
                if request.workflow == .degradation {
                    run.state = report.evidence.isEmpty ? "insufficient evidence" : "assessment with qualifications"
                    if request.degradation.materialID.isEmpty || request.degradation.componentID.isEmpty || request.degradation.environment.isEmpty {
                        run.state = "missing inputs"
                    }
                } else {
                    run.state = report.evidence.isEmpty ? "insufficient local evidence" : "evidence review with qualifications"
                }
                if explain {
                    do {
                        let points = try await service.explain(report, provider: provider)
                        run.explanation = points.map { "AI inference (unverified): \($0.text) [\($0.evidence.map(\.id).joined(separator: ", "))]" }
                        run.events.append(AgentEvent(tool: .localExplanation, summary: points.isEmpty ? "No grounded explanation available; deterministic evidence review retained." : "Local explanation returned validated citation IDs; semantic support requires engineering review."))
                    } catch { run.events.append(AgentEvent(tool: .localExplanation, summary: "Unavailable or invalid local explanation: \(error.localizedDescription). Deterministic evidence review retained.")) }
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

    private func workflowRootID(_ request: EngineeringWorkflowInput) -> String {
        switch request.workflow {
        case .degradation: request.degradation.materialID
        case .materialSelection: request.materialSelection.candidateMaterialIDs.sorted().first ?? request.materialSelection.componentID
        case .vendorQualification: request.vendorQualification.materialID
        case .failureInvestigation: request.failureInvestigation.materialID.isEmpty ? request.failureInvestigation.componentID : request.failureInvestigation.materialID
        case .fitForPurpose: request.fitForPurpose.materialID.isEmpty ? request.fitForPurpose.componentID : request.fitForPurpose.materialID
        }
    }

    private func tool(for workflow: EngineeringWorkflowKind) -> AgentTool {
        switch workflow {
        case .degradation: .degradationAssessment
        case .materialSelection: .materialComparison
        case .vendorQualification: .vendorQualification
        case .failureInvestigation: .failureInvestigation
        case .fitForPurpose: .fitForPurpose
        }
    }

    private func toolSummary(for report: EngineeringWorkflowResult) -> String {
        switch report.workflow {
        case .degradation: "Ran deterministic degradation screening; only reviewed source-backed explicit rules can match."
        case .materialSelection: "Compared stored claims for selected candidates; no material ranking or suitability verdict was generated."
        case .vendorQualification: "Recorded submitted qualification details and retrieved local evidence; no vendor approval verdict was generated."
        case .failureInvestigation: "Organized submitted observations, candidate mechanisms and local evidence; no failure cause was assigned."
        case .fitForPurpose: "Collected design basis, proposed deviation and source-backed context; no fit or compliance verdict was generated."
        }
    }

    private func taskSupports(_ task: String, workflow: EngineeringWorkflowKind) -> Bool {
        let terms: [String]
        switch workflow {
        case .degradation: terms = ["degradation", "corrosion", "damage", "cracking"]
        case .materialSelection: terms = ["material", "selection", "compare", "comparison"]
        case .vendorQualification: terms = ["vendor", "qualification", "qualify"]
        case .failureInvestigation: terms = ["failure", "investigation", "fracture"]
        case .fitForPurpose: terms = ["fit for purpose", "fit-for-purpose", "fitness", "deviation"]
        }
        return terms.contains(where: task.contains)
    }

    private func scopedRequest(_ input: EngineeringWorkflowInput) -> EngineeringWorkflowInput {
        var request = EngineeringWorkflowInput(workflow: input.workflow)
        switch input.workflow {
        case .degradation: request.degradation = input.degradation
        case .materialSelection: request.materialSelection = input.materialSelection
        case .vendorQualification: request.vendorQualification = input.vendorQualification
        case .failureInvestigation: request.failureInvestigation = input.failureInvestigation
        case .fitForPurpose: request.fitForPurpose = input.fitForPurpose
        }
        return request
    }
}
