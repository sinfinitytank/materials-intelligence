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
            HStack {
                Label("Research", systemImage: "doc.badge.plus").font(.title2.bold())
                Spacer()
                Button("Import JSON…", systemImage: "plus") { importer = true }.buttonStyle(.borderedProminent)
            }.padding()
            Divider()
            HStack(spacing: 0) {
                sidebar.frame(width: 220)
                Divider()
                if section == 5 { history }
                else if let selected { workspace(selected) }
                else { ContentUnavailableView("No research package", systemImage: "doc.badge.plus", description: Text("Import a structured JSON package to review it locally.")) }
            }
            if selected != nil && section != 5 { Divider(); bottomBar.padding() }
        }
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
        VStack(alignment: .leading, spacing: 5) {
            Text("PACKAGES").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(sessions.filter { $0.status == "staged" }) { session in
                Button { selectedID = session.id; section = 0 } label: {
                    VStack(alignment: .leading) { Text(session.package.topic).lineLimit(2); Text(session.package.boundary).font(.caption2).foregroundStyle(.secondary) }
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain).padding(7).background(selectedID == session.id ? Color.accentColor.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 7))
            }
            Divider().padding(.vertical, 6)
            ForEach(Array(["Overview", "Entities", "Claims", "Relationships", "Sources", "History"].enumerated()), id: \.offset) { index, title in
                Button(title) { section = index }.buttonStyle(.plain).frame(maxWidth: .infinity, alignment: .leading)
                    .padding(7).background(section == index ? Color.accentColor.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 7))
            }
            Spacer()
            Label("Local staging · no network", systemImage: "internaldrive").font(.caption).foregroundStyle(.secondary)
        }.padding(12).background(Color(nsColor: .underPageBackgroundColor))
    }

    private func workspace(_ session: ResearchSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(session.package.topic).font(.largeTitle.bold())
                        Text("Package \(session.package.packageID) · \(session.package.boundary) · \(session.status.capitalized)")
                            .foregroundStyle(.secondary).textSelection(.enabled)
                    }
                    Spacer()
                    Button("Export original…") { exportOriginal(session) }
                }
                if let failure = session.lastError { Label(failure, systemImage: "exclamationmark.triangle").foregroundStyle(.red).textSelection(.enabled) }
                if section == 0 {
                    Text(session.package.summary ?? "No summary supplied.")
                    Text("\(session.package.entities.count) entities · \(session.package.claims.count) claims · \(session.package.relationships.count) relationships")
                    Text("Each dependency requires its own Accept or Reuse decision. Imported claims stay Unverified until reviewed in Claims.")
                        .foregroundStyle(.secondary)
                    Button("Review entities") { section = 1 }.buttonStyle(.borderedProminent)
                } else {
                    Text(["", "Proposed entities", "Proposed claims", "Proposed relationships", "Proposed sources"][section]).font(.title2.bold())
                    ForEach(visibleItems) { item in proposal(item, session: session) }
                    if visibleItems.isEmpty { Text("No proposals in this section.").foregroundStyle(.secondary) }
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
        }
    }

    private func proposal(_ item: ProposalItem, session: ResearchSession) -> some View {
        let review = session.reviews[item.id] ?? ResearchReview()
        let matches = (try? store.researchMatches(session.package, itemID: item.id)) ?? []
        return VStack(alignment: .leading, spacing: 10) {
            HStack { Text("\(item.type.uppercased()) · \(item.id)").font(.caption.bold()).foregroundStyle(.secondary); Spacer(); Text(review.decision.rawValue.capitalized).font(.caption.bold()) }
            Text(item.title).font(.headline).textSelection(.enabled)
            if !item.detail.isEmpty { Text(item.detail).font(.callout).foregroundStyle(.secondary).textSelection(.enabled) }
            if let target = review.targetID { Text("Reuses existing ID: \(target)").font(.caption).textSelection(.enabled) }
            if let result = session.results[item.id] { Text("Committed ID: \(result)").font(.caption).textSelection(.enabled) }
            ForEach(matches) { match in
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
                    VStack(alignment: .leading) { Text(match.title).font(.callout.bold()); Text(match.reason).font(.caption); Text("Existing ID: \(match.id)").font(.caption2).textSelection(.enabled) }
                    Spacer()
                    if staged && match.canMerge { Button("Reuse") { decide(item.id, .merge, target: match.id) }.buttonStyle(.bordered) }
                }.padding(8).background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
            }
            if staged {
                HStack {
                    Button("Accept") { decide(item.id, .accept) }.buttonStyle(.borderedProminent)
                    Button("Edit JSON…") { startEditing(item.id, session: session) }.buttonStyle(.bordered)
                    Button("Reject") { decide(item.id, .reject) }.buttonStyle(.bordered)
                    Button("Reset") { decide(item.id, .pending) }.buttonStyle(.bordered)
                }
            }
        }.padding(15).frame(maxWidth: .infinity, alignment: .leading).background(.background, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
    }

    private var history: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Import history").font(.largeTitle.bold())
                ForEach(sessions) { session in
                    Button { selectedID = session.id; section = 0 } label: {
                        HStack { VStack(alignment: .leading) { Text(session.package.topic).font(.headline); Text("\(session.package.packageID) · \(session.importedAt) · \(session.results.count) result IDs").font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(session.status.capitalized) }
                            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain).background(.background, in: RoundedRectangle(cornerRadius: 8))
                }
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var bottomBar: some View {
        HStack {
            Text("\(approved) approved · \(selected?.package.boundary ?? "")").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button("Cancel import") { cancelAlert = true }.disabled(!staged)
            Button("Commit approved changes") { commitAlert = true }.buttonStyle(.borderedProminent).disabled(!staged || approved == 0)
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit package JSON").font(.title2.bold())
            Text("Editing proposal \(editItemID). Save validates the whole package and resets all decisions because dependencies may have changed.")
                .foregroundStyle(.secondary)
            TextEditor(text: $editedJSON).font(.system(.body, design: .monospaced)).frame(minWidth: 650, minHeight: 430)
            HStack { Spacer(); Button("Cancel") { editing = false }; Button("Save changes") {
                perform { _ = try store.editResearch(requireSelected(), data: Data(editedJSON.utf8)); reload(); editing = false }
            }.buttonStyle(.borderedProminent) }
        }.padding(20)
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
