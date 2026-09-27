import Foundation

@main @MainActor struct EngineeringWorkflowTests {
    static func check(_ value: @autoclosure () throws -> Bool, _ label: String) throws {
        guard try value() else { throw KnowledgeStoreError(message: label) }
    }

    static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "engineering-workflows-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "knowledge.sqlite")
        let store = try KnowledgeStore(url: url)
        let records = [
            KnowledgeRecord(id: "m1", kind: .material, name: "Synthetic Alloy A"),
            KnowledgeRecord(id: "m2", kind: .material, name: "Synthetic Alloy B"),
            KnowledgeRecord(id: "c", kind: .component, name: "Synthetic Valve"),
            KnowledgeRecord(id: "d", kind: .mechanism, name: "Synthetic Cracking"),
            KnowledgeRecord(id: "std", kind: .standard, name: "Synthetic Standard Revision X"),
            KnowledgeRecord(id: "s", kind: .source, name: "Synthetic Qualification Report")
        ]
        for record in records { try store.save(record) }
        try store.save(EngineeringClaim(id: "claim-a", subjectID: "m1", predicate: "selection_advantage", statement: "Synthetic evidence statement for candidate A", conditions: "synthetic condition", sourceID: "s", locator: "section 3", status: .reviewed))
        try store.save(EngineeringClaim(id: "claim-b", subjectID: "m2", predicate: "selection_limit", statement: "Synthetic evidence statement for candidate B", conditions: "other synthetic condition", sourceID: "s", locator: "table 4", status: .unverified))
        let considerRule = MaterialSelectionRule(version: 1, serviceEnvironment: "synthetic service", operatingConditions: "synthetic conditions", designRequirements: "synthetic criteria", outcome: "consider")
        let excludeRule = MaterialSelectionRule(version: 1, serviceEnvironment: "synthetic service", operatingConditions: "synthetic conditions", designRequirements: "synthetic criteria", outcome: "exclude")
        try store.save(EngineeringClaim(id: "select-a", subjectID: "m1", predicate: "material_selection_rule", statement: "Synthetic scoped consideration", sourceID: "s", locator: "rule A", status: .reviewed, notes: String(decoding: try JSONEncoder().encode(considerRule), as: UTF8.self)))
        try store.save(EngineeringClaim(id: "select-b", subjectID: "m2", predicate: "material_selection_rule", statement: "Synthetic scoped exclusion", sourceID: "s", locator: "rule B", status: .verified, notes: String(decoding: try JSONEncoder().encode(excludeRule), as: UTF8.self)))
        try store.save(EngineeringClaim(id: "claim-d", subjectID: "d", predicate: "observation", statement: "Synthetic mechanism context", sourceID: "s", locator: "figure 2", status: .verified))
        try store.save(KnowledgeRelationship(fromID: "m1", predicate: "context", toID: "d", supportingClaimID: "claim-d"))
        try store.save(KnowledgeRelationship(fromID: "m2", predicate: "context", toID: "d"))
        try store.save(KnowledgeRelationship(fromID: "m1", predicate: "references", toID: "std"))

        let service = EngineeringWorkflowAssessment(store: store)
        var request = EngineeringWorkflowInput(workflow: .materialSelection)
        request.materialSelection = MaterialSelectionInput(candidateMaterialIDs: ["m1", "m2"], componentID: "c", serviceEnvironment: "synthetic service", operatingConditions: "synthetic conditions", designRequirements: "synthetic criteria")
        let selection = try service.assess(request)
        try check(selection.claimIDs == ["claim-a", "claim-b", "claim-d", "select-a", "select-b"], "comparison evidence identity")
        try check(selection.text.contains("No material is ranked") && selection.text.contains("stored advantage claim") && selection.text.contains("Stored standard reference"), "comparison safety and categories")
        try check(selection.text.contains("Supported for consideration only within this exact reviewed source scope") && selection.text.contains("Explicitly excluded only within this exact reviewed source scope"), "scoped selection decisions")
        try check(selection.text.contains("Reviewed") && selection.text.contains("Unverified") && selection.text.contains("section 3") && selection.text.contains("table 4"), "comparison evidence traceability")
        var mismatchedSelection = request
        mismatchedSelection.materialSelection.serviceEnvironment = "different environment"
        let outOfScopeSelection = try service.assess(mismatchedSelection)
        try check(outOfScopeSelection.text.contains("No reviewed material-selection rule matched the entered scope") && !outOfScopeSelection.text.contains("Supported for consideration only within this exact reviewed source scope"), "selection rule exact scope")
        let conflictRule = MaterialSelectionRule(version: 1, serviceEnvironment: "synthetic service", operatingConditions: "synthetic conditions", designRequirements: "synthetic criteria", outcome: "exclude")
        try store.save(EngineeringClaim(id: "select-a-conflict", subjectID: "m1", predicate: "material_selection_rule", statement: "Synthetic conflicting selection outcome", sourceID: "s", locator: "rule conflict", status: .reviewed, notes: String(decoding: try JSONEncoder().encode(conflictRule), as: UTF8.self)))
        try check(try service.assess(request).text.contains("Conflicting explicit selection rules match this scope; no candidate disposition is produced"), "selection rule conflict")
        try store.deleteClaim(id: "select-a-conflict")

        request = EngineeringWorkflowInput(workflow: .vendorQualification)
        request.vendorQualification = VendorQualificationInput(vendor: "Synthetic Vendor", facility: "Plant 1", product: "Valve body", materialID: "m1", manufacturingRoute: "Forged", heatTreatment: "Submitted cycle", testing: "Tensile and NDE", observations: "Synthetic observation", findings: "Synthetic finding", correctiveActions: "Synthetic action", qualificationHistory: "Initial review")
        let vendor = try service.assess(request)
        try check(vendor.text.contains("does not approve or qualify") && vendor.text.contains("Synthetic Vendor") && vendor.text.contains("user-provided"), "vendor qualification boundary")
        try check(vendor.claimIDs.contains("claim-a") && vendor.text.contains("section 3"), "vendor source context")

