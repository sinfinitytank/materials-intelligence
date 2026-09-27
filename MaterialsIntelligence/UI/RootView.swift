import SwiftUI
import AppKit

enum AppSection: String, CaseIterable, Identifiable { case overview, ask, search, library, research, materials, mechanisms, standards, components, sources, claims, relationships, settings
 var id: Self { self }; var title: String { switch self { case .overview:"Overview"; case .ask:"Ask"; case .search:"Search"; case .library:"Library"; case .research:"Research"; case .materials:"Materials"; case .mechanisms:"Damage Mechanisms"; case .standards:"Standards"; case .components:"Components"; case .sources:"Sources"; case .claims:"Claims"; case .relationships:"Relationships"; case .settings:"Settings" } }
 var kind: RecordKind? { switch self { case .materials:.material; case .mechanisms:.mechanism; case .standards:.standard; case .components:.component; case .sources:.source; default:nil } }
}

struct RootView: View { @State private var selection: AppSection? = .overview; @State private var store: KnowledgeStore?; @State private var error: String?; @State private var refresh = UUID(); @State private var targetID: String?
 var body: some View { NavigationSplitView { Sidebar(selection: $selection) } detail: { if let selection { Page(section: selection, store: store, refresh: $refresh, targetID: $targetID, error: error, openResult: openResult, navigate: navigate) } }.navigationSplitViewStyle(.balanced).frame(minWidth: 1040, minHeight: 680).task { do { let s = try KnowledgeStore(url: try KnowledgeStore.applicationURL()); try s.seedIfEmpty(); store=s } catch let caught { error=caught.localizedDescription } } }
 private func openResult(_ result: SearchResult) { targetID=result.id; switch result.entityType { case .document: selection = .library; case .claim: selection = .claims; case .record: if let kind=RecordKind(rawValue:result.kind) { selection = AppSection.allCases.first { $0.kind == kind } } } }
 private func navigate(_ section: AppSection) { targetID = nil; selection = section }
}
private struct Sidebar: View { @Binding var selection: AppSection?
 var body: some View { VStack(alignment: .leading, spacing: 0) {
  HStack(spacing: 10) { Image(systemName: "cube.transparent").font(.title2).foregroundStyle(.blue); Text("Materials Intelligence").font(.headline) }.padding(.horizontal, 18).padding(.top, 22).padding(.bottom, 18)
  ScrollView {
   VStack(alignment: .leading, spacing: 3) {
    nav(.overview); nav(.ask); nav(.search); nav(.research)
    sidebarSection("Knowledge", items: [.materials, .mechanisms, .components, .standards, .sources])
    sidebarSection("Evidence", items: [.library, .claims, .relationships])
    nav(.settings).padding(.top, 8)
   }.padding(.horizontal, 10)
  }
  Spacer()
  HStack(spacing: 8) { Image(systemName: "circle.fill").font(.caption).foregroundStyle(.green); VStack(alignment: .leading, spacing: 2) { Text("Local database").font(.caption.weight(.semibold)); Text("Offline · Indexed and ready").font(.caption2).foregroundStyle(.secondary) } }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12)).padding(12)
 }.background(.regularMaterial) }
 private func nav(_ section: AppSection) -> some View { Button { selection = section } label: { Label(section.title, systemImage: section.symbol).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.vertical, 8).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selection == section)) }
 private func sidebarSection(_ title: String, items: [AppSection]) -> some View { VStack(alignment: .leading, spacing: 3) { Text(title.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).padding(.leading, 12).padding(.top, 14).padding(.bottom, 2); ForEach(items) { nav($0) } } }
}
private struct SidebarButtonStyle: ButtonStyle { let selected: Bool; func makeBody(configuration: Configuration) -> some View { configuration.label.font(.system(size: 13, weight: selected ? .semibold : .regular)).foregroundStyle(selected ? Color.accentColor : .primary).background(selected ? Color.accentColor.opacity(0.14) : (configuration.isPressed ? Color.primary.opacity(0.08) : .clear), in: RoundedRectangle(cornerRadius: 7, style: .continuous)).opacity(configuration.isPressed ? 0.78 : 1) } }
private extension AppSection { var symbol:String { switch self { case .overview:"house"; case .ask:"questionmark.bubble"; case .search:"magnifyingglass"; case .library:"books.vertical"; case .research:"doc.badge.plus"; case .materials:"cube"; case .mechanisms:"exclamationmark.shield"; case .standards:"text.book.closed"; case .components:"gearshape"; case .sources:"doc.text"; case .claims:"checkmark.seal"; case .relationships:"link"; case .settings:"gear" } } }

