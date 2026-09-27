import SwiftUI

struct AssessmentPage: View {
    let store: KnowledgeStore
    @State private var input = AssessmentInput()
    @State private var temperature = ""
    @State private var pressure = ""
    @State private var report: DegradationReport?
    @State private var points: [AnswerPoint] = []
    @State private var error = ""
    @State private var loading = false
    @State private var records: [KnowledgeRecord] = []
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Degradation Assessment", subtitle: "LOCAL · deterministic screening with inspectable evidence")
            Panel { VStack(alignment: .leading, spacing: 12) {
                Picker("Material", selection: $input.materialID) { Text("Select material").tag(""); ForEach(records.filter { $0.kind == .material }) { Text($0.name).tag($0.id) } }
                Picker("Component", selection: $input.componentID) { Text("Select component").tag(""); ForEach(records.filter { $0.kind == .component }) { Text($0.name).tag($0.id) } }
                TextField("Environment / chemistry (exact stored rule scope)", text: $input.environment)
                HStack { TextField("Temperature °C", text: $temperature); TextField("Pressure MPa", text: $pressure) }
                TextField("Operating context and user assumptions", text: $input.notes, axis: .vertical)
                Button("Assess locally", action: assess).buttonStyle(.borderedProminent)
            } }
            if !error.isEmpty { Text(error).foregroundStyle(.orange) }
            if let report {
                Panel { VStack(alignment: .leading, spacing: 10) {
                    Text("Assessment snapshot").font(.headline)
                    Text("Inputs are captured when Assess is pressed. Reassess after edits.").font(.caption).foregroundStyle(.secondary)
                    Text(report.text).textSelection(.enabled)
                    ShareLink("Export assessment", item: report.text)
                } }
                ForEach(report.mechanisms) { item in
                    Panel { VStack(alignment: .leading, spacing: 8) { Text(item.record.name).font(.headline); Text(item.conclusion); RelatedKnowledgeButton(store: store, recordID: item.id)
                        ForEach(item.evidence) { evidence in RelatedKnowledgeButton(store: store, recordID: evidence.claim.subjectID, claimID: evidence.id) }
                    } }
                }
                Button("Explain evidence with local AI") { explain(report) }.disabled(loading)
                if loading { ProgressView() }
                if !points.isEmpty { Panel { VStack(alignment: .leading, spacing: 8) { Text("AI explanation — unverified inference").font(.headline); ForEach(points) { point in Text(point.text); ForEach(point.evidence) { item in Text("[\(item.id)] \(item.source.name) · \(item.claim.locator)").font(.caption) } } } } }
            }
        }.padding(MITheme.pageInset) }.background(MITheme.canvas).task { do { records = try store.records() } catch { self.error = error.localizedDescription } }
    }
    private func assess() {
        do {
            guard temperature.isEmpty || Double(temperature) != nil, pressure.isEmpty || Double(pressure) != nil else { throw KnowledgeStoreError(message: "Enter numeric conditions or leave unknown fields blank.") }
            input.temperatureC = Double(temperature); input.pressureMPa = Double(pressure)
            report = try DegradationAssessment(store: store).assess(input); points = []; error = ""
        } catch { self.error = error.localizedDescription; report = nil; points = [] }
    }
    private func explain(_ report: DegradationReport) {
        loading = true; points = []; error = ""
        Task { defer { loading = false }; do { points = try await DegradationAssessment(store: store).explain(report, provider: AppleLocalProvider()); if points.isEmpty { error = "Insufficient reviewed evidence for an AI explanation." } } catch { self.error = error.localizedDescription } }
    }
}
