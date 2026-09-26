import SwiftUI
import AppKit

enum AppSection: String, CaseIterable, Identifiable { case overview, ask, search, library, materials, mechanisms, standards, components, sources, claims, relationships, settings
 var id: Self { self }; var title: String { switch self { case .overview:"Overview"; case .ask:"Ask"; case .search:"Search"; case .library:"Library"; case .materials:"Materials"; case .mechanisms:"Damage Mechanisms"; case .standards:"Standards"; case .components:"Components"; case .sources:"Sources"; case .claims:"Claims"; case .relationships:"Relationships"; case .settings:"Settings" } }
 var kind: RecordKind? { switch self { case .materials:.material; case .mechanisms:.mechanism; case .standards:.standard; case .components:.component; case .sources:.source; default:nil } }
}

struct RootView: View { @State private var selection: AppSection? = .overview; @State private var store: KnowledgeStore?; @State private var error: String?; @State private var refresh = UUID(); @State private var targetID: String?
 var body: some View { NavigationSplitView { List(AppSection.allCases, selection: $selection) { Label($0.title, systemImage: $0.symbol).tag(Optional($0)) }.navigationTitle("Materials Intelligence").listStyle(.sidebar) } detail: { if let selection { Page(section: selection, store: store, refresh: $refresh, targetID: $targetID, error: error, openResult: openResult) } }.frame(minWidth: 820, minHeight: 560).task { do { let s = try KnowledgeStore(url: try KnowledgeStore.applicationURL()); try s.seedIfEmpty(); store=s } catch let caught { error=caught.localizedDescription } } }
 private func openResult(_ result: SearchResult) { targetID=result.id; switch result.entityType { case .document: selection = .library; case .claim: selection = .claims; case .record: if let kind=RecordKind(rawValue:result.kind) { selection = AppSection.allCases.first { $0.kind == kind } } } }
}
private extension AppSection { var symbol:String { switch self { case .overview:"house"; case .ask:"questionmark.bubble"; case .search:"magnifyingglass"; case .library:"books.vertical"; case .materials:"cube"; case .mechanisms:"exclamationmark.shield"; case .standards:"text.book.closed"; case .components:"gearshape"; case .sources:"doc.text"; case .claims:"checkmark.seal"; case .relationships:"link"; case .settings:"gear" } } }

private struct Page: View { let section: AppSection; let store: KnowledgeStore?; @Binding var refresh: UUID; @Binding var targetID:String?; let error: String?; let openResult:(SearchResult)->Void
 var body: some View { Group { if let error { ContentUnavailableView("Database unavailable", systemImage:"externaldrive.badge.exclamationmark", description:Text(error)) } else if let store { if let kind=section.kind { RecordPage(kind:kind, store:store, refresh:$refresh, targetID:$targetID) } else if section == .search { SearchPage(store:store, openResult:openResult) } else if section == .library { LibraryPage(store:store, refresh:$refresh, targetID:$targetID) } else if section == .claims { ClaimsPage(store:store, refresh:$refresh, targetID:$targetID) } else if section == .relationships { RelationshipsPage(store:store, refresh:$refresh) } else if section == .ask { ContentUnavailableView("Ask", systemImage:"questionmark.bubble", description:Text("Local answering is planned for Phase 5. Search and review your sources in the meantime.")) } else if section == .settings { SettingsPage() } else { Overview(store:store) } } else { ProgressView("Opening local knowledge") } }.toolbar { Button("Refresh", systemImage:"arrow.clockwise") { refresh=UUID() } } }
}
private struct SettingsPage:View { var body:some View { Form { LabeledContent("Storage",value:"Local Application Support database"); LabeledContent("Search",value:"Offline SQLite FTS5"); Text("Documents remain at their original locations. Library keeps access bookmarks and metadata.").foregroundStyle(.secondary) }.padding(28).navigationTitle("Settings") } }

private struct Overview: View { let store: KnowledgeStore; var body: some View { VStack(alignment:.leading,spacing:18) { Text("Knowledge workspace").font(.largeTitle.bold()); Text("Create structured records, preserve source traceability, and review claims locally.").foregroundStyle(.secondary); ForEach(RecordKind.allCases,id:\.self) { k in LabeledContent(k.rawValue.capitalized,value:"\((try? store.records(kind:k).count) ?? 0)") }; Text("Sample records are illustrative and unverified.").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth:700,alignment:.leading).padding(32) } }

