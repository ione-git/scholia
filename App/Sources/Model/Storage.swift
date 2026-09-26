import Foundation
import SwiftData

enum Storage {
    nonisolated static let booksDirectory = URL.applicationSupportDirectory.appending(
        path: "Books", directoryHint: .isDirectory)

    static func makeContainer(_ configuration: LaunchConfiguration) throws -> ModelContainer {
        let store = ModelConfiguration()
        #if DEBUG
            if configuration.unreadableStore {
                try FileManager.default.createDirectory(
                    at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data("unreadable".utf8).write(to: store.url)
            }
        #endif
        if configuration.resetsState {
            for url in files(of: store) + [booksDirectory]
            where FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: url)
            }
        }
        let container = try ModelContainer(
            for: Schema(versionedSchema: SchemaV1.self), migrationPlan: ScholiaMigrationPlan.self,
            configurations: store)
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

    private static func files(of store: ModelConfiguration) -> [URL] {
        let path = store.url.path(percentEncoded: false)
        let name = store.url.deletingPathExtension().lastPathComponent
        return [
            store.url, URL(filePath: path + "-wal"), URL(filePath: path + "-shm"),
            store.url.deletingLastPathComponent().appending(path: ".\(name)_SUPPORT", directoryHint: .isDirectory),
        ]
    }
}
