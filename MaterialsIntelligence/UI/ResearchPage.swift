import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ResearchPage: View {
    let store: KnowledgeStore
    @State private var sessions: [ResearchSession] = []
    @State private var selectedID: String?
    @State private var section = 0
    @State private var importer = false
    @State private var commitAlert = false
    @State private var cancelAlert = false
    @State private var errorMessage: String?
    @State private var editing = false
    @State private var editedJSON = ""
    @State private var editItemID = ""

    private var selected: ResearchSession? { sessions.first { $0.id == selectedID } }
    private var staged: Bool { selected?.status == "staged" }
    private var approved: Int { selected?.reviews.values.filter { $0.decision == .accept || $0.decision == .merge }.count ?? 0 }
    private var visibleItems: [ProposalItem] {
        guard let p = selected?.package else { return [] }
        let entities = p.entities.filter { (section == 1 && $0.kind != "source") || (section == 4 && $0.kind == "source") }.map {
            ProposalItem(id: $0.id, type: $0.kind.capitalized, title: $0.name,
                         detail: [$0.secondary, $0.detail, $0.source?.organization, $0.source?.revisionYear, $0.source?.url].compactMap { $0 }.joined(separator: " · "))
        }
        let claims = section == 2 ? p.claims.map {
            ProposalItem(id: $0.id, type: "Claim", title: $0.statement,
                         detail: "Subject: \($0.subjectID) · \($0.predicate) · Source: \($0.sourceID)" +
                         [$0.conditions, $0.locator, $0.notes].compactMap { $0 }.map { " · \($0)" }.joined())
        } : []
        let relationships = section == 3 ? p.relationships.map {
            ProposalItem(id: $0.id, type: "Relationship", title: "\($0.fromID) → \($0.predicate) → \($0.toID)",
                         detail: $0.supportingClaimID.map { "Supporting claim: \($0)" } ?? "No supporting claim")
        } : []
        return entities + claims + relationships
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: MITheme.Space.panel) {
                PageHeader(title: "Research", subtitle: "Review structured engineering proposals before they enter local knowledge.")
                Spacer()
                Button("Import JSON…", systemImage: "plus") { importer = true }.buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, MITheme.Space.inset)
            .padding(.vertical, MITheme.Space.panel)
            Divider()
            HStack(spacing: 0) {
                sidebar.frame(width: 230)
                Divider()
                if section == 5 { history }
                else if let selected { workspace(selected) }
                else { ContentUnavailableView("No research package", systemImage: "doc.badge.plus", description: Text("Import a structured JSON package to review it locally.")) }
            }
            if selected != nil && section != 5 {
                Divider()
                bottomBar.padding(.horizontal, MITheme.Space.inset).padding(.vertical, MITheme.Space.regular)
            }
        }
        .background(MITheme.canvas)
        .task { reload() }
        .fileImporter(isPresented: $importer, allowedContentTypes: [.json]) { importPackage($0) }
        .alert("Research error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .alert("Commit approved changes?", isPresented: $commitAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Commit") { perform { _ = try store.commitResearch(requireSelected()); reload(); section = 5 } }
        } message: { Text("Only accepted or explicitly reused items will be committed. New claims remain Unverified.") }
        .alert("Cancel this import?", isPresented: $cancelAlert) {
            Button("Keep reviewing", role: .cancel) {}
            Button("Cancel import", role: .destructive) { perform { _ = try store.cancelResearch(requireSelected()); reload() } }
        } message: { Text("The staged package will close without changing permanent knowledge. Its history remains available.") }
        .sheet(isPresented: $editing) { editor }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: MITheme.Space.compact) {
            Text("PACKAGES").font(MITheme.Typography.metadata.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(sessions.filter { $0.status == "staged" }) { session in
                Button { selectedID = session.id; section = 0 } label: {
                    VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(session.package.topic).font(MITheme.Typography.supporting.weight(.medium)).lineLimit(2); Text(session.package.boundary).font(MITheme.Typography.metadata).foregroundStyle(.secondary) }
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain).padding(MITheme.Space.compact).background(selectedID == session.id ? MITheme.selected : .clear, in: RoundedRectangle(cornerRadius: MITheme.Radius.selection, style: .continuous))
            }
            Divider().padding(.vertical, MITheme.Space.compact)
            ForEach(Array(["Overview", "Entities", "Claims", "Relationships", "Sources", "History"].enumerated()), id: \.offset) { index, title in
                Button(title) { section = index }.buttonStyle(.plain).frame(maxWidth: .infinity, alignment: .leading)
                    .font(MITheme.Typography.supporting)
                    .padding(MITheme.Space.compact).background(section == index ? MITheme.selected : .clear, in: RoundedRectangle(cornerRadius: MITheme.Radius.selection, style: .continuous))
            }
            Spacer()
            Label("Local staging · no network", systemImage: "internaldrive").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
        }.padding(MITheme.Space.regular).background(MITheme.sidebar)
    }

    private func workspace(_ session: ResearchSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MITheme.Space.page) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(session.package.topic).font(MITheme.Typography.pageTitle)
                        Text("Package \(session.package.packageID) · \(session.package.boundary) · \(session.status.capitalized)")
                            .font(MITheme.Typography.supporting).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                    Spacer()
                    Button("Export original…") { exportOriginal(session) }
                }
                if let failure = session.lastError { Label(failure, systemImage: "exclamationmark.triangle").foregroundStyle(MITheme.danger).textSelection(.enabled) }
                if section == 0 {
                    Text(session.package.summary ?? "No summary supplied.")
                    Text("\(session.package.entities.count) entities · \(session.package.claims.count) claims · \(session.package.relationships.count) relationships")
                    Text("Each dependency requires its own Accept or Reuse decision. Imported claims stay Unverified until reviewed in Claims.")
                        .foregroundStyle(.secondary)
                    Button("Review entities") { section = 1 }.buttonStyle(.borderedProminent)
                } else {
                    Text(["", "Proposed entities", "Proposed claims", "Proposed relationships", "Proposed sources"][section]).font(MITheme.Typography.sectionTitle)
                    ForEach(visibleItems) { item in proposal(item, session: session) }
                    if visibleItems.isEmpty { Text("No proposals in this section.").foregroundStyle(.secondary) }
                }
            }.font(MITheme.Typography.body).frame(maxWidth: .infinity, alignment: .leading).padding(MITheme.Space.inset)
        }
    }

    private func proposal(_ item: ProposalItem, session: ResearchSession) -> some View {
        let review = session.reviews[item.id] ?? ResearchReview()
        let matches = (try? store.researchMatches(session.package, itemID: item.id)) ?? []
        return Panel {
            VStack(alignment: .leading, spacing: MITheme.Space.regular) {
            HStack { Text("\(item.type.uppercased()) · \(item.id)").font(MITheme.Typography.metadata.weight(.semibold)).foregroundStyle(.secondary); Spacer(); Text(review.decision.rawValue.capitalized).font(MITheme.Typography.metadata.weight(.semibold)).foregroundStyle(MITheme.accent) }
            Text(item.title).font(MITheme.Typography.sectionTitle).textSelection(.enabled)
            if !item.detail.isEmpty { Text(item.detail).font(MITheme.Typography.supporting).foregroundStyle(.secondary).textSelection(.enabled) }
            if let target = review.targetID { Text("Reuses existing ID: \(target)").font(MITheme.Typography.metadata).textSelection(.enabled) }
            if let result = session.results[item.id] { Text("Committed ID: \(result)").font(MITheme.Typography.metadata).textSelection(.enabled) }
            ForEach(matches) { match in
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(MITheme.caution)
                    VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(match.title).font(MITheme.Typography.supporting.weight(.semibold)); Text(match.reason).font(MITheme.Typography.metadata); Text("Existing ID: \(match.id)").font(MITheme.Typography.metadata).textSelection(.enabled) }
                    Spacer()
                    if staged && match.canMerge { Button("Reuse") { decide(item.id, .merge, target: match.id) }.buttonStyle(.bordered) }
                }.padding(MITheme.Space.compact).background(MITheme.caution.opacity(0.08), in: RoundedRectangle(cornerRadius: MITheme.Radius.control, style: .continuous))
            }
            if staged {
                HStack {
                    Button("Accept") { decide(item.id, .accept) }.buttonStyle(.borderedProminent)
                    Button("Edit JSON…") { startEditing(item.id, session: session) }.buttonStyle(.bordered)
                    Button("Reject") { decide(item.id, .reject) }.buttonStyle(.bordered)
                    Button("Reset") { decide(item.id, .pending) }.buttonStyle(.bordered)
                }
            }
            }
        }
    }

    private var history: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MITheme.Space.regular) {
                Text("Import history").font(MITheme.Typography.pageTitle)
                ForEach(sessions) { session in
                    Button { selectedID = session.id; section = 0 } label: {
                        HStack { VStack(alignment: .leading, spacing: MITheme.Space.tight) { Text(session.package.topic).font(MITheme.Typography.sectionTitle); Text("\(session.package.packageID) · \(session.importedAt) · \(session.results.count) result IDs").font(MITheme.Typography.metadata).foregroundStyle(.secondary) }; Spacer(); Text(session.status.capitalized).font(MITheme.Typography.metadata.weight(.semibold)) }
                            .padding(MITheme.Space.regular).frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain).background(MITheme.surface, in: RoundedRectangle(cornerRadius: MITheme.Radius.panel, style: .continuous)).overlay(RoundedRectangle(cornerRadius: MITheme.Radius.panel, style: .continuous).stroke(MITheme.separator, lineWidth: 0.7))
                }
            }.padding(MITheme.Space.inset).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var bottomBar: some View {
        HStack {
            Text("\(approved) approved · \(selected?.package.boundary ?? "")").font(MITheme.Typography.metadata).foregroundStyle(.secondary)
            Spacer()
            Button("Cancel import") { cancelAlert = true }.disabled(!staged)
            Button("Commit approved changes") { commitAlert = true }.buttonStyle(.borderedProminent).disabled(!staged || approved == 0)
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: MITheme.Space.regular) {
            Text("Edit package JSON").font(MITheme.Typography.pageTitle)
            Text("Editing proposal \(editItemID). Save validates the whole package and resets all decisions because dependencies may have changed.")
                .foregroundStyle(.secondary)
            TextEditor(text: $editedJSON).font(.system(.body, design: .monospaced)).frame(minWidth: 650, minHeight: 430)
            HStack { Spacer(); Button("Cancel") { editing = false }; Button("Save changes") {
                perform { _ = try store.editResearch(requireSelected(), data: Data(editedJSON.utf8)); reload(); editing = false }
            }.buttonStyle(.borderedProminent) }
        }.font(MITheme.Typography.body).padding(MITheme.Space.inset)
    }

    private func requireSelected() throws -> ResearchSession {
        guard let selected else { throw KnowledgeStoreError(message: "Select a research package first.") }
        return selected
    }
    private func perform(_ work: () throws -> Void) { do { try work() } catch { errorMessage = error.localizedDescription; reload() } }
    private func reload() {
        do { sessions = try store.researchSessions(); if !sessions.contains(where: { $0.id == selectedID }) { selectedID = sessions.first?.id } }
        catch { errorMessage = error.localizedDescription }
    }
    private func importPackage(_ result: Result<URL, Error>) {
        perform {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let session = try store.importResearch(Data(contentsOf: url))
            reload(); selectedID = session.id; section = 0
        }
    }
    private func decide(_ id: String, _ decision: ResearchDecision, target: String? = nil) {
        perform { _ = try store.decideResearch(requireSelected(), itemID: id, decision: decision, targetID: target); reload() }
    }
    private func startEditing(_ id: String, session: ResearchSession) {
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            editedJSON = String(decoding: try encoder.encode(session.package), as: UTF8.self)
            editItemID = id; editing = true
        } catch { errorMessage = error.localizedDescription }
    }
    private func exportOriginal(_ session: ResearchSession) {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "\(session.package.packageID).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        perform { try Data(session.originalJSON.utf8).write(to: url, options: .atomic) }
    }
}

private struct ProposalItem: Identifiable {
    let id: String
    let type: String
    let title: String
    let detail: String
}
