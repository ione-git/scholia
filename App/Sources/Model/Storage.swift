import Foundation
import ReaderEngine
import SwiftData

enum Storage {
    nonisolated static let booksDirectory = URL.applicationSupportDirectory.appending(
        path: "Books", directoryHint: .isDirectory)

    static func makeContainer(_ configuration: LaunchConfiguration) throws -> ModelContainer {
        let schema = Schema([
            Book.self, BookCollection.self, Highlight.self, Bookmark.self, ReadingSession.self, Settings.self,
        ])
        if configuration.resetsState {
            try ModelContainer(for: schema).erase()
            if FileManager.default.fileExists(atPath: booksDirectory.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: booksDirectory)
            }
            try PageCountCache.removeAll()
        }
        let container = try ModelContainer(for: schema)
        #if DEBUG
            try FixtureLibrary.seed(
                configuration.fixtures, opened: configuration.opened, inProgress: configuration.inProgress,
                into: container.mainContext, now: configuration.now ?? .now)
        #endif
        return container
    }

    @concurrent
    nonisolated static func removeFiles(at urls: [URL]) async {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }

    @concurrent
    nonisolated static func fileSize(at url: URL) async -> Int? {
        try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
    }

    static func settings(in context: ModelContext) throws -> Settings {
        if let settings = try context.fetch(FetchDescriptor<Settings>()).first {
            return settings
        }
        let settings = Settings.makeDefault()
        context.insert(settings)
        try context.save()
        return settings
    }
}