private struct Page: View { let section: AppSection; let store: KnowledgeStore?; @Binding var refresh: UUID; @Binding var targetID:String?; let error: String?; let openResult:(SearchResult)->Void; let navigate:(AppSection)->Void
 var body: some View { Group { if let error { ContentUnavailableView("Database unavailable", systemImage:"externaldrive.badge.exclamationmark", description:Text(error)) } else if let store { if section == .overview { Overview(store: store, navigate: navigate) } else if section == .materials { MaterialsPage(store: store, refresh: $refresh, targetID: $targetID) } else if let kind=section.kind { RecordPage(kind:kind, store:store, refresh:$refresh, targetID:$targetID) } else if section == .search { SearchPage(store:store, openResult:openResult) } else if section == .library { LibraryPage(store:store, refresh:$refresh, targetID:$targetID) } else if section == .research { ResearchPage(store: store) } else if section == .claims { ClaimsPage(store:store, refresh:$refresh, targetID:$targetID) } else if section == .relationships { RelationshipsPage(store:store, refresh:$refresh) } else if section == .ask { AskPage(store: store, openResult: openResult) } else if section == .settings { SettingsPage() } else { Overview(store:store, navigate:navigate) } } else { ProgressView("Opening local knowledge") } }.toolbar { Button("Refresh", systemImage:"arrow.clockwise") { refresh=UUID() } } }
}
private struct SettingsPage:View { var body:some View { VStack(alignment: .leading, spacing: 18) { PageHeader(title: "Settings", subtitle: "Local storage and application behavior"); Panel { VStack(alignment: .leading, spacing: 12) { LabeledContent("Storage",value:"Local Application Support database"); LabeledContent("Search",value:"Offline SQLite FTS5"); Divider(); Text("Documents remain at their original locations. Library keeps access bookmarks and metadata.").foregroundStyle(.secondary) } } }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(MITheme.canvas) } }

