import SwiftUI
struct AgentPage: View {
    let store: KnowledgeStore
    @State private var task = "Assess degradation for the selected material and component"
    @State private var request = EngineeringWorkflowInput()
    @State private var temperature = ""
    @State private var pressure = ""
    @State private var mode: AgentMode = .local
    @State private var explain = false
    @State private var busy = false
    @State private var run: AgentRun?
    @State private var history: [AgentRun] = []
    @State private var records: [KnowledgeRecord] = []
    @State private var error = ""
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: MITheme.Space.page) {
            PageHeader(title: "Engineering Agent", subtitle: "Bounded local workflows over stored knowledge and source-linked evidence")
            Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) {
                Picker("Mode", selection: $mode) { ForEach(AgentMode.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) } }.pickerStyle(.segmented)
                Text(mode == .local ? "LOCAL · database, deterministic tools and optional on-device explanation. No internet." : "RESEARCH · create a research brief only. External findings must pass Research ingestion and review.").font(MITheme.Typography.metadata)
                Picker("Workflow", selection: $request.workflow) {
                    ForEach(EngineeringWorkflowKind.allCases) { workflow in Text(workflow.title).tag(workflow) }
                }.pickerStyle(.menu)
                TextField("Describe the engineering task", text: $task, axis: .vertical).lineLimit(2...5)
                EngineeringWorkflowFieldSet(request: $request, temperature: $temperature, pressure: $pressure, records: records)
                Text("Structured fields control evaluation. Task prose does not silently set conditions. The agent cannot edit knowledge.").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
                Toggle("Add optional local AI explanation", isOn: $explain)
                Button(mode == .local ? "Run local workflow" : "Prepare research handoff", action: submit).buttonStyle(.borderedProminent).disabled(busy || task.isEmpty)
            } }
            if busy { ProgressView("Running local tools…") }
            if !error.isEmpty { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(MITheme.danger) }
            if let run {
                Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) {
                    Text("\((run.workflow ?? .degradation).title) · \(run.mode.rawValue.uppercased()) · \(run.state)").font(MITheme.Typography.sectionTitle)
                    Text(run.report).textSelection(.enabled)
                    ForEach(run.explanation, id: \.self) { Text($0).foregroundStyle(.secondary) }
                    DisclosureGroup("Tools and evidence audit") {
                        ForEach(run.events) { event in Text("\(event.tool.rawValue): \(event.summary)").frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, MITheme.Space.tight) }
                        Text("Claim IDs: \(run.claimIDs.joined(separator: ", "))").font(MITheme.Typography.metadata).textSelection(.enabled)
                        if let snapshot = run.requestSnapshot { Text("Structured input: \(snapshot)").font(MITheme.Typography.metadata).textSelection(.enabled) }
                    }
                    ForEach(run.claimIDs, id: \.self) { id in if let claim = try? store.claim(id: id) { RelatedKnowledgeButton(store: store, recordID: claim.subjectID, claimID: id) } }
                    ShareLink("Export report / research brief", item: run.report)
                } }
            }
            Panel { VStack(alignment: .leading, spacing: MITheme.Space.compact) { Text("Local workflow history").font(MITheme.Typography.sectionTitle); ForEach(history) { item in Button("\((item.workflow ?? .degradation).title) · \(item.createdAt) · \(item.state) · \(item.task)") { restore(item) } } } }
        }.font(MITheme.Typography.body).padding(MITheme.pageInset) }.background(MITheme.canvas).task { do { records = try store.records(); history = try store.agentRuns() } catch { self.error = error.localizedDescription } }
    }
    private func submit() {
        guard request.workflow != .degradation || ((temperature.isEmpty || Double(temperature) != nil) && (pressure.isEmpty || Double(pressure) != nil)) else { error = "Enter numeric conditions or leave unknown fields blank."; return }
        request.degradation.temperatureC = Double(temperature); request.degradation.pressureMPa = Double(pressure)
        let task = task, request = request, mode = mode, explain = explain
        busy = true; error = ""
        Task { defer { busy = false }; do { run = try await EngineeringAgent(store: store).run(task: task, input: request.degradation, workflowInput: request, mode: mode, explain: explain); history = try store.agentRuns() } catch { self.error = error.localizedDescription } }
    }

    private func restore(_ item: AgentRun) {
        run = item
        task = item.task
        if let snapshot = item.requestSnapshot, let data = snapshot.data(using: .utf8), let decoded = try? JSONDecoder().decode(EngineeringWorkflowInput.self, from: data) {
            request = decoded
            temperature = decoded.degradation.temperatureC.map { String($0) } ?? ""
            pressure = decoded.degradation.pressureMPa.map { String($0) } ?? ""
        } else { request.workflow = item.workflow ?? .degradation }
    }
}
