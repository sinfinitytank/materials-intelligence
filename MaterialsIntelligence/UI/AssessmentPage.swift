import SwiftUI

struct EngineeringWorkflowFieldSet: View {
    @Binding var request: EngineeringWorkflowInput
    @Binding var temperature: String
    @Binding var pressure: String
    let records: [KnowledgeRecord]

    var body: some View {
        Group {
            switch request.workflow {
            case .degradation:
                recordPicker("Material", kind: .material, selection: $request.degradation.materialID)
                recordPicker("Component", kind: .component, selection: $request.degradation.componentID)
                TextField("Environment / chemistry (exact stored rule scope)", text: $request.degradation.environment)
                HStack {
                    TextField("Temperature °C", text: $temperature)
                    TextField("Pressure MPa", text: $pressure)
                }
                TextField("Operating context and user assumptions", text: $request.degradation.notes, axis: .vertical).lineLimit(2...4)
                Text("Only reviewed, source-backed explicit rules can match. Unmatched conditions remain unresolved.")
                .font(MITheme.Typography.metadata).foregroundStyle(.secondary)
            case .materialSelection:
                Text("Choose at least two candidates. This compares stored evidence coverage and does not rank or approve a material.")
                    .font(MITheme.Typography.metadata).foregroundStyle(.secondary)
                multiRecordPicker("Candidate materials", records: records.filter { $0.kind == .material }, selection: Binding(
                    get: { Set(request.materialSelection.candidateMaterialIDs) },
                    set: { request.materialSelection.candidateMaterialIDs = $0.sorted() }
                ))
                recordPicker("Component", kind: .component, selection: $request.materialSelection.componentID)
                TextField("Service environment", text: $request.materialSelection.serviceEnvironment)
                TextField("Operating conditions", text: $request.materialSelection.operatingConditions, axis: .vertical).lineLimit(2...4)
                TextField("Design requirements", text: $request.materialSelection.designRequirements, axis: .vertical).lineLimit(2...4)
            case .vendorQualification:
                TextField("Vendor", text: $request.vendorQualification.vendor)
                TextField("Facility", text: $request.vendorQualification.facility)
                TextField("Product", text: $request.vendorQualification.product)
                recordPicker("Material", kind: .material, selection: $request.vendorQualification.materialID)
                TextField("Manufacturing route", text: $request.vendorQualification.manufacturingRoute, axis: .vertical).lineLimit(1...3)
                TextField("Heat treatment", text: $request.vendorQualification.heatTreatment, axis: .vertical).lineLimit(1...3)
                TextField("Testing performed", text: $request.vendorQualification.testing, axis: .vertical).lineLimit(1...3)
                TextField("Observations", text: $request.vendorQualification.observations, axis: .vertical).lineLimit(2...4)
                TextField("Findings", text: $request.vendorQualification.findings, axis: .vertical).lineLimit(2...4)
                TextField("Corrective actions", text: $request.vendorQualification.correctiveActions, axis: .vertical).lineLimit(2...4)
                TextField("Qualification history", text: $request.vendorQualification.qualificationHistory, axis: .vertical).lineLimit(2...4)
                Text("Submitted vendor data is saved in local run history as user-provided information; no approval verdict is generated.")
                    .font(MITheme.Typography.metadata).foregroundStyle(.secondary)
            case .failureInvestigation:
                recordPicker("Material", kind: .material, selection: $request.failureInvestigation.materialID)
                recordPicker("Component", kind: .component, selection: $request.failureInvestigation.componentID)
                TextField("Environment and chemistry", text: $request.failureInvestigation.environment, axis: .vertical).lineLimit(1...3)
                TextField("Damage location", text: $request.failureInvestigation.damageLocation)
                TextField("Morphology", text: $request.failureInvestigation.morphology, axis: .vertical).lineLimit(1...3)
                TextField("Hardness data", text: $request.failureInvestigation.hardness)
                TextField("Metallography", text: $request.failureInvestigation.metallography, axis: .vertical).lineLimit(1...3)
                TextField("Fracture features", text: $request.failureInvestigation.fractureFeatures, axis: .vertical).lineLimit(1...3)
                TextField("Chemistry", text: $request.failureInvestigation.chemistry, axis: .vertical).lineLimit(1...3)
                TextField("Operating history", text: $request.failureInvestigation.operatingHistory, axis: .vertical).lineLimit(1...3)
                multiRecordPicker("Candidate mechanisms", records: records.filter { $0.kind == .mechanism }, selection: Binding(
                    get: { Set(request.failureInvestigation.candidateMechanismIDs) },
                    set: { request.failureInvestigation.candidateMechanismIDs = $0.sorted() }
                ))
                TextField("Observations you consider supportive", text: $request.failureInvestigation.observationsSupportingMechanisms, axis: .vertical).lineLimit(2...4)
                TextField("Observations you consider contradictory", text: $request.failureInvestigation.observationsContradictingMechanisms, axis: .vertical).lineLimit(2...4)
            case .fitForPurpose:
                recordPicker("Material", kind: .material, selection: $request.fitForPurpose.materialID)
                recordPicker("Component", kind: .component, selection: $request.fitForPurpose.componentID)
                TextField("Intended service", text: $request.fitForPurpose.intendedService, axis: .vertical).lineLimit(1...3)
                TextField("Design basis", text: $request.fitForPurpose.designBasis, axis: .vertical).lineLimit(1...3)
                TextField("Proposed deviation or condition", text: $request.fitForPurpose.proposedDeviation, axis: .vertical).lineLimit(1...3)
                TextField("Acceptance criteria to review", text: $request.fitForPurpose.acceptanceCriteria, axis: .vertical).lineLimit(1...3)
                TextField("Parameter values to compare (one key = value per line)", text: $request.fitForPurpose.parameterValues, axis: .vertical).lineLimit(2...5)
                multiRecordPicker("Standards to review", records: records.filter { $0.kind == .standard }, selection: Binding(
                    get: { Set(request.fitForPurpose.standardIDs) },
                    set: { request.fitForPurpose.standardIDs = $0.sorted() }
                ))
                Text("The selected standard revision and governing requirements need human confirmation. No compliance verdict is generated.")
                    .font(MITheme.Typography.metadata).foregroundStyle(.secondary)
            }
        }
    }

