import Foundation

@main struct LibraryIntegrationTests {
    static func check(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        guard try condition() else { throw KnowledgeStoreError(message: "Library integration test failed: " + message) }
    }

    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "library-acceptance-\(UUID())", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let databaseURL = directory.appending(path: "knowledge.sqlite")
        let originalURL = directory.appending(path: "synthetic-source.pdf")
        let movedURL = directory.appending(path: "relocated", directoryHint: .isDirectory).appending(path: "synthetic-source.pdf")
        try FileManager.default.createDirectory(at: movedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let pdfContent = Data("%PDF-1.4\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\n".utf8)
        try pdfContent.write(to: originalURL)

        let material = KnowledgeRecord(id: "library-fixture-material", kind: .material, name: "Synthetic library material")
        let initial = LibraryDocument(
            id: "library-fixture-document",
            title: "LibraryFixtureSearchToken synthetic PDF",
            organization: "Synthetic Test Publisher",
            revisionYear: "2025",
            sourceType: "Test fixture",
            notes: "Generated only for automated Library acceptance.",
            fileName: originalURL.lastPathComponent,
            bookmark: try LibraryFileAccess.makeBookmark(for: originalURL),
            addedAt: ""
        )

        do {
            let store = try KnowledgeStore(url: databaseURL)
            try store.save(material)
            try store.save(initial, recordIDs: [material.id])
        }

        var store = try KnowledgeStore(url: databaseURL)
        var document = try store.documents().first { $0.id == initial.id }!
        try check(document.id == initial.id && document.title == initial.title && document.organization == initial.organization && document.revisionYear == initial.revisionYear && document.sourceType == initial.sourceType && document.notes == initial.notes && document.fileName == initial.fileName && document.bookmark == initial.bookmark && !document.addedAt.isEmpty, "document metadata, generated date and bookmark survive repository re-open")
        let originalAddedAt = document.addedAt
        try check(try store.recordIDs(documentID: document.id) == [material.id], "document association survives repository re-open")
        try check(try store.search("LibraryFixtureSearchToken").contains { $0.id == document.id }, "document metadata remains searchable")

        let originalReference = try LibraryFileAccess.resolve(document.bookmark)
        try check(!originalReference.bookmarkWasStale && originalReference.url.standardizedFileURL == originalURL.standardizedFileURL && originalReference.isReadable, "security-scoped bookmark resolves to readable original file")

        try FileManager.default.removeItem(at: originalURL)
        try pdfContent.write(to: movedURL)
        let oldBookmarkIsReadable: Bool
        do { oldBookmarkIsReadable = try LibraryFileAccess.resolve(document.bookmark).isReadable }
        catch { oldBookmarkIsReadable = false }
        try check(!oldBookmarkIsReadable, "moved file is detected as unavailable through the previous bookmark")
        try check(try store.documents().first { $0.id == document.id }?.title == document.title, "missing file does not remove Library metadata")
        try check(try store.recordIDs(documentID: document.id) == [material.id], "missing file does not remove knowledge association")

        document = try LibraryFileAccess.relink(document, to: movedURL)
        try store.save(document, recordIDs: try store.recordIDs(documentID: document.id))
        store = try KnowledgeStore(url: databaseURL)
        let reopened = try store.documents().first { $0.id == document.id }!
        let movedReference = try LibraryFileAccess.resolve(reopened.bookmark)
        try check(reopened.id == initial.id && reopened.addedAt == originalAddedAt && reopened.fileName == movedURL.lastPathComponent, "relink preserves document identity and original added date")
        try check(movedReference.url.standardizedFileURL == movedURL.standardizedFileURL && movedReference.isReadable, "relinked bookmark resolves after repository re-open")
        try check(try store.recordIDs(documentID: reopened.id) == [material.id] && store.search("LibraryFixtureSearchToken").contains { $0.id == reopened.id }, "relink retains association and indexed metadata")

        try store.deleteDocument(id: reopened.id)
        try check(try store.documents().isEmpty && store.search("LibraryFixtureSearchToken").isEmpty, "document removal clears metadata index")
        try check(try store.record(id: material.id) != nil && store.foreignKeyViolations() == 0, "document removal leaves referenced engineering records intact")
        print("Library integration tests passed: bookmark resolve, missing/moved file, relink, persistence, FTS and deletion")
    }
}