enum MITheme { static let canvas = Color(nsColor: .underPageBackgroundColor); static let blue = Color.accentColor }
struct Panel<Content: View>: View { @ViewBuilder let content: () -> Content; var body: some View { content().padding(18).background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary)) } }
struct PageHeader: View { let title: String; let subtitle: String; var body: some View { VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 30, weight: .bold, design: .rounded)); Text(subtitle).foregroundStyle(.secondary) } } }
private struct AskPage: View {
    let store: KnowledgeStore
    let openResult: (SearchResult) -> Void
    @State private var question = ""
    @State private var answer: LocalAnswer?
    @State private var error = ""
    @State private var loading = false
    private let provider = AppleLocalProvider()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(title: "Ask", subtitle: "Evidence-grounded answers from your local materials knowledge base.")
                HStack { Image(systemName: "desktopcomputer"); Text("LOCAL · database search and on-device model only").font(.caption.weight(.semibold)) }.foregroundStyle(.secondary)
                if let unavailable = provider.availabilityMessage { Panel { Label(unavailable, systemImage: "cpu").foregroundStyle(.orange) } }
                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Ask an engineering question…", text: $question, axis: .vertical).lineLimit(2...4)
                        HStack { Spacer(); Button("Ask locally") { submit() }.buttonStyle(.borderedProminent).disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loading) }
                    }
                }
                if loading { ProgressView("Searching evidence and asking the local model…") }
                if !error.isEmpty { Panel { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) } }
                if let answer {
                    Panel {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack { SectionTitle("Answer", icon: "text.bubble"); Spacer(); if answer.generatedLocally { StatusBadge(title: "LOCAL — no internet used", color: .green) } }
                            if let message = answer.message { Text(message).foregroundStyle(.secondary) }
                            ForEach(answer.points) { point in
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(point.text)
                                    Text("Generated explanation · check the claims below").font(.caption).foregroundStyle(.secondary)
                                    ForEach(point.evidence) { evidence in
                                        Button { open(.claim, evidence.claim.id, title: evidence.claim.statement) } label: {
                                            Label("Claim · \(evidence.claim.status.title) · \(evidence.subject.name)", systemImage: "checkmark.seal")
                                        }.buttonStyle(.link)
                                    }
                                }
                                if point.id != answer.points.last?.id { Divider() }
                            }
                        }
                    }
                    if !answer.found.isEmpty {
                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionTitle("Supporting claims and sources", icon: "books.vertical")
                                ForEach(answer.found) { item in
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.claim.statement)
                                        Text("\(item.claim.status.title) · \(item.subject.name) · \(item.claim.locator.isEmpty ? "No locator" : item.claim.locator)").font(.caption).foregroundStyle(.secondary)
                                        HStack {
                                            Button("Open claim") { open(.claim, item.claim.id, title: item.claim.statement) }
                                            Button("Open source: \(item.source.name)") { open(.record, item.source.id, title: item.source.name, kind: .source) }
                                        }.buttonStyle(.link)
                                    }
                                    Divider()
                                }
                            }
                        }
                    }
                }
                Text("Library document contents are not indexed. Illustrative or unreviewed claims do not authorize a generated engineering conclusion.").font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: 860, alignment: .leading).padding(32).frame(maxWidth: .infinity, alignment: .leading)
        }.background(MITheme.canvas)
    }

    private func open(_ type: SearchEntityType, _ id: String, title: String, kind: RecordKind? = nil) {
        openResult(SearchResult(id: id, entityType: type, title: title, detail: "", kind: kind?.rawValue ?? "", score: 0))
    }
    private func submit() {
        let submitted = question
        answer = nil; error = ""; loading = true
        Task { @MainActor in
            do { answer = try await LocalRAG(store: store, provider: provider).ask(submitted) }
            catch { self.error = error.localizedDescription }
            loading = false
        }
    }
}

