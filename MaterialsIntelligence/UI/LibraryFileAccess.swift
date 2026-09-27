import Foundation

struct ResolvedLibraryFile {
    let url: URL
    let bookmarkWasStale: Bool
    var isReadable: Bool { FileManager.default.isReadableFile(atPath: url.path) }
}

enum LibraryFileAccessError: LocalizedError {
    case unusableBookmark
    case unreadableFile

    var errorDescription: String? {
        switch self {
        case .unusableBookmark: "No usable file reference is stored. Use Locate file to reconnect it."
        case .unreadableFile: "The selected file is not readable."
        }
    }
}

enum LibraryFileAccess {
    static func makeBookmark(for url: URL) throws -> String {
        try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil).base64EncodedString()
    }

    static func resolve(_ bookmark: String) throws -> ResolvedLibraryFile {
        guard let data = Data(base64Encoded: bookmark), !data.isEmpty else { throw LibraryFileAccessError.unusableBookmark }
        var stale = false
        let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale)
        return ResolvedLibraryFile(url: url, bookmarkWasStale: stale)
    }

    static func relink(_ document: LibraryDocument, to url: URL) throws -> LibraryDocument {
        guard FileManager.default.isReadableFile(atPath: url.path) else { throw LibraryFileAccessError.unreadableFile }
        var updated = document
        updated.bookmark = try makeBookmark(for: url)
        updated.fileName = url.lastPathComponent
        return updated
    }
}
