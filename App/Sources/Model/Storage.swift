import Foundation
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
        }
        let container = try ModelContainer(for: schema)
        #if DEBUG
            try FixtureLibrary.seed(
                configuration.fixtures, into: container.mainContext, addedAt: configuration.now ?? .now)
        #endif
        return container
    }
}
