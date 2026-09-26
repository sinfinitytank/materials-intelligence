import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case overview, ask, materials, damageMechanisms, components, standards, library, settings
    var id: Self { self }
    var title: String {
        switch self { case .overview: "Overview"; case .ask: "Ask"; case .materials: "Materials"; case .damageMechanisms: "Damage Mechanisms"; case .components: "Components"; case .standards: "Standards"; case .library: "Library"; case .settings: "Settings" }
    }
    var symbol: String {
        switch self { case .overview: "rectangle.3.group"; case .ask: "bubble.left.and.text.bubble.right"; case .materials: "square.stack.3d.up"; case .damageMechanisms: "exclamationmark.shield"; case .components: "shippingbox"; case .standards: "checkmark.seal"; case .library: "books.vertical"; case .settings: "gearshape" }
    }
}

struct RootView: View {
    @State private var selection: AppSection? = .overview
    @State private var store: KnowledgeStore?
    @State private var loadError: String?
    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection)
        } detail: {
            if let selection { SectionPage(section: selection, store: store, loadError: loadError) } else { ContentUnavailableView("Select a section", systemImage: "sidebar.left") }
        }
        .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        .frame(minWidth: 900, minHeight: 560)
        .task {
            do { let opened = try KnowledgeStore(url: KnowledgeStore.applicationURL()); try opened.seedIfEmpty(); store = opened }
            catch { loadError = error.localizedDescription }
        }
    }
}

private extension AppSection {
    var recordKind: RecordKind? {
        switch self { case .materials: .material; case .damageMechanisms: .mechanism; case .standards: .standard; case .components: .component; case .library: .source; default: nil }
    }
}

private struct Sidebar: View {
    @Binding var selection: AppSection?
    var body: some View {
        List(selection: $selection) {
            Section("Workspace") {
                ForEach(AppSection.allCases.filter { $0 != .settings }) { section in
                    Label(section.title, systemImage: section.symbol).tag(Optional(section))
                }
            }
            Section { Label(AppSection.settings.title, systemImage: AppSection.settings.symbol).tag(Optional(AppSection.settings)) }
        }
        .listStyle(.sidebar)
        .navigationTitle("Materials Intelligence")
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) { Image(systemName: "lock.shield").foregroundStyle(.secondary); Text("Local workspace").font(.caption).foregroundStyle(.secondary); Spacer() }.padding(.horizontal, 12).padding(.vertical, 10)
        }
    }
}

private struct SectionPage: View {
    let section: AppSection
    let store: KnowledgeStore?
    let loadError: String?
    var body: some View {
        Group { if section == .overview { OverviewPage() } else if let kind = section.recordKind { KnowledgePage(kind: kind, store: store, loadError: loadError) } else if section == .settings { SettingsPage() } else { EmptySectionPage(section: section) } }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Refresh", systemImage: "arrow.clockwise") {}.help("Refresh this view")
                    Button("Add", systemImage: "plus") {}.help("Add an item when this section is available")
                }
            }
            .searchable(text: .constant(""), placement: .toolbar, prompt: "Search workspace")
    }
}

private struct OverviewPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignMetrics.sectionSpacing) {
                PageHeading(title: "Overview", subtitle: "Your local engineering workspace")
                HStack(alignment: .top, spacing: DesignMetrics.cardSpacing) {
                    SummaryCard(title: "Materials", value: "—", symbol: "square.stack.3d.up", tint: .blue)
                    SummaryCard(title: "Library", value: "—", symbol: "books.vertical", tint: .purple)
                    SummaryCard(title: "Open work", value: "—", symbol: "checklist", tint: .orange)
                }
                EmptyStatePanel(title: "Your workspace is ready", message: "Materials Intelligence is set up for local engineering knowledge. Add content in a later phase to begin building your library.", symbol: "sparkles")
            }.padding(DesignMetrics.pagePadding)
        }.navigationTitle("Overview")
    }
}

