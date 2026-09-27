import SwiftUI
import AppKit

enum AppSection: String, CaseIterable, Identifiable { case agent, personalVault, assessment, explorer, overview, ask, search, library, research, materials, mechanisms, standards, components, sources, claims, relationships, settings, about
 var id: Self { self }; var title: String { switch self { case .agent:"Engineering Agent"; case .personalVault:"Personal Vault"; case .assessment:"Engineering Tools"; case .explorer:"Explorer"; case .overview:"Overview"; case .ask:"Ask"; case .search:"Search"; case .library:"Library"; case .research:"Research"; case .materials:"Materials"; case .mechanisms:"Damage Mechanisms"; case .standards:"Standards"; case .components:"Components"; case .sources:"Sources"; case .claims:"Claims"; case .relationships:"Relationships"; case .settings:"Settings"; case .about:"About" } }
 var kind: RecordKind? { switch self { case .materials:.material; case .mechanisms:.mechanism; case .standards:.standard; case .components:.component; case .sources:.source; default:nil } }
}

struct RootView: View { @Binding var selection: AppSection?; @State private var store: KnowledgeStore?; @State private var error: String?; @State private var refresh = UUID(); @State private var targetID: String?
 var body: some View { NavigationSplitView { Sidebar(selection: $selection) } detail: { if let selection { Page(section: selection, store: store, refresh: $refresh, targetID: $targetID, error: error, openResult: openResult, navigate: navigate).accessibilityIdentifier("workspace.page.\(selection.rawValue)") } }.navigationSplitViewStyle(.balanced).frame(minWidth: 1040, minHeight: 680).tint(MITheme.accent).toolbar { ToolbarItem(placement: .primaryAction) { Button { selection = .about } label: { Label("About", systemImage: "info.circle") }.accessibilityIdentifier("toolbar.about") } }.task { do { let s = try KnowledgeStore(url: try KnowledgeStore.applicationURL()); try s.seedIfEmpty(); store=s } catch let caught { error=caught.localizedDescription } } }
 private func openResult(_ result: SearchResult) { targetID=result.id; switch result.entityType { case .document: selection = .library; case .claim: selection = .claims; case .record: if let kind=RecordKind(rawValue:result.kind) { selection = AppSection.allCases.first { $0.kind == kind } } } }
 private func navigate(_ section: AppSection) { targetID = nil; selection = section }
}
private struct Sidebar: View { @Binding var selection: AppSection?
 var body: some View { VStack(alignment: .leading, spacing: 0) {
  HStack(spacing: MITheme.Space.regular) {
   BrandMark(size: 32)
   VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text("MATERIALS").font(MITheme.Typography.metadata.weight(.bold)).tracking(1.1); Text("Intelligence").font(MITheme.Typography.sectionTitle) }
  }.padding(.horizontal, MITheme.Space.panel).padding(.top, MITheme.Space.page).padding(.bottom, MITheme.Space.panel)
  Divider().padding(.horizontal, MITheme.Space.panel)
  ScrollView {
  VStack(alignment: .leading, spacing: MITheme.Space.tight) {
    sidebarSection("Workspace", items: [.overview, .ask, .search, .explorer, .research])
    sidebarSection("Engineering records", items: [.materials, .mechanisms, .components, .standards, .sources])
    sidebarSection("Evidence", items: [.library, .claims, .relationships])
    sidebarSection("Workflows", items: [.assessment, .agent, .personalVault])
   }.padding(.horizontal, MITheme.Space.regular)
  }
  Spacer()
  Divider().padding(.horizontal, MITheme.Space.panel)
  nav(.settings).padding(.horizontal, MITheme.Space.regular).padding(.top, MITheme.Space.compact)
  nav(.about).padding(.horizontal, MITheme.Space.regular).padding(.top, MITheme.Space.tight)
  HStack(spacing: MITheme.Space.compact) { Circle().fill(MITheme.accent.opacity(0.8)).frame(width: 7, height: 7); VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text("Local workspace").font(MITheme.Typography.metadata.weight(.semibold)); Text("Offline · SQLite + FTS5").font(MITheme.Typography.metadata).foregroundStyle(.secondary) } }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, MITheme.Space.panel).padding(.top, MITheme.Space.regular).padding(.bottom, MITheme.Space.panel)
 }.frame(minWidth: 205, idealWidth: 224, maxWidth: 250).background(MITheme.sidebar) }
 private func nav(_ section: AppSection) -> some View { SidebarNavigationItem(section: section, selection: $selection) }
 private func sidebarSection(_ title: String, items: [AppSection]) -> some View { VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(title.uppercased()).font(MITheme.Typography.metadata.weight(.bold)).tracking(1.0).foregroundStyle(.tertiary).padding(.leading, MITheme.Space.regular).padding(.top, MITheme.Space.panel).padding(.bottom, MITheme.Space.tight); ForEach(items) { nav($0) } } }
}

private struct BrandMark: View {
 let size: CGFloat