private struct Overview: View { let store: KnowledgeStore; let navigate:(AppSection)->Void
 var body: some View { ScrollView { VStack(alignment: .leading, spacing: 18) { HStack(alignment: .bottom) { PageHeader(title: "Materials Intelligence", subtitle: "Local engineering knowledge base"); Spacer(); Text("Materials. Context. Confidence.\nFor a more reliable tomorrow.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.trailing) }
  LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) { metric("Knowledge coverage", value: totalRecords, note: "records indexed", icon: "books.vertical"); metric("Reviewed claims", value: claims, note: "source-traceable", icon: "doc.text"); metric("Library activity", value: documents, note: "documents registered", icon: "cylinder"); suggested }
  HStack(alignment: .top, spacing: 12) { coverage.frame(maxWidth: .infinity); activity.frame(maxWidth: .infinity) }
  HStack(alignment: .top, spacing: 12) { Panel { VStack(alignment: .leading, spacing: 12) { SectionTitle("Quick actions", icon: "bolt"); HStack(spacing: 10) { action("Ask a question", "magnifyingglass", .ask); action("Browse materials", "square.stack.3d.up", .materials); action("View damage mechanisms", "exclamationmark.triangle", .mechanisms); action("Open library", "books.vertical", .library) } } }.frame(maxWidth: .infinity); Panel { VStack(alignment: .leading, spacing: 10) { SectionTitle("System status", icon: "cylinder"); statusRow("Database", "Local (SQLite)"); statusRow("Index status", "Up to date"); statusRow("Storage", "Local by design") } }.frame(width: 300) }
 }.padding(28) }.background(MITheme.canvas) }
 private var totalRecords: String { "\((try? store.records().count) ?? 0)" }; private var claims: String { "\((try? store.claims().count) ?? 0)" }; private var documents: String { "\((try? store.documents().count) ?? 0)" }
 private func color(for kind: RecordKind) -> Color { switch kind { case .material: .blue; case .mechanism: .orange; case .standard: .purple; case .component: .green; case .source: .gray } }
 private func section(for kind: RecordKind) -> AppSection { switch kind { case .material: .materials; case .mechanism: .mechanisms; case .standard: .standards; case .component: .components; case .source: .sources } }
 private var coverage: some View { Panel { VStack(alignment: .leading, spacing: 12) { SectionTitle("Materials family coverage", icon: "chart.bar.xaxis"); ForEach(RecordKind.allCases, id: \.self) { k in Button { navigate(section(for: k)) } label: { HStack { Circle().fill(color(for: k)).frame(width: 8, height: 8); Text(k.rawValue.capitalized); Spacer(); Text("\((try? store.records(kind: k).count) ?? 0)").foregroundStyle(.secondary); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary) }.contentShape(Rectangle()) }.buttonStyle(.plain) } } } }
 private var activity: some View { Panel { VStack(alignment: .leading, spacing: 12) { SectionTitle("Traceability & recent activity", icon: "clock"); Text("Reviewed engineering claims and local source records remain linked to their originating evidence.").foregroundStyle(.secondary); statusRow("Engineering claims", claims); statusRow("Registered documents", documents); statusRow("Knowledge records", totalRecords) } } }
 private var suggested: some View { Panel { VStack(alignment: .leading, spacing: 10) { SectionTitle("Suggested exploration", icon: "safari"); ForEach([("Browse materials", AppSection.materials), ("Review claims", .claims), ("Open library", .library)], id: \.0) { item in Button { navigate(item.1) } label: { HStack { Text(item.0); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary) } }.buttonStyle(.plain) } } } }
 private func action(_ title: String, _ icon: String, _ section: AppSection) -> some View { Button { navigate(section) } label: { Label(title, systemImage: icon).frame(maxWidth: .infinity, alignment: .leading).padding(10).background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8)) }.buttonStyle(.plain) }
 private func statusRow(_ title: String, _ value: String) -> some View { HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value) } }
 private func metric(_ title: String, value: String, note: String, icon: String) -> some View { Panel { VStack(alignment: .leading, spacing: 6) { Image(systemName: icon).font(.title2).foregroundStyle(.blue); Text(title).font(.headline); Text(value).font(.system(size: 26, weight: .bold, design: .rounded)); Text(note).font(.caption).foregroundStyle(.secondary) } } }
}
private struct SectionTitle: View { let title: String; let icon: String; init(_ title: String, icon: String) { self.title = title; self.icon = icon }; var body: some View { Label(title, systemImage: icon).font(.headline) } }

