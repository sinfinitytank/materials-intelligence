import SwiftUI

struct GraphPage: View {
    let store: KnowledgeStore
    var initialID: String? = nil
    var claimID: String? = nil
    var openResult: ((SearchResult) -> Void)? = nil
    @State private var graph: KnowledgeGraph?
    @State private var root = ""
    @State private var comparison = ""
    @State private var depth = 2
    @State private var history: [String] = []
    @State private var error = ""
    private var records: [KnowledgeRecord] { graph?.records.values.sorted { ($0.name, $0.id) < ($1.name, $1.id) } ?? [] }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MITheme.Space.panel) {
                PageHeader(title: "Knowledge Explorer", subtitle: "Stored relationships, evidence paths, and structured comparison")
                if !error.isEmpty { Text(error).foregroundStyle(MITheme.danger) }
                if let graph {
                    HStack {
                        Picker("Start", selection: $root) { Text("Select record").tag(""); ForEach(records) { Text($0.name).tag($0.id) } }
                        Stepper("\(depth) hops", value: $depth, in: 1...6)
                        Button("Back") { if let prior = history.popLast() { root = prior } }.disabled(history.isEmpty)
                    }
                    if let claimID, let claim = graph.claims[claimID] {
                        Panel { VStack(alignment: .leading, spacing: MITheme.Space.compact) { Text("Why? Starting claim").font(MITheme.Typography.sectionTitle); evidence(claim, graph: graph); Text("Follow only recorded context below. Missing mechanism or metallurgy links are not inferred.").foregroundStyle(.secondary) } }
                    }
                    if let record = graph.records[root] {
                        Panel { VStack(alignment: .leading, spacing: MITheme.Space.compact) { Text(record.name).font(MITheme.Typography.pageTitle); Text(record.detail); recordButton(record); Text("Related records · shortest paths").font(MITheme.Typography.sectionTitle)
                            let traversal = graph.traverse(from: root, depth: depth)
                            if traversal.paths.isEmpty { Text("No recorded relationships at this depth.").foregroundStyle(.secondary) }
                            ForEach(traversal.paths) { path in
                                DisclosureGroup {
                                    ForEach(path.edges) { edge in
                                        VStack(alignment: .leading, spacing: MITheme.Space.tight) {
                                            Text("\(graph.records[edge.from]?.name ?? edge.from) → \(edge.predicate) → \(graph.records[edge.to]?.name ?? edge.to)")
                                            Text(edge.derived ? "Derived from a stored claim's source reference" : "Stored relationship · \(edge.id)").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
                                            if let id = edge.claimID, let claim = graph.claims[id] { evidence(claim, graph: graph) }
                                            else { Text("No supporting claim recorded; relationship is not verified evidence.").foregroundStyle(MITheme.caution) }
                                        }.padding(.vertical, MITheme.Space.compact)
                                    }
                                } label: {
                                    HStack { Text(path.recordIDs.compactMap { graph.records[$0]?.name }.joined(separator: " → ")); Spacer(); Button("Explore") { history.append(root); root = path.id } }
                                }
                            }
                            if traversal.truncated { Text("Traversal bounded by depth or 100 records. Explore a related record to continue.").font(MITheme.Typography.metadata).foregroundStyle(MITheme.caution) }
                        } }
                        Panel { VStack(alignment: .leading, spacing: MITheme.Space.regular) {
                            Text("Compare stored knowledge").font(MITheme.Typography.sectionTitle)
                            Picker("Compare with", selection: $comparison) { Text("Select record").tag(""); ForEach(records.filter { $0.kind == record.kind && $0.id != root }) { Text($0.name).tag($0.id) } }
                            if !comparison.isEmpty {
                                HStack(alignment: .top, spacing: MITheme.Space.page) {
                                    ForEach(graph.compare([root, comparison]), id: \.record.id) { column in
                                        VStack(alignment: .leading, spacing: MITheme.Space.compact) {
                                            Text(column.record.name).font(MITheme.Typography.sectionTitle); Text(column.record.secondary); Text(column.record.detail)
                                            Text("Claims / properties").font(MITheme.Typography.sectionTitle)
                                            if column.claims.isEmpty { Text("No claims recorded") }
                                            ForEach(column.claims) { claim in Text(claim.predicate).font(MITheme.Typography.supporting.weight(.semibold)); evidence(claim, graph: graph) }
                                            Text("Direct standards").font(MITheme.Typography.sectionTitle)
                                            ForEach(column.standards) { recordButton($0) }
                                            Text("\(column.links.count) relationships · \(column.sources.count) sources").font(MITheme.Typography.metadata)
                                        }.frame(maxWidth: .infinity, alignment: .topLeading)
                                    }
                                }
                                Text("Missing fields are unknown, not equivalent. Narrative properties are shown verbatim; no numeric normalization or suitability ranking.").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
                            }
                        } }
                    }
                }
            }.padding(MITheme.pageInset)
        }.background(MITheme.canvas).task { reload() }
    }
    @ViewBuilder private func recordButton(_ record: KnowledgeRecord) -> some View {
        if let openResult { Button("Open \(record.name)") { openResult(SearchResult(id: record.id, entityType: .record, title: record.name, detail: record.detail, kind: record.kind.rawValue, score: 0)) } }
        else { Button(record.name) { history.append(root); root = record.id } }
    }
    private func evidence(_ claim: EngineeringClaim, graph: KnowledgeGraph) -> some View {
        VStack(alignment: .leading, spacing: MITheme.Space.tight) {
            Text(claim.statement); Text("\(claim.status.title) · \(claim.evidenceLevel) · \(claim.conditions)").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
            if let source = graph.records[claim.sourceID] { recordButton(source) }
            Text("\(claim.locator) · Claim \(claim.id)").font(MITheme.Typography.metadata).textSelection(.enabled)
            if let openResult { Button("Open claim") { openResult(SearchResult(id: claim.id, entityType: .claim, title: claim.statement, detail: "", kind: "", score: 0)) } }
        }
    }
    private func reload() { do { let snapshot = try KnowledgeGraph(store: store); graph = snapshot; root = initialID ?? claimID.flatMap { snapshot.claims[$0]?.subjectID } ?? records.first?.id ?? "" } catch { self.error = error.localizedDescription } }
}

struct RelatedKnowledgeButton: View {
    let store: KnowledgeStore
    let recordID: String
    var claimID: String? = nil
    @State private var showing = false
    var body: some View { Button(claimID == nil ? "Explore related knowledge / Compare" : "Why? Explore evidence path") { showing = true }.sheet(isPresented: $showing) { VStack { HStack { Spacer(); Button("Done") { showing = false } }.padding(MITheme.Space.panel); GraphPage(store: store, initialID: recordID, claimID: claimID) }.frame(minWidth: 800, minHeight: 600) } }
}
