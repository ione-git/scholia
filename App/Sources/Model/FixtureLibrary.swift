#if DEBUG
    import Foundation
    import SwiftData

    enum FixtureLibrary {
        static func seed(_ fixtures: [Fixture], into context: ModelContext, addedAt: Date) throws {
            var stored = Set(try context.fetch(FetchDescriptor<Book>()).map(\.fileName))
            for fixture in fixtures {
                guard let url = fixture.url, stored.insert(url.lastPathComponent).inserted else { continue }
                let book = Book(
                    fileName: url.lastPathComponent, title: fixture.title, author: fixture.author,
                    language: fixture.language, cover: nil, addedAt: addedAt)
                try FileManager.default.createDirectory(at: Storage.booksDirectory, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: url, to: book.fileURL)
                context.insert(book)
            }
            try context.save()
        }
    }

    extension Fixture {
        fileprivate var title: String {
            switch self {
            case .german: "Die Verwandlung"
            case .frenchNoCover: "Un matin en ville"
            case .minimalMetadata: "Minimal"
            case .corrupted: "Corrupted"
            case .drm: "Encrypted"
            }
        }

        fileprivate var author: String? {
            switch self {
            case .german, .drm: "Franz Kafka"
            case .frenchNoCover: "Scholia"
            case .minimalMetadata, .corrupted: nil
            }
        }

        fileprivate var language: String {
            switch self {
            case .german, .drm: "de"
            case .frenchNoCover: "fr"
            case .minimalMetadata, .corrupted: "en"
            }
        }
    }
#endif
