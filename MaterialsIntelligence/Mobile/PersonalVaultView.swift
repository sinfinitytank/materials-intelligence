import SwiftUI

struct PersonalVaultLauncher: View {
    @State private var store: KnowledgeStore?
    @State private var error = ""

    var body: some View {
        Group {
            if let store {
                PersonalVaultView(store: store)
            } else if !error.isEmpty {
                ContentUnavailableView("Personal vault unavailable", systemImage: "externaldrive.badge.exclamationmark", description: Text(error))
            } else {
                ProgressView("Opening personal vault")
            }
        }
        .task {
            do { store = try PersonalSync.openStore() }
            catch { self.error = error.localizedDescription }
        }
    }
}

private enum VaultTab: String, CaseIterable, Hashable, Identifiable {
    case reference, ask, sync, research, claims, relationships

    var id: String { rawValue }

    static var available: Set<VaultTab> {
        #if os(macOS)
        Set(allCases)
        #else
        [.reference, .ask, .sync]
        #endif
    }
}

struct PersonalVaultView: View {
    let store: KnowledgeStore
    @StateObject private var sync: PersonalSync
    @State private var selectedTab: VaultTab = .reference
    @State private var refresh = UUID()
    @State private var targetID: String?

    init(store: KnowledgeStore) {
        self.store = store
        _sync = StateObject(wrappedValue: PersonalSync(store: store))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PersonalVaultReferenceTab(store: store)
                .tabItem { Label("Reference", systemImage: "books.vertical").accessibilityIdentifier("personalVault.tab.reference") }
                .tag(VaultTab.reference)

            PersonalVaultAskTab(store: store)
                .tabItem { Label("Ask", systemImage: "questionmark.bubble").accessibilityIdentifier("personalVault.tab.ask") }
                .tag(VaultTab.ask)

            PersonalVaultSyncTab(store: store, sync: sync)
                .tabItem { Label("Sync", systemImage: "arrow.triangle.2.circlepath").accessibilityIdentifier("personalVault.tab.sync") }
                .tag(VaultTab.sync)

            #if os(macOS)
            ResearchPage(store: store)
                .accessibilityIdentifier("personalVault.research.content")
                .tabItem { Label("Research review", systemImage: "doc.badge.plus").accessibilityIdentifier("personalVault.tab.research") }
                .tag(VaultTab.research)

            ClaimsPage(store: store, refresh: $refresh, targetID: $targetID)
                .accessibilityIdentifier("personalVault.claims.content")
                .tabItem { Label("Claims", systemImage: "checkmark.seal").accessibilityIdentifier("personalVault.tab.claims") }
                .tag(VaultTab.claims)

            RelationshipsPage(store: store, refresh: $refresh)
                .accessibilityIdentifier("personalVault.relationships.content")
                .tabItem { Label("Relationships", systemImage: "link").accessibilityIdentifier("personalVault.tab.relationships") }
                .tag(VaultTab.relationships)
            #endif
        }
        .accessibilityIdentifier("personalVault.tabs")
        .onChange(of: selectedTab) { _, newValue in
            if !VaultTab.available.contains(newValue) { selectedTab = .reference }
        }
    }
}

private struct PersonalVaultReferenceTab: View {
    let store: KnowledgeStore
#if !os(macOS)
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
#endif
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var records: [KnowledgeRecord] = []
    @State private var selectedResult: SearchResult?
    @State private var adding = false
    @State private var name = ""
    @State private var kind: RecordKind = .material
    @State private var message = ""