    private func recordPicker(_ title: String, kind: RecordKind, selection: Binding<String>) -> some View {
        Picker(title, selection: selection) {
            Text("Select \(title.lowercased())").tag("")
            ForEach(records.filter { $0.kind == kind }) { Text($0.name).tag($0.id) }
        }
    }

    private func multiRecordPicker(_ title: String, records choices: [KnowledgeRecord], selection: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: MITheme.Space.tight) {
            Text(title).font(MITheme.Typography.supporting.weight(.semibold))
            List(choices, selection: selection) { record in Text(record.name).tag(record.id) }
                .frame(height: min(max(CGFloat(choices.count) * 30, 60), 150))
                .overlay(RoundedRectangle(cornerRadius: MITheme.Radius.control).stroke(MITheme.separator))
            Text("\(selection.wrappedValue.count) selected").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
        }
    }
}

struct AssessmentPage: View {
    let store: KnowledgeStore
    @State private var request = EngineeringWorkflowInput()
    @State private var temperature = ""
    @State private var pressure = ""
    @State private var explain = false
    @State private var busy = false
    @State private var run: AgentRun?
    @State private var history: [AgentRun] = []
    @State private var records: [KnowledgeRecord] = []
    @State private var error = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MITheme.Space.page) {
                PageHeader(title: "Engineering Tools", subtitle: "Structured local workflows that preserve source evidence and expose missing information.")
                Panel {
                    VStack(alignment: .leading, spacing: MITheme.Space.regular) {
                        Picker("Workflow", selection: $request.workflow) {
                            ForEach(EngineeringWorkflowKind.allCases) { workflow in
                                Text(workflow.title).tag(workflow)
                            }
                        }
                        .pickerStyle(.menu)
                        EngineeringWorkflowFieldSet(request: $request, temperature: $temperature, pressure: $pressure, records: records)
                        Toggle("Add optional on-device AI explanation", isOn: $explain)
                        Text("LOCAL · SQLite, stored rules and evidence only. No internet or cloud model is used.")
                            .font(MITheme.Typography.metadata).foregroundStyle(.secondary)
                        Button(busy ? "Reviewing local evidence…" : "Run workflow locally", action: submit)
                            .buttonStyle(.borderedProminent).disabled(busy)
                    }
                }
                if busy { ProgressView("Retrieving source-linked knowledge…") }
                if !error.isEmpty { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(MITheme.danger) }
                if let run { resultView(run) }
                Panel {
                    VStack(alignment: .leading, spacing: MITheme.Space.compact) {
                        Text("Recent workflow history").font(MITheme.Typography.sectionTitle)
                        if history.isEmpty { Text("No local workflow runs yet.").foregroundStyle(.secondary) }
                        ForEach(history.prefix(20)) { item in
                            Button {
                                run = item
                                request.workflow = item.workflow ?? .degradation
                            } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(item.workflow?.title ?? "Degradation assessment").fontWeight(.medium)
                                    Text("· \(item.createdAt) · \(item.state)").foregroundStyle(.secondary)
                                    Spacer(minLength: 0)
                                    Text(item.task).lineLimit(1).foregroundStyle(.secondary)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }.font(MITheme.Typography.body).frame(maxWidth: 920, alignment: .leading).padding(MITheme.pageInset)
        }
        .background(MITheme.canvas)
        .task { refresh() }
    }

    private func resultView(_ run: AgentRun) -> some View {
        Group {
            Panel {
                VStack(alignment: .leading, spacing: MITheme.Space.regular) {
                    HStack {
                        Text("\((run.workflow ?? .degradation).title) · \(run.state)").font(MITheme.Typography.sectionTitle)
                        Spacer()
                        ShareLink("Export report", item: reportText(run))
                    }
                    Text(run.report).textSelection(.enabled)
                    ForEach(run.explanation, id: \.self) { Text($0).foregroundStyle(.secondary) }
                    DisclosureGroup("Workflow and evidence audit") {
                        ForEach(run.events) { event in
                            Text("\(event.tool.rawValue): \(event.summary)")
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, MITheme.Space.tight)
                        }
                        if let snapshot = run.requestSnapshot {
                            Text("Input snapshot: \(snapshot)").font(MITheme.Typography.metadata).textSelection(.enabled)
                        }
                    }
                }
            }
            if !run.claimIDs.isEmpty {
                Panel {
                    VStack(alignment: .leading, spacing: MITheme.Space.compact) {
                        Text("Open stored evidence").font(MITheme.Typography.sectionTitle)
                        ForEach(run.claimIDs, id: \.self) { id in
                            if let claim = try? store.claim(id: id) {
                                RelatedKnowledgeButton(store: store, recordID: claim.subjectID, claimID: id)
                            } else { Text("Claim \(id) is no longer available.").foregroundStyle(.secondary) }
                        }
                    }
                }
            }
        }
    }

    private func submit() {
        if request.workflow == .degradation {
            guard temperature.isEmpty || Double(temperature) != nil,
                  pressure.isEmpty || Double(pressure) != nil else {
                error = "Enter numeric conditions or leave unknown fields blank."
                return
            }
            request.degradation.temperatureC = Double(temperature)
            request.degradation.pressureMPa = Double(pressure)
        }
        let request = request
        let task = "Run the structured \(request.workflow.title.lowercased()) workflow using the supplied fields."
        let explain = explain
        busy = true; error = ""
        Task { @MainActor in
            defer { busy = false }
            do {
                let item = try await EngineeringAgent(store: store).run(
                    task: task, input: request.degradation, workflowInput: request, explain: explain
                )
                run = item
                refresh()
            } catch { self.error = error.localizedDescription }
        }
    }

    private func refresh() {
        do { records = try store.records(); history = try store.agentRuns() }
        catch { self.error = error.localizedDescription }
    }

    private func reportText(_ run: AgentRun) -> String {
        (["\((run.workflow ?? .degradation).title) — \(run.state)", run.report] + run.explanation).joined(separator: "\n\n")
    }
}