private struct SearchPage: View {
    let store: KnowledgeStore; let openResult:(SearchResult)->Void
    @State private var query = ""
    @State private var selectedTypes = Set(SearchEntityType.allCases)
    @State private var kind: RecordKind? = nil
    @State private var status: VerificationStatus? = nil
    @State private var results:[SearchResult] = []
    @State private var error = ""
    var body: some View { VStack(alignment:.leading, spacing:14) {
        Text("Search").font(.largeTitle.bold())
        HStack { TextField("Search local knowledge", text:$query).textFieldStyle(.roundedBorder).onSubmit(search); Button("Search", action:search).keyboardShortcut(.return, modifiers:[]) }
        filters
        if !error.isEmpty { Text(error).foregroundStyle(.red) }
        if query.isEmpty { ContentUnavailableView("Search your local engineering knowledge", systemImage:"magnifyingglass", description:Text("Results rank full-text and prefix matches across records, claims, and Library metadata.")) } else { List(results) { result in Button { openResult(result) } label: { VStack(alignment:.leading,spacing:4) { HStack { Text(result.title).font(.headline); Spacer(); Text(result.entityType.title).font(.caption).padding(4).background(.quaternary, in:Capsule()) }; HighlightedText(text:result.detail, query:query).foregroundStyle(.secondary); Text(result.kind.replacingOccurrences(of:"_",with:" ")).font(.caption).foregroundStyle(.tertiary) }.padding(.vertical,3).frame(maxWidth:.infinity,alignment:.leading) }.buttonStyle(.plain).accessibilityLabel("Open \(result.entityType.title): \(result.title)") }.overlay { if results.isEmpty && error.isEmpty { ContentUnavailableView("No local matches", systemImage:"magnifyingglass") } } }
    }.padding(28).onChange(of: kind) { _,_ in search() }.onChange(of: status) { _,_ in search() }.onChange(of:selectedTypes) { _,_ in search() } }
    private var filters: some View { HStack { Menu("Types") { ForEach(SearchEntityType.allCases) { type in Toggle(type.title, isOn: typeBinding(type)) } }; Picker("Record type",selection:$kind){ Text("All records").tag(RecordKind?.none); ForEach(RecordKind.allCases,id:\.self) { recordKind in Text(recordKind.rawValue.capitalized).tag(Optional(recordKind)) } }.frame(width:180); Picker("Claim state",selection:$status) { Text("All claim states").tag(VerificationStatus?.none); ForEach(VerificationStatus.allCases,id:\.self) { claimStatus in Text(claimStatus.title).tag(Optional(claimStatus)) } }.frame(width:190); Spacer(); Text("Offline FTS5").font(.caption).foregroundStyle(.secondary) } }
    private func typeBinding(_ type:SearchEntityType) -> Binding<Bool> { Binding(get:{selectedTypes.contains(type)},set:{ enabled in if enabled {selectedTypes.insert(type)} else {selectedTypes.remove(type)} }) }
    private func search() { do { results = try store.search(query, entityTypes:selectedTypes, recordKind:kind, verificationStatus:status); error="" } catch let caught { error=caught.localizedDescription; results=[] } }
}

private struct HighlightedText: View { let text:String; let query:String
    var body: some View { let words=query.split(whereSeparator:\.isWhitespace).map(String.init).filter{!$0.isEmpty}; Text(words.reduce(AttributedString(text)) { output, word in var value=output; var cursor=value.startIndex; while let range=value[cursor...].range(of:word,options:.caseInsensitive) { value[range].backgroundColor = .yellow.opacity(0.35); cursor=range.upperBound }; return value }) }
}

private struct LibraryPage: View {
    let store: KnowledgeStore
    @Binding var refresh: UUID
    @Binding var targetID: String?
    @State private var documents: [LibraryDocument] = []
    @State private var selected: LibraryDocument?
    @State private var showingImport = false
    @State private var message = ""