 var body: some View {
  ZStack {
   RoundedRectangle(cornerRadius: size * 0.22, style: .continuous).fill(MITheme.accent)
   Canvas { context, canvasSize in
    let points: [(CGFloat, CGFloat)] = [
     (0.50, 0.17), (0.79, 0.335), (0.79, 0.665),
     (0.50, 0.83), (0.21, 0.665), (0.21, 0.335)
    ]
    var outline = Path()
    outline.move(to: CGPoint(x: points[0].0 * canvasSize.width, y: points[0].1 * canvasSize.height))
    for point in points.dropFirst() {
     outline.addLine(to: CGPoint(x: point.0 * canvasSize.width, y: point.1 * canvasSize.height))
    }
    outline.closeSubpath()

    var facets = Path()
    let center = CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.5)
    for point in points {
     facets.move(to: center)
     facets.addLine(to: CGPoint(x: point.0 * canvasSize.width, y: point.1 * canvasSize.height))
    }
    let lineWidth = max(canvasSize.width * 0.038, 1)
    context.stroke(outline, with: .color(.white.opacity(0.94)), style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
    context.stroke(facets, with: .color(.white.opacity(0.76)), style: StrokeStyle(lineWidth: lineWidth * 0.78, lineCap: .round))
    let nodeSize = canvasSize.width * 0.12
    let node = CGRect(x: center.x - nodeSize / 2, y: center.y - nodeSize / 2, width: nodeSize, height: nodeSize)
    context.fill(Path(ellipseIn: node), with: .color(Color(red: 0.70, green: 0.87, blue: 0.82)))
   }
  }
  .frame(width: size, height: size)
  .accessibilityHidden(true)
 }
}

private struct SidebarNavigationItem: View {
 let section: AppSection
 @Binding var selection: AppSection?
 @State private var hovering = false
 private var isSelected: Bool { selection == section }
 var body: some View {
  Button { selection = section } label: {
   HStack(spacing: MITheme.Space.compact) {
    Capsule().fill(isSelected ? MITheme.accent : .clear).frame(width: 2, height: 15)
    Label(section.title, systemImage: section.symbol).font(MITheme.Typography.navigation.weight(isSelected ? .semibold : .regular)).frame(maxWidth: .infinity, alignment: .leading)
   }.foregroundStyle(isSelected ? MITheme.accent : Color.primary.opacity(0.82)).padding(.vertical, MITheme.Space.tight + 2).padding(.trailing, MITheme.Space.compact).background(isSelected ? MITheme.selected : (hovering ? Color.primary.opacity(0.045) : .clear), in: RoundedRectangle(cornerRadius: MITheme.Radius.selection, style: .continuous))
  }.buttonStyle(.plain).accessibilityLabel(section.title).accessibilityIdentifier("navigation.\(section.rawValue)").accessibilityAddTraits(isSelected ? .isSelected : []).onHover { hovering = $0 }
 }
}
private struct SidebarButtonStyle: ButtonStyle {
 let selected: Bool
 func makeBody(configuration: Configuration) -> some View {
  configuration.label.font(MITheme.Typography.navigation.weight(selected ? .semibold : .regular))
   .foregroundStyle(selected ? MITheme.accent : .primary)
   .background(selected ? MITheme.selected : (configuration.isPressed ? Color.primary.opacity(0.07) : .clear), in: RoundedRectangle(cornerRadius: MITheme.Radius.selection, style: .continuous))
   .opacity(configuration.isPressed ? 0.8 : 1)
 }
}
private extension AppSection { var symbol:String { switch self { case .agent:"sparkles"; case .personalVault:"icloud"; case .assessment:"wrench.and.screwdriver"; case .explorer:"point.3.connected.trianglepath.dotted"; case .overview:"house"; case .ask:"questionmark.bubble"; case .search:"magnifyingglass"; case .library:"books.vertical"; case .research:"doc.badge.plus"; case .materials:"cube"; case .mechanisms:"exclamationmark.shield"; case .standards:"text.book.closed"; case .components:"gearshape"; case .sources:"doc.text"; case .claims:"checkmark.seal"; case .relationships:"link"; case .settings:"gear"; case .about:"info.circle" } } }