private struct SearchPage: View {
    let store: KnowledgeStore; let openResult:(SearchResult)->Void
    @State private var query = ""
    @State private var selectedTypes = Set(SearchEntityType.allCases)
    @State private var kind: RecordKind? = nil
    @State private var status: VerificationStatus? = nil
    @State private var results:[SearchResult] = []
    @State private var error = ""
    var body: some View { VStack(alignment:.leading, spacing:14) {
        PageHeader(title: "Search", subtitle: "Find materials, claims, standards, and local documents.")
        HStack { Image(systemName: "magnifyingglass").foregroundStyle(.secondary); TextField("Search local knowledge…", text:$query).textFieldStyle(.plain).onSubmit(search); if !query.isEmpty { Button("Clear", systemImage: "xmark.circle.fill") { query = ""; results = [] }.buttonStyle(.plain).foregroundStyle(.secondary) }; Button("Search", action:search).buttonStyle(.borderedProminent).keyboardShortcut(.return, modifiers:[]) }.padding(10).background(.background, in: RoundedRectangle(cornerRadius: 9)).overlay(RoundedRectangle(cornerRadius: 9).stroke(.quaternary))
        filters
        if !error.isEmpty { Text(error).foregroundStyle(.red) }
        if query.isEmpty { ContentUnavailableView("Search your local engineering knowledge", systemImage:"magnifyingglass", description:Text("Results rank full-text and prefix matches across records, claims, and Library metadata.")) } else { List(results) { result in Button { openResult(result) } label: { VStack(alignment:.leading,spacing:4) { HStack { Text(result.title).font(.headline); Spacer(); Text(result.entityType.title).font(.caption).padding(4).background(.quaternary, in:Capsule()) }; HighlightedText(text:result.detail, query:query).foregroundStyle(.secondary); Text(result.kind.replacingOccurrences(of:"_",with:" ")).font(.caption).foregroundStyle(.tertiary) }.padding(.vertical,3).frame(maxWidth:.infinity,alignment:.leading) }.buttonStyle(.plain).accessibilityLabel("Open \(result.entityType.title): \(result.title)") }.overlay { if results.isEmpty && error.isEmpty { ContentUnavailableView("No local matches", systemImage:"magnifyingglass") } } }
    }.padding(28).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(MITheme.canvas).onChange(of: kind) { _,_ in search() }.onChange(of: status) { _,_ in search() }.onChange(of:selectedTypes) { _,_ in search() } }
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
            VStack(alignment: .leading, spacing: 10) { Text("Library").font(.title2.bold()); Text("Local documents and source files").font(.caption).foregroundStyle(.secondary); ScrollView { LazyVStack(alignment: .leading, spacing: 3) { ForEach(documents) { document in Button { selected = document } label: { VStack(alignment: .leading, spacing: 3) { Label(document.title, systemImage: "doc.text").lineLimit(1); Text([document.organization, document.revisionYear].filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(8).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selected?.id == document.id)) } } }.frame(maxWidth: .infinity, maxHeight: .infinity) }.padding(.top, 18).frame(minWidth: 250, idealWidth: 320)
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
        .onChange(of: targetID) { _, _ in load() }.background(MITheme.canvas)
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
                    VStack(alignment: .leading, spacing: 4) { Text(document.title).font(.system(size: 28, weight: .bold, design: .rounded)); Text("Library document").font(.subheadline).foregroundStyle(.secondary) }
                    Spacer()
                    Button("Open document", action: open).buttonStyle(.borderedProminent)
                    Button("Locate file…", action: locate)
                    Button("Edit metadata") { editing = true }
                }
                Panel { VStack(alignment: .leading, spacing: 10) { SectionTitle("Document details", icon: "info.circle"); if !document.organization.isEmpty { LabeledContent("Organization", value: document.organization) }; if !document.revisionYear.isEmpty { LabeledContent("Revision / year", value: document.revisionYear) }; if !document.sourceType.isEmpty { LabeledContent("Source type", value: document.sourceType) }; LabeledContent("File", value: document.fileName.isEmpty ? "Not linked" : document.fileName); Text(document.notes.isEmpty ? "No notes recorded." : document.notes).foregroundStyle(.secondary) } }
                Panel { VStack(alignment: .leading, spacing: 10) { SectionTitle("Associated knowledge", icon: "link"); ForEach((try? store.recordIDs(documentID: document.id)) ?? [], id: \.self) { id in Label((try? store.record(id: id))?.name ?? "Unavailable record", systemImage: "cube") } } }
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

private struct MaterialsPage: View {
    let store: KnowledgeStore
    @Binding var refresh: UUID
    @Binding var targetID: String?
    @State private var selected: KnowledgeRecord?
    @State private var editor: KnowledgeRecord?
    @State private var adding = false
    @State private var confirmDeletion = false
    @State private var alert = ""
    private var records: [KnowledgeRecord] { (try? store.records(kind: .material)) ?? [] }
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) { Text("Materials").font(.title2.bold()); Text("Materials, alloys, and engineering grades").font(.caption).foregroundStyle(.secondary); ScrollView { LazyVStack(alignment: .leading, spacing: 3) { ForEach(records) { record in Button { selected = record } label: { VStack(alignment: .leading, spacing: 3) { Text(record.name); Text(record.secondary).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(9).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selected?.id == record.id)) } } }.frame(maxHeight: .infinity) }.padding(.top, 18).padding(.horizontal, 12).frame(minWidth: 240, idealWidth: 300)
            Divider()
            if let selected { MaterialDetail(record: selected, store: store, edit: { editor = selected }, delete: { confirmDeletion = true }) } else { ContentUnavailableView("Select a material", systemImage: "cube") }
        }
        .background(MITheme.canvas)
        .toolbar { Button("Add", systemImage: "plus") { adding = true } }
        .sheet(isPresented: $adding) { RecordEditor(kind: .material, store: store, done: { refresh = UUID(); reload() }) }
        .sheet(item: $editor) { RecordEditor(record: $0, store: store, done: { refresh = UUID(); reload() }) }
        .confirmationDialog("Delete this material?", isPresented: $confirmDeletion) {
            Button("Delete material", role: .destructive, action: delete)
        } message: { Text("Materials referenced by claims, relationships, or documents cannot be deleted.") }
        .alert("Cannot delete material", isPresented: Binding(get: { !alert.isEmpty }, set: { if !$0 { alert = "" } })) {
            Button("OK") {}
        } message: { Text(alert) }
        .onAppear(perform: reload).onChange(of: refresh) { _, _ in reload() }.onChange(of: targetID) { _, _ in reload() }
    }
    private func reload() {
        if let targetID, let found = records.first(where: { $0.id == targetID }) { selected = found }
        else if let selected { self.selected = records.first { $0.id == selected.id } ?? records.first }
        else { selected = records.first }
    }
    private func delete() {
        guard let selected else { return }
        do { try store.deleteRecord(id: selected.id); self.selected = nil; refresh = UUID(); reload() }
        catch { alert = "This material is referenced by a claim, relationship, or Library document. Remove those links first. \(error.localizedDescription)" }
    }
}