private struct EmptySectionPage: View {
    let section: AppSection
    var body: some View { EmptyStatePanel(title: section.title, message: "This workspace is ready for future engineering content.", symbol: section.symbol).padding(DesignMetrics.pagePadding).navigationTitle(section.title) }
}

private struct SettingsPage: View {
    var body: some View {
        Form {
            Section("Workspace") { LabeledContent("Storage", value: "Local"); LabeledContent("Appearance", value: "System") }
            Section("About") { LabeledContent("Application", value: "Materials Intelligence"); LabeledContent("Version", value: "1.0") }
        }.formStyle(.grouped).padding(DesignMetrics.pagePadding).frame(maxWidth: 680, alignment: .leading).navigationTitle("Settings")
    }
}

private struct PageHeading: View {
    let title: String; let subtitle: String
    var body: some View { VStack(alignment: .leading, spacing: 6) { Text(title).font(.largeTitle.bold()); Text(subtitle).foregroundStyle(.secondary) } }
}

private struct SummaryCard: View {
    let title: String; let value: String; let symbol: String; let tint: Color
    var body: some View { VStack(alignment: .leading, spacing: 14) { Image(systemName: symbol).font(.title2).foregroundStyle(tint); Text(value).font(.title.bold()); Text(title).font(.subheadline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10)) }
}

private struct EmptyStatePanel: View {
    let title: String; let message: String; let symbol: String
    var body: some View { ContentUnavailableView { Label(title, systemImage: symbol) } description: { Text(message) }.frame(maxWidth: .infinity, minHeight: 230).background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 12)) }
}

private enum DesignMetrics { static let pagePadding: CGFloat = 28; static let cardSpacing: CGFloat = 14; static let sectionSpacing: CGFloat = 28 }


private struct KnowledgePage: View {
    let kind: RecordKind
    let store: KnowledgeStore?
    let loadError: String?
    @State private var selectedID: String?
    private var records: [KnowledgeRecord] { (try? store?.records(kind: kind)) ?? [] }
    var body: some View {
        if let loadError { ContentUnavailableView("Database unavailable", systemImage: "externaldrive.badge.exclamationmark", description: Text(loadError)) }
        else if store == nil { ProgressView("Opening local knowledge") }
        else {
            HStack(spacing: 0) {
                List(records, selection: $selectedID) { record in
                    VStack(alignment: .leading) { Text(record.name); if !record.secondary.isEmpty { Text(record.secondary).font(.caption).foregroundStyle(.secondary) } }.tag(record.id)
                }.frame(minWidth: 250, idealWidth: 300)
                Divider()
                if let selectedID, let record = try? store?.record(id: selectedID) { KnowledgeDetail(record: record, store: store!) }
                else { ContentUnavailableView("Select a record", systemImage: "doc.text") }
            }
        }
    }
}

private struct KnowledgeDetail: View {
    let record: KnowledgeRecord
    let store: KnowledgeStore
    var body: some View {
        let claims = (try? store.claims(subjectID: record.id)) ?? []
        let relationships = (try? store.relationships(recordID: record.id)) ?? []
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(record.name).font(.largeTitle.bold())
                Text(record.detail).foregroundStyle(.secondary)
                if !record.secondary.isEmpty { Text(record.secondary) }
                if !relationships.isEmpty {
                    Text("Relationships").font(.title2.bold())
                    ForEach(relationships) { link in
                        let otherID = link.fromID == record.id ? link.toID : link.fromID
                        if let other = try? store.record(id: otherID) { LabeledContent(link.predicate.replacingOccurrences(of: "_", with: " "), value: other.name) }
                    }
                }
                if !claims.isEmpty {
                    Text("Engineering claims").font(.title2.bold())
                    ForEach(claims) { claim in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(claim.statement)
                            Text("\(claim.status.rawValue.capitalized) · Source: \((try? store.record(id: claim.sourceID))?.name ?? "Unknown")\(claim.locator.isEmpty ? "" : " · \(claim.locator)")").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(28)
        }
    }
}
