import SwiftData

nonisolated enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Book.self, BookCollection.self, Highlight.self, Bookmark.self, ReadingSession.self, Settings.self]
    }
}

nonisolated enum ScholiaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

typealias Book = SchemaV1.Book
typealias BookCollection = SchemaV1.BookCollection
typealias Highlight = SchemaV1.Highlight
typealias Bookmark = SchemaV1.Bookmark
typealias ReadingSession = SchemaV1.ReadingSession
typealias Settings = SchemaV1.Settings
