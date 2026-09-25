import Foundation
import ReaderEngine
import UIKit

nonisolated struct ImportFailure: Error {
    let fileName: String
    let reason: EPUBMetadata.Failure
}

nonisolated struct PendingBook: Identifiable, Sendable {
    enum Source: Sendable {
        case files
        case otherApp
    }

    let id: UUID
    let file: URL
    let size: Int
    let source: Source
    let title: String
    let author: String?
    let language: String?
    let cover: Data?
    let coverImage: UIImage?

    @concurrent
    static func stage(_ url: URL, from source: Source) async throws(ImportFailure) -> PendingBook {
        let id = UUID()
        let file = URL.temporaryDirectory.appending(path: "\(id.uuidString).epub")
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try FileManager.default.copyItem(at: url, to: file)
        } catch {
            throw ImportFailure(fileName: url.lastPathComponent, reason: .unreadable)
        }
        if url.isInsideAppDocuments {
            try? FileManager.default.removeItem(at: url)
        }
        do throws(EPUBMetadata.Failure) {
            let metadata = try await EPUBMetadata.read(from: file)
            guard let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
                throw EPUBMetadata.Failure.unreadable
            }
            return PendingBook(
                id: id, file: file, size: size, source: source,
                title: metadata.title ?? url.deletingPathExtension().lastPathComponent, author: metadata.author,
                language: metadata.language.flatMap(BookLanguage.code(from:)), cover: metadata.cover,
                coverImage: metadata.cover.flatMap(UIImage.init(data:))?.preparingForDisplay())
        } catch {
            try? FileManager.default.removeItem(at: file)
            throw ImportFailure(fileName: url.lastPathComponent, reason: error)
        }
    }

    private var libraryFile: URL {
        Storage.booksDirectory.appending(path: file.lastPathComponent)
    }

    @concurrent
    func moveToLibrary() async throws -> String {
        try FileManager.default.createDirectory(at: Storage.booksDirectory, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: file, to: libraryFile)
        return libraryFile.lastPathComponent
    }

    @concurrent
    func moveOutOfLibrary() async {
        try? FileManager.default.moveItem(at: libraryFile, to: file)
    }

    @concurrent
    func discard() async {
        try? FileManager.default.removeItem(at: file)
    }
}

extension URL {
    nonisolated fileprivate var isInsideAppDocuments: Bool {
        resolvingSymlinksInPath().path(percentEncoded: false).hasPrefix(
            URL.documentsDirectory.resolvingSymlinksInPath().path(percentEncoded: false))
    }
}