private struct MaterialDetail: View {
    let record: KnowledgeRecord
    let store: KnowledgeStore
    let edit: () -> Void
    let delete: () -> Void
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) { VStack(alignment: .leading, spacing: 6) { Text("Materials / \(record.secondary.isEmpty ? "Alloys" : record.secondary) / \(record.name)").font(.caption).foregroundStyle(.secondary); Text(record.name).font(.system(size: 30, weight: .bold, design: .rounded)) }; Spacer(); Button("Edit", action: edit).buttonStyle(.borderedProminent); Button("Delete", role: .destructive, action: delete) }
            HStack(spacing: 8) { Text(record.secondary.isEmpty ? "Material" : record.secondary).padding(.horizontal, 10).padding(.vertical, 5).background(.blue.opacity(0.12), in: Capsule()); Text("Local record").foregroundStyle(.secondary) }
            HStack(alignment: .top, spacing: 14) {
                Panel { VStack(alignment: .leading, spacing: 12) { SectionTitle("Material profile", icon: "cube"); detailRow("Common name", record.name); detailRow("Designation", record.secondary.isEmpty ? "Not recorded" : record.secondary); detailRow("Class", "Material record"); detailRow("Notes", record.detail.isEmpty ? "No detail recorded." : record.detail); Divider(); Text("Source-preserved engineering knowledge").font(.headline); Text("Properties and context remain attached to local records and their evidence.").foregroundStyle(.secondary) } }.frame(maxWidth: .infinity)
                claimsPanel.frame(maxWidth: .infinity)
            }
            Panel { VStack(alignment: .leading, spacing: 12) { SectionTitle("Relationship map", icon: "arrow.triangle.branch"); ForEach((try? store.relationships(recordID: record.id)) ?? []) { relationship in let other = relationship.fromID == record.id ? relationship.toID : relationship.fromID; HStack { Image(systemName: "link").foregroundStyle(.blue); Text((try? store.record(id: other))?.name ?? "Unknown record"); Spacer(); Text(relationship.predicate.replacingOccurrences(of: "_", with: " ")).foregroundStyle(.secondary) } } } }
        }.padding(28).frame(maxWidth: .infinity, alignment: .leading) }.background(MITheme.canvas)
    }
    private var claimsPanel: some View { Panel { VStack(alignment: .leading, spacing: 12) { HStack { SectionTitle("Key claims & evidence", icon: "checkmark.seal"); Spacer(); Text("\((try? store.claims(subjectID: record.id).count) ?? 0) claims").font(.caption).foregroundStyle(.secondary) }; ForEach((try? store.claims(subjectID: record.id)) ?? []) { claim in VStack(alignment: .leading, spacing: 6) { Text(claim.statement); HStack { StatusBadge(title: claim.status.title, color: claim.status == .verified ? .green : .orange); Text((try? store.record(id: claim.sourceID))?.name ?? "Unknown source").font(.caption).foregroundStyle(.secondary) }; if !claim.locator.isEmpty { Text(claim.locator).font(.caption2).foregroundStyle(.tertiary) } }; if claim.id != ((try? store.claims(subjectID: record.id)) ?? []).last?.id { Divider() } } } } }
    private func detailRow(_ title: String, _ value: String) -> some View { HStack(alignment: .top) { Text(title).foregroundStyle(.secondary).frame(width: 110, alignment: .leading); Text(value); Spacer() } }
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
            ScrollView { LazyVStack(alignment: .leading, spacing: 3) { ForEach(records) { record in Button { selected = record } label: { VStack(alignment: .leading, spacing: 3) { Text(record.name); Text(record.secondary).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(8).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selected?.id == record.id)) } } }.frame(minWidth: 220, idealWidth: 300)
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
        .onChange(of: refresh) { _, _ in reload() }.background(MITheme.canvas)
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
                    VStack(alignment: .leading, spacing: 5) { Text(record.name).font(.system(size: 30, weight: .bold, design: .rounded)); Text(record.kind.rawValue.capitalized).font(.subheadline).foregroundStyle(.secondary) }
                    Spacer()
                    Button("Edit", action: edit).buttonStyle(.borderedProminent)
                    Button("Delete", role: .destructive, action: delete)
                }
                HStack(spacing: 8) { if !record.secondary.isEmpty { Text(record.secondary).font(.subheadline).padding(.horizontal, 10).padding(.vertical, 5).background(.blue.opacity(0.12), in: Capsule()) }; Text("Local record").font(.subheadline).foregroundStyle(.secondary) }
                Panel { VStack(alignment: .leading, spacing: 10) { SectionTitle("Profile", icon: "cube"); Text(record.detail.isEmpty ? "No detail recorded." : record.detail).foregroundStyle(.secondary) } }
                Panel { VStack(alignment: .leading, spacing: 10) { SectionTitle("Claims & evidence", icon: "checkmark.seal"); ForEach((try? store.claims(subjectID: record.id)) ?? []) { claim in HStack(alignment: .top) { Image(systemName: "doc.text").foregroundStyle(.blue); VStack(alignment: .leading, spacing: 3) { Text(claim.statement); Text("\(claim.status.title) · \((try? store.record(id: claim.sourceID))?.name ?? "Unknown source")").font(.caption).foregroundStyle(.secondary) }; Spacer(); StatusBadge(title: claim.status.title, color: claim.status == .verified ? .green : .orange) } } } }
                Panel { VStack(alignment: .leading, spacing: 10) { SectionTitle("Relationships", icon: "arrow.triangle.branch"); ForEach((try? store.relationships(recordID: record.id)) ?? []) { relationship in let id = relationship.fromID == record.id ? relationship.toID : relationship.fromID; Label { Text((try? store.record(id: id))?.name ?? "Unknown"); Text(relationship.predicate.replacingOccurrences(of: "_", with: " ")).font(.caption).foregroundStyle(.secondary) } icon: { Image(systemName: "link") } } } } }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(28)
        }
    }