    var body: some View {
        HStack(spacing: 0) {
            List(documents, selection: $selected) { document in
                VStack(alignment: .leading) {
                    Text(document.title)
                    Text([document.organization, document.revisionYear].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary)
                }.tag(document)
            }.frame(minWidth: 240, idealWidth: 320)
            Divider()
            if let selected {
                DocumentDetail(document: selected, store: store, changed: load, message: $message)
            } else {
                ContentUnavailableView("Select a document", systemImage: "books.vertical")
            }
        }
        .navigationTitle("Library")
        .toolbar { Button("Register document", systemImage: "plus") { showingImport = true } }
        .sheet(isPresented: $showingImport) { DocumentEditor(store: store, done: load) }
        .alert("Document", isPresented: Binding(get: { !message.isEmpty }, set: { if !$0 { message = "" } })) {
            Button("OK") {}
        } message: { Text(message) }
        .onAppear(perform: load)
        .onChange(of: refresh) { _, _ in load() }
        .onChange(of: targetID) { _, _ in load() }
    }

    private func load() {
        documents = (try? store.documents()) ?? []
        if let targetID, let target = documents.first(where: { $0.id == targetID }) {
            selected = target
        } else if let selected {
            self.selected = documents.first { $0.id == selected.id }
        }
    }
}

private struct DocumentDetail: View {
    let document: LibraryDocument
    let store: KnowledgeStore
    let changed: () -> Void
    @Binding var message: String
    @State private var confirmRemoval = false
    @State private var editing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(document.title).font(.largeTitle.bold())
                    Spacer()
                    Button("Open", action: open)
                    Button("Locate file…", action: locate)
                    Button("Edit metadata") { editing = true }
                }
                if !document.organization.isEmpty { LabeledContent("Organization", value: document.organization) }
                if !document.revisionYear.isEmpty { LabeledContent("Revision / year", value: document.revisionYear) }
                if !document.sourceType.isEmpty { LabeledContent("Source type", value: document.sourceType) }
                Text(document.notes.isEmpty ? "No notes recorded." : document.notes)
                Divider()
                Text("Associated knowledge").font(.title2.bold())
                ForEach((try? store.recordIDs(documentID: document.id)) ?? [], id: \.self) { id in
                    Text((try? store.record(id: id))?.name ?? "Unavailable record")
                }
                Button("Remove from Library", role: .destructive) { confirmRemoval = true }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(28)
        }
        .confirmationDialog("Remove this document's Library metadata and associations? The original file is retained.", isPresented: $confirmRemoval) {
            Button("Remove from Library", role: .destructive) {
                do { try store.deleteDocument(id: document.id); changed() }
                catch { message = error.localizedDescription }
            }
        }
        .sheet(isPresented: $editing) { DocumentEditor(document: document, store: store, done: changed) }
    }

    private func open() {
        guard let data = Data(base64Encoded: document.bookmark), !data.isEmpty else {
            message = "No usable file reference is stored. Use Locate file to restore access. Metadata and associations remain available."
            return
        }
        var stale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale)
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard FileManager.default.isReadableFile(atPath: url.path) else {
                message = "This file is missing or inaccessible. Use Locate file to reconnect it. Metadata and associations are retained."
                return
            }
            guard NSWorkspace.shared.open(url) else {
                message = "macOS could not open this file. Use Locate file if it has moved. Metadata and associations are retained."
                return
            }
            if stale {
                do {
                    var updated = document
                    updated.bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil).base64EncodedString()
                    try store.save(updated, recordIDs: store.recordIDs(documentID: document.id))
                    changed()
                } catch {
                    message = "The document opened, but its file permission could not be refreshed. Use Locate file to reconnect it."
                }
            }
        } catch {
            message = "The file reference could not be resolved or refreshed. Use Locate file to reconnect it. Metadata and associations are retained."
        }
    }

    private func locate() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            guard FileManager.default.isReadableFile(atPath: url.path) else {
                throw KnowledgeStoreError(message: "Selected file is not readable")
            }
            var updated = document
            updated.bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil).base64EncodedString()
            updated.fileName = url.lastPathComponent
            try store.save(updated, recordIDs: store.recordIDs(documentID: document.id))
            changed()
        } catch { message = error.localizedDescription }
    }
}

