import SwiftUI

struct PersonalVaultLauncher: View {
    @State private var store: KnowledgeStore?
    @State private var error = ""
    var body: some View { Group { if let store { PersonalVaultView(store: store) } else if !error.isEmpty { Text(error) } else { ProgressView() } }.task { do { store = try PersonalSync.openStore() } catch { self.error = error.localizedDescription } } }
}
struct PersonalVaultView: View {
    let store: KnowledgeStore
    @StateObject private var sync: PersonalSync
    @State private var refresh = UUID()
    @State private var targetID: String?
    @State private var selectedResult: SearchResult?
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var records: [KnowledgeRecord] = []
    @State private var consent = false
    @State private var question = ""
    @State private var answer: LocalAnswer?
    @State private var error = ""
    @State private var confirmRemote = false
    @State private var confirmLocal = false
    @State private var confirmRecovery = false
    @State private var adding = false
    @State private var name = ""
    @State private var kind: RecordKind = .material
    init(store: KnowledgeStore) { self.store = store; _sync = StateObject(wrappedValue: PersonalSync(store: store)) }
    var body: some View {
        TabView {
            NavigationSplitView(preferredCompactColumn: $compactColumn) {
                List {
                    Section("Personal / public vault · offline reference") {
                        Text("Keep restricted work data in the Mac local vault. This separate vault is eligible for your explicit iCloud opt-in.").font(.caption)
                    }
                    if query.isEmpty {
                        ForEach(records) { record in Button(record.name) { selectedResult = SearchResult(id: record.id, entityType: .record, title: record.name, detail: record.detail, kind: record.kind.rawValue, score: 0); compactColumn = .detail } }
                    } else {
                        ForEach(results) { result in
                            Button(result.title) { selectedResult = result; compactColumn = .detail }
                        }
                    }
                }.searchable(text: $query).onChange(of: query) { _, _ in reload() }
                .navigationTitle("Knowledge").toolbar { Button("Add reference") { adding = true }; Button("Refresh", action: reload) }
            } detail: { NavigationStack { if let selectedResult { PortableSearchDetail(store: store, result: selectedResult).id(selectedResult.id) } else { ContentUnavailableView("Select a reference", systemImage: "books.vertical") } } } .tabItem { Label("Reference", systemImage: "books.vertical") }
            NavigationStack {
                Form {
                    Section("LOCAL · on-device only") {
                        TextField("Ask about stored evidence", text: $question)
                        if let message = AppleLocalProvider().availabilityMessage { Text(message) }
                        Button("Ask locally") { Task { do { answer = try await LocalRAG(store: store, provider: AppleLocalProvider()).ask(question); error = "" } catch { self.error = error.localizedDescription } } }.disabled(question.isEmpty)
                    }
                    if let answer {
                        if let message = answer.message { Text(message) }
                        Section("AI explanation · unverified") { ForEach(answer.points) { Text($0.text) } }
                        Section("Evidence") { ForEach(answer.found) { item in NavigationLink("\(item.claim.statement) — \(item.claim.status.title)") { PortableClaimView(store: store, claim: item.claim) } } }
                    }
                    if !error.isEmpty { Text(error).foregroundStyle(.orange) }
                }.navigationTitle("Ask")
            }.tabItem { Label("Ask", systemImage: "questionmark.bubble") }
            NavigationStack {
                Form {
                    Section("Private iCloud · personal/public only") {
                        Toggle("I permit this vault to use my private iCloud", isOn: $consent)
                        Text(sync.status)
                        Button("Sync now") { Task { await sync.synchronize(consent: consent); reload() } }.disabled(!consent || sync.busy)
                        Text("Sync is explicit. Incoming changes require review. Local copies work offline. Files and device bookmarks do not sync.").font(.caption)
                    }
                    if sync.pending {
                        Section("Review incoming snapshot") {
                            Text(sync.review).font(.caption).textSelection(.enabled)
                            Button("Replace local with reviewed remote") { confirmRemote = true }.disabled(!consent || sync.busy)
                            Button("Keep local and replace remote") { confirmLocal = true }.disabled(!consent || sync.busy)
                        }
                    }
                    Section("Recovery") { Button("Restore saved pre-resolution snapshot") { confirmRecovery = true }.disabled(sync.busy) }
                    if !error.isEmpty { Text(error).foregroundStyle(.orange) }
                }.navigationTitle("Sync")
            }.tabItem { Label("Sync", systemImage: "arrow.triangle.2.circlepath") }
            #if os(macOS)
            ResearchPage(store: store).tabItem { Label("Research review", systemImage: "doc.badge.plus") }
            ClaimsPage(store: store, refresh: $refresh, targetID: $targetID).tabItem { Label("Claims", systemImage: "checkmark.seal") }
            RelationshipsPage(store: store, refresh: $refresh).tabItem { Label("Relationships", systemImage: "link") }
            #endif
        }
        .task { reload() }
        .sheet(isPresented: $adding) { NavigationStack { Form { Picker("Kind", selection: $kind) { ForEach(RecordKind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }; TextField("Name", text: $name); Button("Save") { do { try store.save(KnowledgeRecord(kind: kind, name: name)); name = ""; adding = false; reload() } catch { self.error = error.localizedDescription } }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty); Button("Cancel") { adding = false }; Text(error) }.navigationTitle("Add reference") }.frame(minWidth: 300, minHeight: 300) }
        .confirmationDialog("Replace local personal vault, including changed or deleted Verified claims? Recovery is retained.", isPresented: $confirmRemote) { Button("Apply reviewed remote", role: .destructive) { do { try sync.useRemote(); reload() } catch { self.error = error.localizedDescription } } }
        .confirmationDialog("Replace remote vault with this local snapshot? Other devices must review these changes.", isPresented: $confirmLocal) { Button("Use local snapshot", role: .destructive) { Task { await sync.keepLocal() } } }
        .confirmationDialog("Restore recovery snapshot locally? Current content will become the recovery snapshot.", isPresented: $confirmRecovery) { Button("Restore", role: .destructive) { do { try sync.restoreRecovery(); reload() } catch { self.error = error.localizedDescription } } }
    }
    private func reload() { do { records = try store.records(); results = query.isEmpty ? [] : try store.search(query) } catch { self.error = error.localizedDescription } }
}
struct PortableSearchDetail: View {
    let store: KnowledgeStore
    let result: SearchResult
    var body: some View {
        if result.entityType == .record, let record = try? store.record(id: result.id) { PortableRecordView(store: store, record: record) }
        else if result.entityType == .claim, let claim = try? store.claim(id: result.id) { PortableClaimView(store: store, claim: claim) }
        else { ScrollView { VStack(alignment: .leading) { Text(result.title).font(.title); Text(result.detail); Text("Document metadata only; file remains on its originating device.").foregroundStyle(.secondary) }.padding() } }
    }
}
struct PortableRecordView: View {
    let store: KnowledgeStore
    let record: KnowledgeRecord
    @State private var notes = ""
    @State private var message = ""
    var body: some View {
        Form {
            Section("Reference") { Text(record.secondary); TextField("Notes", text: $notes, axis: .vertical); Button("Save lightweight update") { do { var updated = record; updated.detail = notes; try store.save(updated); message = "Saved locally" } catch { message = error.localizedDescription } }; Text(message) }
            Section("Claims and evidence") { ForEach((try? store.claims(subjectID: record.id)) ?? []) { claim in NavigationLink(claim.statement) { PortableClaimView(store: store, claim: claim) } } }
            Section("Related records") { ForEach((try? store.relationships(recordID: record.id)) ?? []) { edge in let id = edge.fromID == record.id ? edge.toID : edge.fromID; if let other = try? store.record(id: id) { NavigationLink("\(edge.predicate) · \(other.name)") { PortableRecordView(store: store, record: other) } } } }
        }.navigationTitle(record.name).task { notes = record.detail }
    }
}
struct PortableClaimView: View {
    let store: KnowledgeStore
    let claim: EngineeringClaim
    var body: some View { Form { Text(claim.statement); LabeledContent("State", value: claim.status.title); Text(claim.conditions); Text(claim.evidenceLevel); Text(claim.locator); Text(claim.notes); if let source = try? store.record(id: claim.sourceID) { NavigationLink("Source: \(source.name)") { PortableRecordView(store: store, record: source) } }; Text("Review evidence here; claim approval remains a Mac authoring action.").font(.caption) }.navigationTitle("Evidence") }
}