struct StatusBadge: View { let title: String; let color: Color; var body: some View { Text(title).font(.caption.weight(.semibold)).foregroundStyle(color).padding(.horizontal, 8).padding(.vertical, 4).background(color.opacity(0.12), in: Capsule()) } }

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
            ScrollView { LazyVStack(alignment: .leading, spacing: 3) { ForEach(claims) { claim in Button { selected = claim } label: { VStack(alignment: .leading, spacing: 3) { Text(claim.statement).lineLimit(2); Text("\(claim.status.title) · \((try? store.record(id: claim.sourceID))?.name ?? "Unknown source")").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(8).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selected?.id == claim.id)) } } }.frame(minWidth: 260, idealWidth: 360)
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
        .onChange(of: targetID) { _, _ in reload() }.background(MITheme.canvas)
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
        ScrollView { LazyVStack(alignment: .leading, spacing: 3) { ForEach(relationships) { relationship in let from = (try? store.record(id: relationship.fromID))?.name ?? "?"; let to = (try? store.record(id: relationship.toID))?.name ?? "?"; Button { selected = relationship } label: { Text("\(from) — \(relationship.predicate.replacingOccurrences(of: "_", with: " ")) — \(to)").frame(maxWidth: .infinity, alignment: .leading).padding(10).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selected?.id == relationship.id)) } }.padding(12) }
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