        request = EngineeringWorkflowInput(workflow: .failureInvestigation)
        request.failureInvestigation = FailureInvestigationInput(materialID: "m1", componentID: "c", environment: "synthetic environment", damageLocation: "weld toe", morphology: "surface crack", hardness: "synthetic hardness", metallography: "synthetic micrograph", fractureFeatures: "synthetic feature", chemistry: "synthetic chemistry", operatingHistory: "synthetic history", observationsSupportingMechanisms: "user observation considered supportive", observationsContradictingMechanisms: "user observation considered contradictory", candidateMechanismIDs: ["d"])
        let failure = try service.assess(request)
        try check(failure.text.contains("Candidate mechanisms are navigation leads") && failure.text.contains("No cause is assigned") && failure.text.contains("user observation considered contradictory"), "failure investigation attribution")
        try check(failure.text.contains("Synthetic Cracking") && failure.claimIDs.contains("claim-d"), "failure candidate evidence")

        request = EngineeringWorkflowInput(workflow: .fitForPurpose)
        let fitRule = FitRequirementRule(version: 1, scope: "synthetic service", field: "heat treatment", expected: "solution annealed")
        try store.save(EngineeringClaim(id: "fit-rule", subjectID: "std", predicate: "fit_for_purpose_requirement", statement: "Synthetic explicit requirement", sourceID: "s", locator: "clause 9", status: .verified, notes: String(decoding: try JSONEncoder().encode(fitRule), as: UTF8.self)))
        request.fitForPurpose = FitForPurposeInput(materialID: "m1", componentID: "c", intendedService: "synthetic service", designBasis: "synthetic design basis", proposedDeviation: "synthetic deviation", acceptanceCriteria: "synthetic acceptance criteria", parameterValues: "heat treatment = solution annealed", standardIDs: ["std"])
        let fit = try service.assess(request)
        try check(fit.text.contains("No fit, acceptance, or compliance verdict") && fit.text.contains("Synthetic Standard Revision X") && fit.text.contains("does not establish the governing code edition") && fit.text.contains("matches the exact stored text"), "fit for purpose boundary and text check")
        var mismatchedFit = request
        mismatchedFit.fitForPurpose.parameterValues = "heat treatment = as received"
        try check(try service.assess(mismatchedFit).text.contains("differs from the exact stored text"), "fit-for-purpose mismatch flagged for review")
        mismatchedFit = request
        mismatchedFit.fitForPurpose.intendedService = "different service"
        try check(try service.assess(mismatchedFit).text.contains("intended-service scope does not exactly match"), "fit-for-purpose exact scope")

        request = EngineeringWorkflowInput(workflow: .vendorQualification)
        var persistedRequest = request
        persistedRequest.failureInvestigation.operatingHistory = "stale context from another workflow"
        let before = try VaultSnapshot(store: store).encoded()
        let saved = try await EngineeringAgent(store: store).run(task: "Review synthetic vendor submission", input: .init(), workflowInput: {
            var value = persistedRequest
            value.vendorQualification.vendor = "Synthetic Vendor"
            value.vendorQualification.facility = "Plant 1"
            value.vendorQualification.product = "Valve body"
            value.vendorQualification.materialID = "m1"
            return value
        }())
        try check(saved.workflow == .vendorQualification && saved.events.last?.tool == .vendorQualification, "agent workflow routing")
        try check(saved.requestSnapshot?.contains("Synthetic Vendor") == true && !((saved.requestSnapshot ?? "").contains("stale context from another workflow")) && saved.report.contains("Synthetic Vendor"), "workflow-scoped input snapshot")
        try check(try VaultSnapshot(store: store).encoded() == before, "workflow does not mutate knowledge")
        let unsupported = try await EngineeringAgent(store: store).run(task: "Write a purchase order", input: .init(), workflowInput: request)
        try check(unsupported.state == "unsupported task" && unsupported.events.isEmpty && !unsupported.report.contains("qualification record"), "workflow intent mismatch stopped")
        let reopened = try KnowledgeStore(url: url)
        let history = try reopened.agentRuns()
        let reopenedRun = history.first { $0.id == saved.id }
        try check(history.count == 2 && reopenedRun?.workflow == .vendorQualification && reopenedRun?.requestSnapshot?.contains("Plant 1") == true, "workflow audit persistence")

        let oldRunJSON = #"{"id":"old","createdAt":"2026-09-27T00:00:00Z","task":"legacy","mode":"local","state":"complete","events":[],"report":"old report","claimIDs":[],"explanation":[]}"#
        let legacy = try JSONDecoder().decode(AgentRun.self, from: Data(oldRunJSON.utf8))
        try check(legacy.workflow == nil && legacy.requestSnapshot == nil && legacy.report == "old report", "schema 6 agent-run history compatibility")

        var tooLarge = VendorQualificationInput()
        tooLarge.vendor = String(repeating: "x", count: 4_001)
        request = EngineeringWorkflowInput(workflow: .vendorQualification)
        request.vendorQualification = tooLarge
        do { _ = try service.assess(request); throw KnowledgeStoreError(message: "workflow field limit was not enforced") }
        catch let error as KnowledgeStoreError { try check(error.message.contains("4,000"), "workflow input bound") }

        print("Engineering workflow tests passed: material comparison, vendor qualification, failure investigation, fit-for-purpose, source traceability, local audit and legacy history")
    }
}