private struct DocumentEditor: View {
    @Environment(\.dismiss) private var dismiss
    let document: LibraryDocument?
    let store: KnowledgeStore
    let done: () -> Void
    @State private var fileURL: URL?
    @State private var title: String
    @State private var organization: String
    @State private var revisionYear: String
    @State private var sourceType: String
    @State private var notes: String
    @State private var selectedIDs = Set<String>()
    @State private var error = ""
    @State private var associationLoadFailed = false

    init(document: LibraryDocument? = nil, store: KnowledgeStore, done: @escaping () -> Void) {
        self.document = document; self.store = store; self.done = done
        _title = State(initialValue: document?.title ?? "")
        _organization = State(initialValue: document?.organization ?? "")
        _revisionYear = State(initialValue: document?.revisionYear ?? "")
        _sourceType = State(initialValue: document?.sourceType ?? "")
        _notes = State(initialValue: document?.notes ?? "")
        if let document {
            let ids = try? store.recordIDs(documentID: document.id)
            _selectedIDs = State(initialValue: Set(ids ?? []))
            _associationLoadFailed = State(initialValue: ids == nil)
            if ids == nil { _error = State(initialValue: "Associations could not be loaded. Close and reopen this editor before saving.") }
        }
    }

    var body: some View {
        Form {
            HStack {
                Text(fileURL?.lastPathComponent ?? document?.fileName ?? "No document selected").lineLimit(1)
                Spacer()
                Button("Choose…", action: choose)
            }
            TextField("Title", text: $title)
            TextField("Organization / author", text: $organization)
            TextField("Revision / year", text: $revisionYear)
            TextField("Source type", text: $sourceType)
            TextField("Notes", text: $notes, axis: .vertical)
            Section("Associate with knowledge") {
                ForEach((try? store.records()) ?? []) { record in
                    Toggle(record.name, isOn: Binding(
                        get: { selectedIDs.contains(record.id) },
                        set: { if $0 { selectedIDs.insert(record.id) } else { selectedIDs.remove(record.id) } }
                    ))
                }
            }
            Text(error).foregroundStyle(.red)
        }
        .padding().frame(width: 560, height: 620)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(document == nil ? "Register" : "Save", action: save).disabled(associationLoadFailed || (fileURL == nil && document == nil) || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    private func choose() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            fileURL = url
            if title.isEmpty { title = url.deletingPathExtension().lastPathComponent }
        }
    }
    private func save() {
        let scoped = fileURL?.startAccessingSecurityScopedResource() ?? false
        defer { if scoped { fileURL?.stopAccessingSecurityScopedResource() } }
        do {
            if let fileURL, !FileManager.default.isReadableFile(atPath: fileURL.path) { throw KnowledgeStoreError(message: "Selected file is not readable") }
            let bookmark = try fileURL?.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil).base64EncodedString() ?? document?.bookmark ?? ""
            try store.save(LibraryDocument(id: document?.id ?? UUID().uuidString, title: title.trimmingCharacters(in: .whitespacesAndNewlines), organization: organization, revisionYear: revisionYear, sourceType: sourceType, notes: notes, fileName: fileURL?.lastPathComponent ?? document?.fileName ?? "", bookmark: bookmark), recordIDs: Array(selectedIDs))
            done(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

private struct RecordPage: View {
    let kind: RecordKind
    let store: KnowledgeStore
    @Binding var refresh: UUID
    @Binding var targetID: String?
    @State private var selected: KnowledgeRecord?
    @State private var editor: KnowledgeRecord?
    @State private var adding = false
    @State private var confirmDeletion = false
    @State private var alert = ""
    private var records: [KnowledgeRecord] { (try? store.records(kind: kind)) ?? [] }

    var body: some View {
        HStack(spacing: 0) {
            List(records, selection: $selected) { record in
                VStack(alignment: .leading) {
                    Text(record.name)
                    Text(record.secondary).font(.caption).foregroundStyle(.secondary)
                }.tag(record)
            }.frame(minWidth: 220, idealWidth: 300)
            Divider()
            if let selected {
                RecordDetail(record: selected, store: store, edit: { editor = selected }, delete: { confirmDeletion = true })
            } else { ContentUnavailableView("Select a record", systemImage: "doc.text") }
        }
        .navigationTitle(kind.rawValue.capitalized)
        .toolbar { Button("Add", systemImage: "plus") { adding = true } }
        .sheet(isPresented: $adding) { RecordEditor(kind: kind, store: store, done: { refresh = UUID() }) }
        .sheet(item: $editor) { RecordEditor(record: $0, store: store, done: { reload() }) }
        .confirmationDialog("Delete this record?", isPresented: $confirmDeletion) {
            Button("Delete record", role: .destructive, action: delete)
        } message: { Text("Records referenced by claims, relationships, or documents cannot be deleted.") }
        .alert("Cannot delete record", isPresented: Binding(get: { !alert.isEmpty }, set: { if !$0 { alert = "" } })) {
            Button("OK") {}
        } message: { Text(alert) }
        .onAppear(perform: reload)
        .onChange(of: targetID) { _, _ in reload() }
        .onChange(of: refresh) { _, _ in reload() }
    }
    private func reload() {
        if let targetID, let found = records.first(where: { $0.id == targetID }) { selected = found }
        else if let selected { self.selected = records.first { $0.id == selected.id } }
    }
    private func delete() {
        guard let selected else { return }
        do { try store.deleteRecord(id: selected.id); self.selected = nil; refresh = UUID() }
        catch { alert = "This record is referenced by a claim, relationship, or Library document. Remove those links first. \(error.localizedDescription)" }
    }
}

private struct RecordDetail: View {
    let record: KnowledgeRecord
    let store: KnowledgeStore
    let edit: () -> Void
    let delete: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(record.name).font(.largeTitle.bold())
                    Spacer()
                    Button("Edit", action: edit)
                    Button("Delete", role: .destructive, action: delete)
                }
                Text(record.secondary).font(.headline)
                Text(record.detail.isEmpty ? "No detail recorded." : record.detail)
                Divider()
                Text("Claims").font(.title2.bold())
                ForEach((try? store.claims(subjectID: record.id)) ?? []) { claim in
                    Text("\(claim.status.title): \(claim.statement)")
                }
                Text("Relationships").font(.title2.bold())
                ForEach((try? store.relationships(recordID: record.id)) ?? []) { relationship in
                    let id = relationship.fromID == record.id ? relationship.toID : relationship.fromID
                    Text("\(relationship.predicate.replacingOccurrences(of: "_", with: " ")) → \((try? store.record(id: id))?.name ?? "Unknown")")
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(28)
        }
    }
}

private struct RecordEditor: View {
    @Environment(\.dismiss) private var dismiss
    let record: KnowledgeRecord?
    let kind: RecordKind
    let store: KnowledgeStore
    let done: () -> Void
    @State private var name: String
    @State private var detail: String
    @State private var secondary: String
    @State private var error = ""
    init(record: KnowledgeRecord? = nil, kind: RecordKind? = nil, store: KnowledgeStore, done: @escaping () -> Void) {
        self.record = record; self.kind = record?.kind ?? kind!; self.store = store; self.done = done
        _name = State(initialValue: record?.name ?? "")
        _detail = State(initialValue: record?.detail ?? "")
        _secondary = State(initialValue: record?.secondary ?? "")
    }
    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Designation / revision", text: $secondary)
            TextField("Detail", text: $detail, axis: .vertical)
            Text(error).foregroundStyle(.red)
        }.padding().frame(width: 460)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }
    }
    private func save() {
        do {
            try store.save(KnowledgeRecord(id: record?.id ?? UUID().uuidString, kind: kind, name: name.trimmingCharacters(in: .whitespacesAndNewlines), detail: detail, secondary: secondary))
            done(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

private struct ClaimsPage: View {
    let store: KnowledgeStore
    @Binding var refresh: UUID
    @Binding var targetID: String?
    @State private var selected: EngineeringClaim?
    @State private var editing: EngineeringClaim?
    @State private var adding = false
    @State private var confirmDeletion = false
    @State private var message = ""
    private var claims: [EngineeringClaim] { (try? store.claims()) ?? [] }
    var body: some View {
        HStack(spacing: 0) {
            List(claims, selection: $selected) { claim in
                VStack(alignment: .leading) {
                    Text(claim.statement).lineLimit(2)
                    Text("\(claim.status.title) · \((try? store.record(id: claim.sourceID))?.name ?? "Unknown source")")
                        .font(.caption).foregroundStyle(.secondary)
                }.tag(claim)
            }.frame(minWidth: 260, idealWidth: 360)
            Divider()
            if let selected {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Engineering Claim").font(.largeTitle.bold())
                            Spacer()
                            Button("Edit / Review") { editing = selected }
                            Button("Delete", role: .destructive) { confirmDeletion = true }
                        }
                        Text(selected.statement)
                        LabeledContent("State", value: selected.status.title)
                        LabeledContent("Subject", value: (try? store.record(id: selected.subjectID))?.name ?? "Unknown")
                        LabeledContent("Source", value: (try? store.record(id: selected.sourceID))?.name ?? "Unknown")
                        LabeledContent("Page / section", value: selected.locator)
                        Text(selected.notes)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(28)
                }
            } else { ContentUnavailableView("Select a claim", systemImage: "checkmark.seal") }
        }
        .navigationTitle("Engineering Claims")
        .toolbar { Button("Add", systemImage: "plus") { adding = true } }
        .sheet(isPresented: $adding) { ClaimEditor(store: store, done: { refresh = UUID(); reload() }) }
        .sheet(item: $editing) { ClaimEditor(claim: $0, store: store, done: { refresh = UUID(); reload() }) }
        .confirmationDialog("Delete this claim?", isPresented: $confirmDeletion) {
            Button("Delete claim", role: .destructive, action: delete)
        } message: { Text("A claim supporting a relationship cannot be deleted. Archive it to retain provenance.") }
        .alert("Claim", isPresented: Binding(get: { !message.isEmpty }, set: { if !$0 { message = "" } })) { Button("OK") {} } message: { Text(message) }
        .onAppear(perform: reload)
        .onChange(of: refresh) { _, _ in reload() }
        .onChange(of: targetID) { _, _ in reload() }
    }
    private func reload() {
        if let targetID, let found = claims.first(where: { $0.id == targetID }) { selected = found }
        else if let selected { self.selected = claims.first { $0.id == selected.id } }
    }
    private func delete() {
        guard let selected else { return }
        do { try store.deleteClaim(id: selected.id); self.selected = nil; refresh = UUID() }
        catch { message = "This claim supports a relationship. Remove that relationship first, or archive the claim. \(error.localizedDescription)" }
    }
}

private struct ClaimEditor: View {
    @Environment(\.dismiss) private var dismiss
    let claim: EngineeringClaim?
    let store: KnowledgeStore
    let done: () -> Void
    @State private var subject: String
    @State private var statement: String
    @State private var predicate: String
    @State private var source: String
    @State private var locator: String
    @State private var conditions: String
    @State private var evidenceLevel: String
    @State private var notes: String
    @State private var status: VerificationStatus
    @State private var error = ""
    init(claim: EngineeringClaim? = nil, store: KnowledgeStore, done: @escaping () -> Void) {
        self.claim = claim; self.store = store; self.done = done
        _subject = State(initialValue: claim?.subjectID ?? "")
        _statement = State(initialValue: claim?.statement ?? "")
        _predicate = State(initialValue: claim?.predicate ?? "")
        _source = State(initialValue: claim?.sourceID ?? "")
        _locator = State(initialValue: claim?.locator ?? "")
        _conditions = State(initialValue: claim?.conditions ?? "")
        _evidenceLevel = State(initialValue: claim?.evidenceLevel ?? "")
        _notes = State(initialValue: claim?.notes ?? "")
        _status = State(initialValue: claim?.status ?? .draft)
    }
    var body: some View {
        Form {
            Picker("Subject", selection: $subject) {
                Text("Select a subject").tag("")
                ForEach((try? store.records()) ?? []) { Text($0.name).tag($0.id) }
            }
            Picker("Source", selection: $source) {
                Text("Select a source").tag("")
                ForEach((try? store.records(kind: .source)) ?? []) { Text($0.name).tag($0.id) }
            }
            TextField("Predicate", text: $predicate)
            TextField("Statement", text: $statement, axis: .vertical)
            TextField("Conditions", text: $conditions, axis: .vertical)
            TextField("Page / section", text: $locator)
            TextField("Evidence level", text: $evidenceLevel)
            TextField("Notes", text: $notes, axis: .vertical)
            Picker("Review state", selection: $status) {
                ForEach(VerificationStatus.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            Text(error).foregroundStyle(.red)
        }.padding().frame(width: 560, height: 620)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(subject.isEmpty || source.isEmpty || predicate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || statement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    private func save() {
        do {
            try store.save(EngineeringClaim(id: claim?.id ?? UUID().uuidString, subjectID: subject, predicate: predicate.trimmingCharacters(in: .whitespacesAndNewlines), statement: statement.trimmingCharacters(in: .whitespacesAndNewlines), conditions: conditions, sourceID: source, locator: locator, status: status, evidenceLevel: evidenceLevel, notes: notes))
            done(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

private struct RelationshipsPage: View {
    let store: KnowledgeStore
    @Binding var refresh: UUID
    @State private var adding = false
    @State private var selected: KnowledgeRelationship?
    @State private var confirmRemoval = false
    @State private var message = ""
    private var relationships: [KnowledgeRelationship] { (try? store.relationships()) ?? [] }
    var body: some View {
        List(relationships, selection: $selected) { relationship in
            let from = (try? store.record(id: relationship.fromID))?.name ?? "?"
            let to = (try? store.record(id: relationship.toID))?.name ?? "?"
            Text("\(from) — \(relationship.predicate.replacingOccurrences(of: "_", with: " ")) — \(to)")
                .tag(relationship)
        }
        .navigationTitle("Relationships")
        .toolbar {
            Button("Add", systemImage: "plus") { adding = true }
            if selected != nil { Button("Remove", systemImage: "minus", role: .destructive) { confirmRemoval = true } }
        }
        .sheet(isPresented: $adding) { RelationshipEditor(store: store, done: { refresh = UUID() }) }
        .confirmationDialog("Remove this relationship? Its records and supporting claim will remain.", isPresented: $confirmRemoval) {
            Button("Remove relationship", role: .destructive) {
                guard let selected else { return }
                do { try store.deleteRelationship(id: selected.id); self.selected = nil; refresh = UUID() }
                catch { message = error.localizedDescription }
            }
        }
        .alert("Relationship", isPresented: Binding(get: { !message.isEmpty }, set: { if !$0 { message = "" } })) { Button("OK") {} } message: { Text(message) }
    }
}

private struct RelationshipEditor: View {
    @Environment(\.dismiss) private var dismiss
    let store: KnowledgeStore
    let done: () -> Void
    @State private var from = ""
    @State private var to = ""
    @State private var predicate = "related_to"
    @State private var supportingClaimID = ""
    @State private var error = ""
    var body: some View {
        Form {
            Picker("From", selection: $from) {
                Text("Select a record").tag("")
                ForEach((try? store.records()) ?? []) { Text($0.name).tag($0.id) }
            }
            TextField("Relationship", text: $predicate)
            Picker("To", selection: $to) {
                Text("Select a record").tag("")
                ForEach((try? store.records()) ?? []) { Text($0.name).tag($0.id) }
            }
            Picker("Supporting claim", selection: $supportingClaimID) {
                Text("None").tag("")
                ForEach((try? store.claims()) ?? []) { Text($0.statement).tag($0.id) }
            }
            Text(error).foregroundStyle(.red)
        }.padding().frame(width: 480)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(from.isEmpty || to.isEmpty || from == to || predicate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    private func save() {
        do {
            try store.save(KnowledgeRelationship(fromID: from, predicate: predicate.trimmingCharacters(in: .whitespacesAndNewlines), toID: to, supportingClaimID: supportingClaimID.isEmpty ? nil : supportingClaimID))
            done(); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
