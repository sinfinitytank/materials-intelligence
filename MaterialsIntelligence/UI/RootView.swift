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
    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection)
        } detail: {
            if let selection { SectionPage(section: selection) } else { ContentUnavailableView("Select a section", systemImage: "sidebar.left") }
        }
        .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        .frame(minWidth: 900, minHeight: 560)
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
    var body: some View {
        Group { if section == .overview { OverviewPage() } else if section == .settings { SettingsPage() } else { EmptySectionPage(section: section) } }
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