private struct Page: View { let section: AppSection; let store: KnowledgeStore?; @Binding var refresh: UUID; @Binding var targetID:String?; let error: String?; let openResult:(SearchResult)->Void; let navigate:(AppSection)->Void
 var body: some View { Group { if section == .about { AboutPage() } else if let error { ContentUnavailableView("Database unavailable", systemImage:"externaldrive.badge.exclamationmark", description:Text(error)) } else if let store { if section == .agent { AgentPage(store: store) } else if section == .personalVault { PersonalVaultLauncher() } else if section == .assessment { AssessmentPage(store: store) } else if section == .explorer { GraphPage(store: store, openResult: openResult) } else if section == .overview { Overview(store: store, navigate: navigate) } else if section == .materials { MaterialsPage(store: store, refresh: $refresh, targetID: $targetID) } else if let kind=section.kind { RecordPage(kind:kind, store:store, refresh:$refresh, targetID:$targetID) } else if section == .search { SearchPage(store:store, openResult:openResult) } else if section == .library { LibraryPage(store:store, refresh:$refresh, targetID:$targetID) } else if section == .research { ResearchPage(store: store) } else if section == .claims { ClaimsPage(store:store, refresh:$refresh, targetID:$targetID) } else if section == .relationships { RelationshipsPage(store:store, refresh:$refresh) } else if section == .ask { AskPage(store: store, openResult: openResult) } else if section == .settings { SettingsPage() } else { Overview(store:store, navigate:navigate) } } else { ProgressView("Opening local knowledge") } }.toolbar { Button("Refresh", systemImage:"arrow.clockwise") { refresh=UUID() }.accessibilityIdentifier("toolbar.refresh") } }
}

