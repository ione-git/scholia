#if DEBUG
    import Foundation
    import SwiftData

    enum FixtureLibrary {
        static func seed(
            _ fixtures: [Fixture], opened: [Fixture], inProgress: [Fixture], highlighted: [Fixture],
            collections: [FixtureCollection], into context: ModelContext, now: Date
        ) throws {
            var stored = Set(try context.fetch(FetchDescriptor<Book>()).map(\.fileName))
            for fixture in fixtures {
                guard let url = fixture.url, stored.insert(url.lastPathComponent).inserted else { continue }
                let book = Book(
                    fileName: url.lastPathComponent, title: fixture.title, author: fixture.author,
                    language: fixture.language, cover: try fixture.coverURL.map { try Data(contentsOf: $0) },
                    addedAt: now)
                try FileManager.default.createDirectory(at: Storage.booksDirectory, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: url, to: book.fileURL)
                context.insert(book)
            }
            let books = try context.fetch(FetchDescriptor<Book>())
            for (position, fixture) in opened.enumerated() {
                let book = books.first { $0.fileName == fixture.url?.lastPathComponent }
                book?.openedAt = now.addingTimeInterval(-Double(position) * openedInterval)
            }
            for fixture in inProgress {
                let book = books.first { $0.fileName == fixture.url?.lastPathComponent }
                book?.position = ReadingPosition(chapter: 1, offset: 0)
            }
            for fixture in highlighted {
                guard let book = books.first(where: { $0.fileName == fixture.url?.lastPathComponent }),
                    book.highlights.isEmpty
                else { continue }
                for offset in 0..<highlightCount {
                    let position = ReadingPosition(chapter: 1, offset: offset)
                    let highlight = Highlight(
                        start: position, end: position, color: .yellow, text: book.title, before: "", after: "")
                    context.insert(highlight)
                    highlight.book = book
                }
            }
            let storedCollections = try context.fetch(FetchDescriptor<BookCollection>())
            for (index, fixtureCollection) in collections.enumerated() {
                let collection: BookCollection
                if let stored = storedCollections.first(where: { $0.name == fixtureCollection.name }) {
                    collection = stored
                } else {
                    collection = BookCollection(
                        name: fixtureCollection.name,
                        createdAt: now.addingTimeInterval(-Double(collections.count - index) * collectionInterval))
                    context.insert(collection)
                }
                for fixture in fixtureCollection.books {
                    guard let book = books.first(where: { $0.fileName == fixture.url?.lastPathComponent }),
                        !collection.books.contains(book)
                    else { continue }
                    collection.books.append(book)
                }
            }
            try context.save()
        }

        private static let openedInterval: TimeInterval = 60
        private static let collectionInterval: TimeInterval = 60
        private static let highlightCount = 7
    }

    extension Fixture {
        fileprivate var coverURL: URL? {
            Bundle.main.url(forResource: "\(rawValue)-cover", withExtension: "png", subdirectory: "Fixtures")
        }

        fileprivate var title: String {
            switch self {
            case .german: "Die Verwandlung"
            case .frenchNoCover: "Un matin en ville"
            case .arabic: "صباح في المدينة"
            case .minimalMetadata: "Minimal"
            case .corrupted: "Corrupted"
            case .drm: "Encrypted"
            case .zip64: "ZIP64"
            case .fontObfuscation: "Obfuscated Font"
            }
        }

        fileprivate var author: String? {
            switch self {
            case .german, .drm, .zip64, .fontObfuscation: "Franz Kafka"
            case .frenchNoCover, .arabic: "Scholia"
            case .minimalMetadata, .corrupted: nil
            }
        }

        fileprivate var language: String {
            switch self {
            case .german, .drm, .zip64, .fontObfuscation: "de"
            case .frenchNoCover: "fr"
            case .arabic: "ar"
            case .minimalMetadata, .corrupted: "en"
            }
        }
    }
#endif