    var body: some View {
        Group {
#if os(macOS)
        HStack(spacing: 0) {
            referenceSidebar.frame(minWidth: 220, idealWidth: 250, maxWidth: 290)
            Divider()
            referenceDetail.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Knowledge")
#else
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            referenceList
        } detail: {
            referenceDetail
        }
#endif
        }
        .task { reload() }
        .sheet(isPresented: $adding) {
            NavigationStack {
                Form {
                    Section("New reference") {
                        Picker("Kind", selection: $kind) {
                            ForEach(RecordKind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        TextField("Name", text: $name).accessibilityIdentifier("personalVault.reference.name")
                        if !message.isEmpty { Text(message).foregroundStyle(.red) }
                    }
                    HStack {
                        Button("Cancel") { adding = false; message = "" }.accessibilityIdentifier("personalVault.reference.cancel")
                        Spacer()
                        Button("Save reference", action: save).buttonStyle(.borderedProminent)
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityIdentifier("personalVault.reference.save")
                    }
                }.padding().navigationTitle("Add reference")
            }.frame(minWidth: 340, minHeight: 270)
        }
    }

    private var referenceList: some View {
        List {
            Section("PERSONAL / PUBLIC VAULT") {
                Text("This separate vault is for explicitly permitted knowledge. Keep restricted work in the Mac local vault.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            if query.isEmpty {
                if records.isEmpty {
                    ContentUnavailableView("No references yet", systemImage: "books.vertical", description: Text("Add a local reference to begin."))
                }
                ForEach(records) { record in
                    Button {
                        select(SearchResult(id: record.id, entityType: .record, title: record.name, detail: record.detail, kind: record.kind.rawValue, score: 0))
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.name).font(.system(size: 12, weight: .medium))
                            Text(record.kind.rawValue.capitalized + (record.secondary.isEmpty ? "" : " · \(record.secondary)"))
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain)
                }
            } else {
                if results.isEmpty {
                    ContentUnavailableView("No local matches", systemImage: "magnifyingglass")
                }
                ForEach(results) { result in
                    Button {
                        select(result)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(result.title).font(.system(size: 12, weight: .medium))
                            Text("\(result.entityType.title) · \(result.kind)").font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain)
                }
            }
        }
        .searchable(text: $query, prompt: "Search this vault")
        .onChange(of: query) { _, _ in reload() }
        .navigationTitle("Knowledge")
    }

    private var referenceSidebar: some View {
#if os(macOS)
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button("Add reference", systemImage: "plus") { adding = true }
                    .accessibilityIdentifier("personalVault.reference.add")
                Button("Refresh", systemImage: "arrow.clockwise", action: reload)
                    .accessibilityIdentifier("personalVault.reference.refresh")
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            Divider()
            referenceList
        }
#else
        referenceList.toolbar {
            Button("Add reference", systemImage: "plus") { adding = true }.accessibilityIdentifier("personalVault.reference.add")
            Button("Refresh", systemImage: "arrow.clockwise", action: reload).accessibilityIdentifier("personalVault.reference.refresh")
        }
#endif
    }

    private var referenceDetail: some View {
        NavigationStack {
            if let selectedResult {
                PortableSearchDetail(store: store, result: selectedResult).id(selectedResult.id)
            } else {
                ContentUnavailableView("Select a reference", systemImage: "books.vertical", description: Text("Stored records, claims and sources appear here."))
            }
        }
    }

    private func select(_ result: SearchResult) {
        selectedResult = result
#if !os(macOS)
        compactColumn = .detail
#endif
    }

    private func reload() {
        do {
            records = try store.records()
            results = query.isEmpty ? [] : try store.search(query)
            message = ""
        } catch { message = error.localizedDescription }
    }

    private func save() {
        do {
            try store.save(KnowledgeRecord(kind: kind, name: name.trimmingCharacters(in: .whitespacesAndNewlines)))
            name = ""
            adding = false
            reload()
        } catch { message = error.localizedDescription }
    }
}

private struct PersonalVaultAskTab: View {
    let store: KnowledgeStore
    @State private var question = ""
    @State private var answer: LocalAnswer?
    @State private var message = ""
    @State private var loading = false
    @State private var request: Task<Void, Never>?
    private let provider = AppleLocalProvider()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VaultPageHeader(title: "Ask", subtitle: "Search this vault and use on-device generation only when available.")
                    VaultPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("LOCAL · on-device only", systemImage: "desktopcomputer")
                                .font(.system(size: 10, weight: .semibold)).foregroundStyle(VaultTheme.accent)
                            if let unavailable = provider.availabilityMessage {
                                Label(unavailable, systemImage: "cpu").font(.system(size: 11)).foregroundStyle(.orange)
                            }
                            TextField("Ask about stored evidence", text: $question, axis: .vertical)
                                .lineLimit(2...4).accessibilityIdentifier("personalVault.ask.question")
                            HStack {
                                Spacer()
                                Button("Ask locally", systemImage: "arrow.up.right", action: submit)
                                    .buttonStyle(.borderedProminent).disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || loading)
                                    .accessibilityIdentifier("personalVault.ask.submit")
                            }
                        }
                    }
                    if loading { ProgressView("Retrieving stored evidence…") }
                    if !message.isEmpty {
                        VaultPanel { Label(message, systemImage: "exclamationmark.triangle").font(.system(size: 11)).foregroundStyle(.orange) }
                    }
                    if let answer {
                        if let text = answer.message {
                            VaultPanel { Text(text).font(.system(size: 12)).foregroundStyle(.secondary) }
                        }
                        if !answer.points.isEmpty {
                            VaultPanel {
                                VStack(alignment: .leading, spacing: 11) {
                                    VaultSectionTitle(title: "Generated explanation · unverified", icon: "text.bubble")
                                    ForEach(answer.points) { point in
                                        VStack(alignment: .leading, spacing: 7) {
                                            Text(point.text).font(.system(size: 12))
                                            ForEach(point.evidence) { item in
                                                NavigationLink("Claim · \(item.claim.status.title) · \(item.subject.name)") {
                                                    PortableClaimView(store: store, claim: item.claim)
                                                }.font(.system(size: 11))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if !answer.found.isEmpty {
                            VaultPanel {
                                VStack(alignment: .leading, spacing: 10) {
                                    VaultSectionTitle(title: "Retrieved evidence", icon: "checkmark.seal")
                                    ForEach(answer.found) { item in
                                        NavigationLink("\(item.claim.statement) · \(item.claim.status.title)") {
                                            PortableClaimView(store: store, claim: item.claim)
                                        }.font(.system(size: 11))
                                    }
                                }
                            }
                        }
                    }
                    Text("Generated explanations remain separate from reviewed knowledge. Check each cited claim against its source.")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }.padding(22).frame(maxWidth: 860, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(VaultTheme.canvas)
            .navigationTitle("Ask")
            .accessibilityIdentifier("personalVault.ask.content")
            .onDisappear { request?.cancel(); request = nil; loading = false }
        }
    }

    private func submit() {
        request?.cancel()
        let submitted = question.trimmingCharacters(in: .whitespacesAndNewlines)
        answer = nil
        message = ""
        loading = true
        request = Task { @MainActor in
            defer { loading = false }
            do {
                let value = try await LocalRAG(store: store, provider: provider).ask(submitted)
                try Task.checkCancellation()
                answer = value
            } catch is CancellationError {
                // Leaving Ask cancels this transient request without changing the vault.
            } catch {
                if !Task.isCancelled { message = error.localizedDescription }
            }
        }
    }
}

private struct PersonalVaultSyncTab: View {
    let store: KnowledgeStore
    @ObservedObject var sync: PersonalSync
    @State private var consent = false
    @State private var confirmRemote = false
    @State private var confirmLocal = false
    @State private var confirmRecovery = false
    @State private var message = ""

    private var statusColor: Color {
        if sync.pending || sync.status.hasPrefix("Sync paused:") || sync.status.hasPrefix("Conflict retained:") { return .orange }
        if sync.status == "Up to date" || sync.status == "Synchronized personal/public vault" { return .green }
        return .secondary
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    VaultPageHeader(title: "Private Sync", subtitle: "An explicit, review-first connection for the separate personal/public vault.")
                    VaultPanel {
                        VStack(alignment: .leading, spacing: 11) {
                            HStack(spacing: 8) {
                                Circle().fill(statusColor).frame(width: 7, height: 7)
                                Text(sync.status).font(.system(size: 12, weight: .semibold)).accessibilityIdentifier("personalVault.sync.status")
                            }
                            Divider()
                            LabeledContent("Local vault", value: "\((try? store.records().count) ?? 0) records · \((try? store.claims().count) ?? 0) claims")
                            LabeledContent("Last successful sync", value: sync.lastSuccessfulSync)
                            LabeledContent("Cloud state", value: sync.pending ? "Incoming snapshot needs review" : "Checked only when you sync")
                            Toggle("I permit this vault to use my private iCloud", isOn: $consent)
                                .accessibilityIdentifier("personalVault.sync.consent")
                            HStack(spacing: 10) {
                                Button("Sync now", systemImage: "arrow.triangle.2.circlepath") {
                                    Task { await sync.synchronize(consent: consent) }
                                }
                                .buttonStyle(.borderedProminent).disabled(!consent || sync.busy)
                                .accessibilityIdentifier("personalVault.sync.start")
                                if sync.busy { ProgressView().controlSize(.small) }
                            }
                            Text("Sync never starts from navigation. Incoming changes require review; file contents and bookmarks stay on this device.")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }
                    if sync.pending {
                        VaultPanel {
                            VStack(alignment: .leading, spacing: 11) {
                                VaultSectionTitle(title: "Review incoming snapshot", icon: "arrow.down.doc")
                                Text(sync.review).font(.system(size: 10, design: .monospaced)).textSelection(.enabled)
                                HStack {
                                    Button("Apply remote to this vault", role: .destructive) { confirmRemote = true }
                                        .disabled(!consent || sync.busy).accessibilityIdentifier("personalVault.sync.applyRemote")
                                    Button("Keep local and update cloud") { confirmLocal = true }
                                        .disabled(!consent || sync.busy).accessibilityIdentifier("personalVault.sync.keepLocal")
                                }
                            }
                        }
                    }
                    VaultPanel {
                        VStack(alignment: .leading, spacing: 9) {
                            VaultSectionTitle(title: "Recovery", icon: "clock.arrow.circlepath")
                            Text("A pre-resolution snapshot is retained locally when a reviewed replacement is applied.")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                            Button("Restore saved recovery snapshot", systemImage: "arrow.uturn.backward") { confirmRecovery = true }
                                .disabled(sync.busy).accessibilityIdentifier("personalVault.sync.restoreRecovery")
                        }
                    }
                    if !message.isEmpty {
                        VaultPanel { Label(message, systemImage: "exclamationmark.triangle").font(.system(size: 11)).foregroundStyle(.orange) }
                    }
                }.padding(22).frame(maxWidth: 900, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(VaultTheme.canvas)
            .navigationTitle("Sync")
            .accessibilityIdentifier("personalVault.sync.content")
            .confirmationDialog("Replace this local vault with the reviewed cloud snapshot? The current state will be saved for recovery.", isPresented: $confirmRemote) {
                Button("Apply reviewed cloud snapshot", role: .destructive) {
                    do { try sync.useRemote() } catch { message = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Replace the remote snapshot with this local vault? Other devices will review the change.", isPresented: $confirmLocal) {
                Button("Keep local snapshot", role: .destructive) { Task { await sync.keepLocal() } }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Restore the saved recovery snapshot locally? Current content becomes the next recovery point.", isPresented: $confirmRecovery) {
                Button("Restore recovery snapshot", role: .destructive) {
                    do { try sync.restoreRecovery() } catch { message = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

private enum VaultTheme {
    static let accent = Color(red: 0.13, green: 0.38, blue: 0.45)
    static let canvas = Color.primary.opacity(0.025)
}

private struct VaultPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content().padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.primary.opacity(0.085), lineWidth: 0.7))
    }
}

private struct VaultPageHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 25, weight: .semibold))
            Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
}

private struct VaultSectionTitle: View {
    let title: String
    let icon: String
    var body: some View { Label(title, systemImage: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(VaultTheme.accent) }
}

struct PortableSearchDetail: View {
    let store: KnowledgeStore
    let result: SearchResult
    var body: some View {
        if result.entityType == .record, let record = try? store.record(id: result.id) {
            PortableRecordView(store: store, record: record)
        } else if result.entityType == .claim, let claim = try? store.claim(id: result.id) {
            PortableClaimView(store: store, claim: claim)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.title).font(.system(size: 22, weight: .semibold))
                    Text(result.detail).foregroundStyle(.secondary)
                    Text("Document metadata only; the file remains on its originating device.").font(.system(size: 11)).foregroundStyle(.secondary)
                }.padding(22)
            }
        }
    }
}

struct PortableRecordView: View {
    let store: KnowledgeStore
    let record: KnowledgeRecord
    @State private var notes = ""
    @State private var message = ""
    var body: some View {
        Form {
            Section("Reference") {
                Text(record.secondary)
                TextField("Notes", text: $notes, axis: .vertical)
                Button("Save lightweight update") {
                    do { var updated = record; updated.detail = notes; try store.save(updated); message = "Saved locally" }
                    catch { message = error.localizedDescription }
                }
                Text(message)
            }
            Section("Claims and evidence") {
                ForEach((try? store.claims(subjectID: record.id)) ?? []) { claim in
                    NavigationLink(claim.statement) { PortableClaimView(store: store, claim: claim) }
                }
            }
            Section("Related records") {
                ForEach((try? store.relationships(recordID: record.id)) ?? []) { edge in
                    let id = edge.fromID == record.id ? edge.toID : edge.fromID
                    if let other = try? store.record(id: id) { NavigationLink("\(edge.predicate) · \(other.name)") { PortableRecordView(store: store, record: other) } }
                }
            }
        }.navigationTitle(record.name).task { notes = record.detail }
    }
}

struct PortableClaimView: View {
    let store: KnowledgeStore
    let claim: EngineeringClaim
    var body: some View {
        Form {
            Text(claim.statement)
            LabeledContent("State", value: claim.status.title)
            Text(claim.conditions)
            Text(claim.evidenceLevel)
            Text(claim.locator)
            Text(claim.notes)
            if let source = try? store.record(id: claim.sourceID) { NavigationLink("Source: \(source.name)") { PortableRecordView(store: store, record: source) } }
            Text("Review evidence here; claim approval remains a Mac authoring action.").font(.caption)
        }.navigationTitle("Evidence")
    }
}