private struct AboutPage: View {
 private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }

 var body: some View {
  ScrollView {
   VStack(alignment: .leading, spacing: MITheme.Space.page) {
    HStack(spacing: MITheme.Space.panel) {
     BrandMark(size: 72)
   VStack(alignment: .leading, spacing: MITheme.Space.compact) {
      Text("Materials Intelligence").font(MITheme.Typography.pageTitle)
      Text("Materials knowledge, made clear.").font(MITheme.Typography.supporting).foregroundStyle(.secondary)
     }
    }
    Text("A native workspace for organizing materials records, reviewing claims against sources, and tracing relationships across engineering knowledge.")
     .font(MITheme.Typography.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    Panel {
     VStack(spacing: MITheme.Space.regular) {
      LabeledContent("Version", value: version)
      Divider()
      LabeledContent("Platform", value: "macOS 26 or later")
      Divider()
      LabeledContent("Knowledge store", value: "On this Mac · SQLite")
      Divider()
      LabeledContent("Privacy", value: "Local by default · sync is optional")
     }
    }
    Panel {
     Label {
      Text("Early development release. Review technical evidence before applying it to engineering decisions.")
       .font(MITheme.Typography.metadata).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
     } icon: {
      Image(systemName: "checkmark.seal").foregroundStyle(MITheme.accent)
     }
    }
    Text("© 2026 Siddharth Tank").font(MITheme.Typography.metadata).foregroundStyle(.tertiary)
   }
   .frame(maxWidth: 640, alignment: .leading)
   .padding(MITheme.Space.inset)
   .frame(maxWidth: .infinity, alignment: .topLeading)
  }
  .background(MITheme.canvas)
  .accessibilityIdentifier("about.page")
 }
}
private struct SettingsPage: View {
 var body: some View {
  VStack(alignment: .leading, spacing: MITheme.Space.page) {
   PageHeader(title: "Settings", subtitle: "Local storage and application behavior")
   Panel {
    VStack(alignment: .leading, spacing: MITheme.Space.regular) {
     LabeledContent("Storage", value: "Local Application Support database")
     LabeledContent("Search", value: "Offline SQLite FTS5")
     Divider()
     Text("Documents remain at their original locations. Library keeps access bookmarks and metadata.").foregroundStyle(.secondary)
    }
   }
  }
  .font(MITheme.Typography.body)
  .padding(MITheme.Space.inset)
  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  .background(MITheme.canvas)
 }
}

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
            VStack(alignment: .leading, spacing: MITheme.Space.page) {
                PageHeader(title: "Ask", subtitle: "Evidence-grounded answers from your local materials knowledge base.")
                HStack { Image(systemName: "desktopcomputer"); Text("LOCAL · database search and on-device model only").font(MITheme.Typography.metadata.weight(.semibold)) }.foregroundStyle(.secondary)
                if let unavailable = provider.availabilityMessage { Panel { Label(unavailable, systemImage: "cpu").foregroundStyle(MITheme.caution) } }
                Panel {
                    VStack(alignment: .leading, spacing: MITheme.Space.regular) {
                        TextField("Ask an engineering question…", text: $question, axis: .vertical).lineLimit(2...4)
                        HStack { Spacer(); Button("Ask locally") { submit() }.buttonStyle(.borderedProminent).disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loading) }
                    }
                }
                if loading { ProgressView("Searching evidence and asking the local model…") }
                if !error.isEmpty { Panel { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(MITheme.danger) } }
                if let answer {
                    Panel {
                        VStack(alignment: .leading, spacing: MITheme.Space.panel) {
                            HStack { SectionTitle("Answer", icon: "text.bubble"); Spacer(); if answer.generatedLocally { StatusBadge(title: "LOCAL — no internet used", color: MITheme.success) } }
                            if let message = answer.message { Text(message).foregroundStyle(.secondary) }
                            ForEach(answer.points) { point in
                                VStack(alignment: .leading, spacing: MITheme.Space.compact) {
                                    Text(point.text)
                                    Text("Generated explanation · check the claims below").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
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
                            VStack(alignment: .leading, spacing: MITheme.Space.regular) {
                                SectionTitle("Supporting claims and sources", icon: "books.vertical")
                                ForEach(answer.found) { item in
                                    VStack(alignment: .leading, spacing: MITheme.Space.tight) {
                                        Text(item.claim.statement)
                                        Text("\(item.claim.status.title) · \(item.subject.name) · \(item.claim.locator.isEmpty ? "No locator" : item.claim.locator)").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
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
                Text("Library document contents are not indexed. Illustrative or unreviewed claims do not authorize a generated engineering conclusion.").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
            }.font(MITheme.Typography.body).frame(maxWidth: 860, alignment: .leading).padding(MITheme.Space.inset).frame(maxWidth: .infinity, alignment: .leading)
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
 var body: some View { ScrollView { VStack(alignment: .leading, spacing: MITheme.Space.page) {
  PageHeader(title: "Materials Intelligence", subtitle: "A local workspace for materials knowledge and source-traceable evidence.")
  LazyVGrid(columns: [GridItem(.adaptive(minimum: 185), spacing: MITheme.Space.regular)], alignment: .leading, spacing: MITheme.Space.regular) {
   metric("Knowledge records", value: totalRecords, note: "materials, mechanisms, standards and sources", icon: "square.stack.3d.up")
   metric("Engineering claims", value: claims, note: "stored with subject and source links", icon: "checkmark.seal")
   metric("Library documents", value: documents, note: "metadata and local file references", icon: "books.vertical")
  }
  LazyVGrid(columns: [GridItem(.flexible(), spacing: MITheme.Space.regular), GridItem(.flexible(), spacing: MITheme.Space.regular)], alignment: .leading, spacing: MITheme.Space.regular) { coverage; activity }
  LazyVGrid(columns: [GridItem(.flexible(minimum: 420), spacing: MITheme.Space.regular), GridItem(.flexible(minimum: 235), spacing: MITheme.Space.regular)], alignment: .leading, spacing: MITheme.Space.regular) {
   Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) {
    SectionTitle("Open a workspace", icon: "arrow.up.right.square")
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: MITheme.Space.compact)], spacing: MITheme.Space.compact) {
     action("Ask", "questionmark.bubble", .ask); action("Search evidence", "magnifyingglass", .search); action("Explore relationships", "point.3.connected.trianglepath.dotted", .explorer); action("Review research", "doc.badge.plus", .research)
    }
   } }
   Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { SectionTitle("Workspace status", icon: "externaldrive")
    statusRow("Database", "On this Mac"); statusRow("Search", "SQLite FTS5"); statusRow("Files", "Remain at source location")
   } }
  }
 }.padding(MITheme.pageInset) }.background(MITheme.canvas) }
 private var totalRecords: String { "\((try? store.records().count) ?? 0)" }; private var claims: String { "\((try? store.claims().count) ?? 0)" }; private var documents: String { "\((try? store.documents().count) ?? 0)" }
 private func color(for kind: RecordKind) -> Color { MITheme.categoryColor(for: kind) }
 private func section(for kind: RecordKind) -> AppSection { switch kind { case .material: .materials; case .mechanism: .mechanisms; case .standard: .standards; case .component: .components; case .source: .sources } }
 private var coverage: some View { Panel { VStack(alignment: .leading, spacing: MITheme.Space.compact) { SectionTitle("Records by type", icon: "chart.bar.xaxis"); ForEach(RecordKind.allCases, id: \.self) { k in Button { navigate(section(for: k)) } label: { HStack(spacing: MITheme.Space.compact) { Circle().fill(color(for: k)).frame(width: 7, height: 7); Text(k.rawValue.capitalized); Spacer(); Text("\((try? store.records(kind: k).count) ?? 0)").font(.system(.body, design: .monospaced)).foregroundStyle(.secondary); Image(systemName: "chevron.right").font(MITheme.Typography.metadata).foregroundStyle(.tertiary) }.contentShape(Rectangle()) }.buttonStyle(.plain).padding(.vertical, MITheme.Space.tight) } } } }
 private var activity: some View { Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { SectionTitle("Evidence coverage", icon: "point.3.connected.trianglepath.dotted"); Text("Each engineering claim retains its subject, source, review state, and recorded conditions.").font(MITheme.Typography.metadata).foregroundStyle(.secondary); Divider(); statusRow("Claims", claims); statusRow("Sources", "\((try? store.records(kind: .source).count) ?? 0)"); statusRow("Relationships", "\((try? store.relationships().count) ?? 0)") } } }
 private func action(_ title: String, _ icon: String, _ section: AppSection) -> some View { Button { navigate(section) } label: { Label(title, systemImage: icon).font(MITheme.Typography.supporting.weight(.medium)).frame(maxWidth: .infinity, minHeight: 40, alignment: .leading).padding(.horizontal, MITheme.Space.regular).background(MITheme.subtleSurface, in: RoundedRectangle(cornerRadius: MITheme.Radius.control, style: .continuous)).contentShape(Rectangle()) }.buttonStyle(.plain).accessibilityIdentifier("overview.action.\(section.rawValue)") }
 private func statusRow(_ title: String, _ value: String) -> some View { HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value) } }
 private func metric(_ title: String, value: String, note: String, icon: String) -> some View { Panel { HStack(alignment: .top, spacing: MITheme.Space.regular) { Image(systemName: icon).font(MITheme.Typography.sectionTitle).foregroundStyle(MITheme.accent).frame(width: 24, alignment: .leading).padding(.top, MITheme.Space.tight); VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(title.uppercased()).font(MITheme.Typography.metadata.weight(.bold)).tracking(0.7).foregroundStyle(.secondary); Text(value).font(MITheme.Typography.metricValue.monospacedDigit()); Text(note).font(MITheme.Typography.metadata).foregroundStyle(.secondary).lineLimit(2) } } } }
}
private struct SearchPage: View {
    let store: KnowledgeStore; let openResult:(SearchResult)->Void
    @State private var query = ""
    @State private var selectedTypes = Set(SearchEntityType.allCases)
    @State private var kind: RecordKind? = nil
    @State private var status: VerificationStatus? = nil
    @State private var results:[SearchResult] = []
    @State private var error = ""
    var body: some View { VStack(alignment:.leading, spacing: MITheme.Space.panel) {
        PageHeader(title: "Search", subtitle: "Find materials, claims, standards, and local documents.")
        HStack(spacing: MITheme.Space.compact) { Image(systemName: "magnifyingglass").foregroundStyle(MITheme.accent); TextField("Search local knowledge…", text:$query).textFieldStyle(.plain).onSubmit(search).accessibilityIdentifier("search.query"); if !query.isEmpty { Button("Clear", systemImage: "xmark.circle.fill") { query = ""; results = [] }.buttonStyle(.plain).foregroundStyle(.secondary) }; Button("Search", action:search).buttonStyle(.borderedProminent).keyboardShortcut(.return, modifiers:[]).accessibilityIdentifier("search.submit") }.padding(MITheme.Space.regular).background(MITheme.surface, in: RoundedRectangle(cornerRadius: MITheme.Radius.control, style: .continuous)).overlay(RoundedRectangle(cornerRadius: MITheme.Radius.control, style: .continuous).stroke(MITheme.separator, lineWidth: 0.7))
        filters
        if !error.isEmpty { Text(error).foregroundStyle(MITheme.danger) }
        if query.isEmpty { ContentUnavailableView("Search your local engineering knowledge", systemImage:"magnifyingglass", description:Text("Results rank full-text and prefix matches across records, claims, and Library metadata.")) } else { List(results) { result in Button { openResult(result) } label: { VStack(alignment:.leading,spacing:MITheme.Space.tight) { HStack { Text(result.title).font(MITheme.Typography.sectionTitle); Spacer(); Text(result.entityType.title).font(MITheme.Typography.metadata).padding(.horizontal, MITheme.Space.compact).padding(.vertical, MITheme.Space.tight).background(MITheme.selected, in:Capsule()) }; HighlightedText(text:result.detail, query:query).foregroundStyle(.secondary); Text(result.kind.replacingOccurrences(of:"_",with:" ")).font(MITheme.Typography.metadata).foregroundStyle(.tertiary) }.padding(.vertical, MITheme.Space.tight).frame(maxWidth:.infinity,alignment:.leading) }.buttonStyle(.plain).accessibilityLabel("Open \(result.entityType.title): \(result.title)") }.overlay { if results.isEmpty && error.isEmpty { ContentUnavailableView("No local matches", systemImage:"magnifyingglass") } } }
    }.font(MITheme.Typography.body).padding(MITheme.pageInset).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(MITheme.canvas).onChange(of: kind) { _,_ in search() }.onChange(of: status) { _,_ in search() }.onChange(of:selectedTypes) { _,_ in search() }.accessibilityIdentifier("workspace.search") }
    private var filters: some View { HStack { Menu("Types") { ForEach(SearchEntityType.allCases) { type in Toggle(type.title, isOn: typeBinding(type)) } }; Picker("Record type",selection:$kind){ Text("All records").tag(RecordKind?.none); ForEach(RecordKind.allCases,id:\.self) { recordKind in Text(recordKind.rawValue.capitalized).tag(Optional(recordKind)) } }.frame(width:180); Picker("Claim state",selection:$status) { Text("All claim states").tag(VerificationStatus?.none); ForEach(VerificationStatus.allCases,id:\.self) { claimStatus in Text(claimStatus.title).tag(Optional(claimStatus)) } }.frame(width:190); Spacer(); Text("Offline FTS5").font(MITheme.Typography.metadata).foregroundStyle(.secondary) } }
    private func typeBinding(_ type:SearchEntityType) -> Binding<Bool> { Binding(get:{selectedTypes.contains(type)},set:{ enabled in if enabled {selectedTypes.insert(type)} else {selectedTypes.remove(type)} }) }
    private func search() { do { results = try store.search(query, entityTypes:selectedTypes, recordKind:kind, verificationStatus:status); error="" } catch let caught { error=caught.localizedDescription; results=[] } }
}

