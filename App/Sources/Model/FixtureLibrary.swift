#if DEBUG
    import Foundation
    import SwiftData

    enum FixtureLibrary {
        static func seed(
            _ fixtures: [Fixture], opened: [Fixture], minutesRead: Int, into context: ModelContext, now: Date
        ) throws {
            var stored = Set(try context.fetch(FetchDescriptor<Book>()).map(\.fileName))
            for fixture in fixtures {
                guard let url = fixture.url, stored.insert(url.lastPathComponent).inserted else { continue }
                let book = Book(
                    fileName: url.lastPathComponent, title: fixture.title, author: fixture.author,
                    language: fixture.language, cover: nil, addedAt: now)
                try FileManager.default.createDirectory(at: Storage.booksDirectory, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: url, to: book.fileURL)
                context.insert(book)
            }
            let books = try context.fetch(FetchDescriptor<Book>())
            for (position, fixture) in opened.enumerated() {
                let book = books.first { $0.fileName == fixture.url?.lastPathComponent }
                book?.openedAt = now.addingTimeInterval(-Double(position) * openedInterval)
            }
            if minutesRead > 0 {
                context.insert(
                    ReadingSession(start: now.addingTimeInterval(-Double(minutesRead) * 60), end: now, pages: 0))
            }
            try context.save()
        }

        private static let openedInterval: TimeInterval = 60
    }

    extension Fixture {
        fileprivate var title: String {
            switch self {
            case .german: "Die Verwandlung"
            case .frenchNoCover: "Un matin en ville"
            case .arabic: "صباح في المدينة"
            case .minimalMetadata: "Minimal"
            case .corrupted: "Corrupted"
            case .drm: "Encrypted"
            }
        }

        fileprivate var author: String? {
            switch self {
            case .german, .drm: "Franz Kafka"
            case .frenchNoCover, .arabic: "Scholia"
            case .minimalMetadata, .corrupted: nil
            }
        }

        fileprivate var language: String {
            switch self {
            case .german, .drm: "de"
            case .frenchNoCover: "fr"
            case .arabic: "ar"
            case .minimalMetadata, .corrupted: "en"
            }
        }
    }
#endif
