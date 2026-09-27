import SwiftUI
struct AgentPage: View {
    let store: KnowledgeStore
    @State private var task = "Assess degradation for the selected material and component"
    @State private var input = AssessmentInput()
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
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Engineering Agent", subtitle: "Controlled evidence-backed degradation assessment")
            Panel { VStack(alignment: .leading, spacing: 10) {
                Picker("Mode", selection: $mode) { ForEach(AgentMode.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) } }.pickerStyle(.segmented)
                Text(mode == .local ? "LOCAL · database, deterministic tools and optional on-device explanation. No internet." : "RESEARCH · create a research brief only. External findings must pass Research ingestion and review.").font(.caption)
                TextField("Describe a degradation assessment", text: $task, axis: .vertical).lineLimit(2...5)
                Picker("Material", selection: $input.materialID) { Text("Resolve from task or report missing").tag(""); ForEach(records.filter { $0.kind == .material }) { Text($0.name).tag($0.id) } }
                Picker("Component", selection: $input.componentID) { Text("Resolve from task or report missing").tag(""); ForEach(records.filter { $0.kind == .component }) { Text($0.name).tag($0.id) } }
                TextField("Environment scope", text: $input.environment)
                HStack { TextField("Temperature °C", text: $temperature); TextField("Pressure MPa", text: $pressure) }
                TextField("Assumptions / operating context", text: $input.notes)
                Text("Structured fields control conditions. Task prose does not silently override them.").font(.caption).foregroundStyle(.secondary)
                Toggle("Add optional local AI explanation", isOn: $explain)
                Button(mode == .local ? "Run local assessment" : "Prepare research handoff", action: submit).buttonStyle(.borderedProminent).disabled(busy || task.isEmpty)
            } }
            if busy { ProgressView("Running local tools…") }
            if !error.isEmpty { Text(error).foregroundStyle(.orange) }
            if let run {
                Panel { VStack(alignment: .leading, spacing: 10) {
                    Text("\(run.mode.rawValue.uppercased()) · \(run.state)").font(.headline)
                    Text(run.report).textSelection(.enabled)
                    ForEach(run.explanation, id: \.self) { Text($0).foregroundStyle(.secondary) }
                    DisclosureGroup("Tools and evidence audit") { ForEach(run.events) { event in Text("\(event.tool.rawValue): \(event.summary)").frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4) }; Text("Claim IDs: \(run.claimIDs.joined(separator: ", "))").font(.caption).textSelection(.enabled) }
                    ForEach(run.claimIDs, id: \.self) { id in if let claim = try? store.claim(id: id) { RelatedKnowledgeButton(store: store, recordID: claim.subjectID, claimID: id) } }
                    ShareLink("Export report / research brief", item: run.report)
                } }
            }
            Panel { VStack(alignment: .leading, spacing: 8) { Text("Local task history").font(.headline); ForEach(history) { item in Button("\(item.createdAt) · \(item.state) · \(item.task)") { run = item } } } }
        }.padding(MITheme.pageInset) }.background(MITheme.canvas).task { do { records = try store.records(); history = try store.agentRuns() } catch { self.error = error.localizedDescription } }
    }
    private func submit() {
        guard temperature.isEmpty || Double(temperature) != nil, pressure.isEmpty || Double(pressure) != nil else { error = "Enter numeric conditions or leave unknown fields blank."; return }
        input.temperatureC = Double(temperature); input.pressureMPa = Double(pressure)
        let task = task, input = input, mode = mode, explain = explain
        busy = true; error = ""
        Task { defer { busy = false }; do { run = try await EngineeringAgent(store: store).run(task: task, input: input, mode: mode, explain: explain); history = try store.agentRuns() } catch { self.error = error.localizedDescription } }
    }
}