private struct HighlightedText: View { let text:String; let query:String
    var body: some View { let words=query.split(whereSeparator:\.isWhitespace).map(String.init).filter{!$0.isEmpty}; Text(words.reduce(AttributedString(text)) { output, word in var value=output; var cursor=value.startIndex; while let range=value[cursor...].range(of:word,options:.caseInsensitive) { value[range].backgroundColor = MITheme.accent.opacity(0.18); cursor=range.upperBound }; return value }) }
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
            VStack(alignment: .leading, spacing: MITheme.Space.regular) { Text("Library").font(MITheme.Typography.pageTitle); Text("Local documents and source files").font(MITheme.Typography.metadata).foregroundStyle(.secondary); ScrollView { LazyVStack(alignment: .leading, spacing: MITheme.Space.tight) { ForEach(documents) { document in Button { selected = document } label: { VStack(alignment: .leading, spacing: MITheme.Space.tight) { Label(document.title, systemImage: "doc.text").lineLimit(1); Text([document.organization, document.revisionYear].filter { !$0.isEmpty }.joined(separator: " · ")).font(MITheme.Typography.metadata).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(MITheme.Space.compact).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selected?.id == document.id)) } } }.frame(maxWidth: .infinity, maxHeight: .infinity) }.padding(.top, MITheme.Space.panel).frame(minWidth: 250, idealWidth: 320)
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
            VStack(alignment: .leading, spacing: MITheme.Space.page) {
                HStack {
                    VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(document.title).font(MITheme.Typography.pageTitle); Text("Library document").font(MITheme.Typography.metadata).foregroundStyle(.secondary) }
                    Spacer()
                    Button("Open document", action: open).buttonStyle(.borderedProminent)
                    Button("Locate file…", action: locate)
                    Button("Edit metadata") { editing = true }
                }
                Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { SectionTitle("Document details", icon: "info.circle"); if !document.organization.isEmpty { LabeledContent("Organization", value: document.organization) }; if !document.revisionYear.isEmpty { LabeledContent("Revision / year", value: document.revisionYear) }; if !document.sourceType.isEmpty { LabeledContent("Source type", value: document.sourceType) }; LabeledContent("File", value: document.fileName.isEmpty ? "Not linked" : document.fileName); Text(document.notes.isEmpty ? "No notes recorded." : document.notes).foregroundStyle(.secondary) } }
                Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { SectionTitle("Associated knowledge", icon: "link"); ForEach((try? store.recordIDs(documentID: document.id)) ?? [], id: \.self) { id in Label((try? store.record(id: id))?.name ?? "Unavailable record", systemImage: "cube") } } }
                Button("Remove from Library", role: .destructive) { confirmRemoval = true }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(MITheme.pageInset)
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
        guard !document.bookmark.isEmpty else {
            message = "No usable file reference is stored. Use Locate file to restore access. Metadata and associations remain available."
            return
        }
        do {
            let reference = try LibraryFileAccess.resolve(document.bookmark)
            let url = reference.url
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard reference.isReadable else {
                message = "This file is missing or inaccessible. Use Locate file to reconnect it. Metadata and associations are retained."
                return
            }
            guard NSWorkspace.shared.open(url) else {
                message = "macOS could not open this file. Use Locate file if it has moved. Metadata and associations are retained."
                return
            }
            if reference.bookmarkWasStale {
                do {
                    var updated = document
                    updated.bookmark = try LibraryFileAccess.makeBookmark(for: url)
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
            let updated = try LibraryFileAccess.relink(document, to: url)
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
            Text(error).foregroundStyle(MITheme.danger)
        }
        .padding(MITheme.Space.panel).frame(width: 560, height: 620)
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
            var updated = LibraryDocument(id: document?.id ?? UUID().uuidString, title: title.trimmingCharacters(in: .whitespacesAndNewlines), organization: organization, revisionYear: revisionYear, sourceType: sourceType, notes: notes, fileName: document?.fileName ?? "", bookmark: document?.bookmark ?? "", addedAt: document?.addedAt ?? "")
            if let fileURL { updated = try LibraryFileAccess.relink(updated, to: fileURL) }
            try store.save(updated, recordIDs: Array(selectedIDs))
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
            VStack(alignment: .leading, spacing: MITheme.Space.regular) { Text("Materials").font(MITheme.Typography.pageTitle); Text("Materials, alloys, and engineering grades").font(MITheme.Typography.metadata).foregroundStyle(.secondary); ScrollView { LazyVStack(alignment: .leading, spacing: MITheme.Space.tight) { ForEach(records) { record in Button { selected = record } label: { VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(record.name); Text(record.secondary).font(MITheme.Typography.metadata).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(MITheme.Space.regular).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selected?.id == record.id)) } } }.frame(maxHeight: .infinity) }.padding(.top, MITheme.Space.panel).padding(.horizontal, MITheme.Space.regular).frame(minWidth: 240, idealWidth: 300)
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
        ScrollView { VStack(alignment: .leading, spacing: MITheme.Space.page) {
            HStack(alignment: .bottom) { VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text("Materials / \(record.secondary.isEmpty ? "Alloys" : record.secondary) / \(record.name)").font(MITheme.Typography.metadata).foregroundStyle(.secondary); Text(record.name).font(MITheme.Typography.pageTitle) }; Spacer(); Button("Edit", action: edit).buttonStyle(.borderedProminent); Button("Delete", role: .destructive, action: delete) }
            RelatedKnowledgeButton(store: store, recordID: record.id)
            HStack(spacing: MITheme.Space.compact) { Text(record.secondary.isEmpty ? "Material" : record.secondary).padding(.horizontal, MITheme.Space.regular).padding(.vertical, MITheme.Space.tight).background(MITheme.categoryColor(for: .material).opacity(0.12), in: Capsule()); Text("Local record").foregroundStyle(.secondary) }
            HStack(alignment: .top, spacing: MITheme.Space.panel) {
                Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { SectionTitle("Material profile", icon: "cube"); detailRow("Common name", record.name); detailRow("Designation", record.secondary.isEmpty ? "Not recorded" : record.secondary); detailRow("Class", "Material record"); detailRow("Notes", record.detail.isEmpty ? "No detail recorded." : record.detail); Divider(); Text("Source-preserved engineering knowledge").font(MITheme.Typography.sectionTitle); Text("Properties and context remain attached to local records and their evidence.").foregroundStyle(.secondary) } }.frame(maxWidth: .infinity)
                claimsPanel.frame(maxWidth: .infinity)
            }
            Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { SectionTitle("Relationship map", icon: "arrow.triangle.branch"); ForEach((try? store.relationships(recordID: record.id)) ?? []) { relationship in let other = relationship.fromID == record.id ? relationship.toID : relationship.fromID; HStack { Image(systemName: "link").foregroundStyle(MITheme.accent); Text((try? store.record(id: other))?.name ?? "Unknown record"); Spacer(); Text(relationship.predicate.replacingOccurrences(of: "_", with: " ")).foregroundStyle(.secondary) } } } }
        }.padding(MITheme.pageInset).frame(maxWidth: .infinity, alignment: .leading) }.background(MITheme.canvas)
    }
    private var claimsPanel: some View { Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { HStack { SectionTitle("Key claims & evidence", icon: "checkmark.seal"); Spacer(); Text("\((try? store.claims(subjectID: record.id).count) ?? 0) claims").font(MITheme.Typography.metadata).foregroundStyle(.secondary) }; ForEach((try? store.claims(subjectID: record.id)) ?? []) { claim in VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(claim.statement); HStack { StatusBadge(title: claim.status.title, color: MITheme.statusColor(for: claim.status)); Text((try? store.record(id: claim.sourceID))?.name ?? "Unknown source").font(MITheme.Typography.metadata).foregroundStyle(.secondary) }; if !claim.locator.isEmpty { Text(claim.locator).font(MITheme.Typography.metadata).foregroundStyle(.tertiary) } }; if claim.id != ((try? store.claims(subjectID: record.id)) ?? []).last?.id { Divider() } } } } }
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
            ScrollView { LazyVStack(alignment: .leading, spacing: MITheme.Space.tight) { ForEach(records) { record in Button { selected = record } label: { VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(record.name); Text(record.secondary).font(MITheme.Typography.metadata).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(MITheme.Space.compact).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selected?.id == record.id)) } } }.frame(minWidth: 220, idealWidth: 300)
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
            VStack(alignment: .leading, spacing: MITheme.Space.page) {
                HStack {
                    VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(record.name).font(MITheme.Typography.pageTitle); RelatedKnowledgeButton(store: store, recordID: record.id); Text(record.kind.rawValue.capitalized).font(MITheme.Typography.metadata).foregroundStyle(.secondary) }
                    Spacer()
                    Button("Edit", action: edit).buttonStyle(.borderedProminent)
                    Button("Delete", role: .destructive, action: delete)
                }
                HStack(spacing: MITheme.Space.compact) { if !record.secondary.isEmpty { Text(record.secondary).font(MITheme.Typography.supporting).padding(.horizontal, MITheme.Space.regular).padding(.vertical, MITheme.Space.tight).background(MITheme.categoryColor(for: record.kind).opacity(0.12), in: Capsule()) }; Text("Local record").font(MITheme.Typography.supporting).foregroundStyle(.secondary) }
                Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { SectionTitle("Profile", icon: "cube"); Text(record.detail.isEmpty ? "No detail recorded." : record.detail).foregroundStyle(.secondary) } }
                Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { SectionTitle("Claims & evidence", icon: "checkmark.seal"); ForEach((try? store.claims(subjectID: record.id)) ?? []) { claim in HStack(alignment: .top) { Image(systemName: "doc.text").foregroundStyle(MITheme.accent); VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(claim.statement); Text("\(claim.status.title) · \((try? store.record(id: claim.sourceID))?.name ?? "Unknown source")").font(MITheme.Typography.metadata).foregroundStyle(.secondary) }; Spacer(); StatusBadge(title: claim.status.title, color: MITheme.statusColor(for: claim.status)) } } } }
                Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) { SectionTitle("Relationships", icon: "arrow.triangle.branch"); ForEach((try? store.relationships(recordID: record.id)) ?? []) { relationship in let id = relationship.fromID == record.id ? relationship.toID : relationship.fromID; Label { Text((try? store.record(id: id))?.name ?? "Unknown"); Text(relationship.predicate.replacingOccurrences(of: "_", with: " ")).font(MITheme.Typography.metadata).foregroundStyle(.secondary) } icon: { Image(systemName: "link") } } } } }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(MITheme.pageInset)
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
            Text(error).foregroundStyle(MITheme.danger)
        }.padding(MITheme.Space.panel).frame(width: 460)
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

