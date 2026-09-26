import Foundation
import OSLog
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
                configuration.fixtures, opened: configuration.opened, into: container.mainContext,
                now: configuration.now ?? .now)
        #endif
        return container
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

extension Logger {
    static let storage = Logger(subsystem: "com.ione.scholia", category: "storage")
}

extension ModelContext {
    func saveLogged() {
        do {
            try save()
        } catch {
            Logger.storage.error("Saving failed: \(String(describing: error), privacy: .public)")
        }
    }
}

@MainActor
extension Settings {
    func update<Value: Equatable>(
        _ keyPath: ReferenceWritableKeyPath<Settings, Value>, to value: Value, in context: ModelContext
    ) {
        guard self[keyPath: keyPath] != value else {
            return
        }
        self[keyPath: keyPath] = value
        context.saveLogged()
    }
}