struct ClaimsPage: View {
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
            ScrollView { LazyVStack(alignment: .leading, spacing: MITheme.Space.tight) { ForEach(claims) { claim in Button { selected = claim } label: { VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(claim.statement).lineLimit(2); Text("\(claim.status.title) · \((try? store.record(id: claim.sourceID))?.name ?? "Unknown source")").font(MITheme.Typography.metadata).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(MITheme.Space.compact).contentShape(Rectangle()) }.buttonStyle(SidebarButtonStyle(selected: selected?.id == claim.id)) } } }.frame(minWidth: 260, idealWidth: 360)
            Divider()
            if let selected {
                ScrollView {
                    VStack(alignment: .leading, spacing: MITheme.Space.page) {
                        HStack {
                            Text("Engineering Claim").font(MITheme.Typography.pageTitle)
                            StatusBadge(title: selected.status.title, color: MITheme.statusColor(for: selected.status))
                            Spacer()
                            Button("Edit / Review") { editing = selected }
                            Button("Delete", role: .destructive) { confirmDeletion = true }
                        }
                        Panel {
                            VStack(alignment: .leading, spacing: MITheme.Space.regular) {
                                Text(selected.statement).font(MITheme.Typography.sectionTitle)
                                LabeledContent("Subject", value: (try? store.record(id: selected.subjectID))?.name ?? "Unknown")
                                LabeledContent("Source", value: (try? store.record(id: selected.sourceID))?.name ?? "Unknown")
                                LabeledContent("Page / section", value: selected.locator)
                                Text(selected.notes).foregroundStyle(.secondary)
                                RelatedKnowledgeButton(store: store, recordID: selected.subjectID, claimID: selected.id)
                            }
                        }
                    }.font(MITheme.Typography.body).frame(maxWidth: .infinity, alignment: .leading).padding(MITheme.pageInset)
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
            Text(error).foregroundStyle(MITheme.danger)
        }.padding(MITheme.Space.panel).frame(width: 560, height: 620)
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

struct RelationshipsPage: View {
    let store: KnowledgeStore
    @Binding var refresh: UUID
    @State private var adding = false
    @State private var selected: KnowledgeRelationship?
    @State private var confirmRemoval = false
    @State private var message = ""
    private var relationships: [KnowledgeRelationship] { (try? store.relationships()) ?? [] }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MITheme.Space.page) {
                PageHeader(title: "Relationships", subtitle: "Explicit links between stored records, with supporting evidence kept traceable.")
                if relationships.isEmpty {
                    ContentUnavailableView(
                        "No relationships yet",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        description: Text("Connect local records to make their context and supporting evidence easier to explore.")
                    )
                } else {
                    LazyVStack(alignment: .leading, spacing: MITheme.Space.compact) {
                        ForEach(relationships) { relationship in
                            let from = (try? store.record(id: relationship.fromID))?.name ?? "?"
                            let to = (try? store.record(id: relationship.toID))?.name ?? "?"
                            Panel {
                                Button {
                                    selected = relationship
                                } label: {
                                    HStack(spacing: MITheme.Space.compact) {
                                        Image(systemName: "arrow.left.arrow.right").foregroundStyle(MITheme.accent)
                                        Text("\(from) — \(relationship.predicate.replacingOccurrences(of: "_", with: " ")) — \(to)")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        if selected?.id == relationship.id { Image(systemName: "checkmark").foregroundStyle(MITheme.accent) }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .font(MITheme.Typography.body)
            .padding(MITheme.pageInset)
        }
        .accessibilityIdentifier("relationships.content")
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
        .background(MITheme.canvas)
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
            Text(error).foregroundStyle(MITheme.danger)
        }.padding(MITheme.Space.panel).frame(width: 480)
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
