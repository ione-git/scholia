#if DEBUG
    import Foundation
    import SwiftData

    enum FixtureLibrary {
        static func seed(
            _ fixtures: [Fixture], opened: [Fixture], inProgress: [Fixture], highlighted: [Fixture],
            into context: ModelContext, now: Date
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
            for fixture in inProgress {
                let book = books.first { $0.fileName == fixture.url?.lastPathComponent }
                book?.position = ReadingPosition(chapter: 1, offset: 0)
            }
            for fixture in highlighted {
                guard let book = books.first(where: { $0.fileName == fixture.url?.lastPathComponent }),
                    book.highlights.isEmpty
                else { continue }
                for highlight in fixture.highlights ?? placeholderHighlights(of: book) {
                    context.insert(highlight)
                    highlight.book = book
                }
            }
            try context.save()
        }

        private static func placeholderHighlights(of book: Book) -> [Highlight] {
            (0..<highlightCount).map { offset in
                let position = ReadingPosition(chapter: 1, offset: offset)
                return Highlight(
                    start: position, end: position, color: .yellow, text: book.title, before: "", after: "")
            }
        }

        private static let openedInterval: TimeInterval = 60
        private static let highlightCount = 7
    }

    extension Highlight {
        fileprivate convenience init(
            chapter: Int, offset: Int, text: String, before: String, after: String, color: HighlightColor
        ) {
            self.init(
                start: ReadingPosition(chapter: chapter, offset: offset),
                end: ReadingPosition(chapter: chapter, offset: offset + text.utf16.count), color: color, text: text,
                before: before, after: after)
        }
    }

    extension Fixture {
        fileprivate var highlights: [Highlight]? {
            switch self {
            case .german:
                [
                    Highlight(
                        chapter: 0, offset: 77,
                        text: "fand er sich in seinem Bett zu einem ungeheueren Ungeziefer verwandelt",
                        before: "aus unruhigen Träumen erwachte, ", after: ". Er lag auf seinem panzerartig ",
                        color: .yellow),
                    Highlight(
                        chapter: 0, offset: 410,
                        text:
                            "Seine vielen, im Vergleich zu seinem sonstigen Umfang kläglich dünnen Beine flimmerten ihm hilflos vor den Augen.",
                        before: "eit, kaum noch erhalten konnte. ", after: "\n»Was ist mit mir geschehen?«, d",
                        color: .green),
                    Highlight(
                        chapter: 0, offset: 565, text: "Es war kein Traum.", before: "mit mir geschehen?«, dachte er. ",
                        after: " Sein Zimmer, ein richtiges, nur", color: .yellow),
                    Highlight(
                        chapter: 1, offset: 719,
                        text:
                            "Sein Zimmer, ein richtiges, nur etwas zu kleines Menschenzimmer, lag ruhig zwischen den vier wohlbekannten Wänden.",
                        before: ", dachte er. Es war kein Traum. ", after: " Über dem Tisch, auf dem eine au",
                        color: .blue),
                    Highlight(
                        chapter: 1, offset: 1423, text: "machte ihn ganz melancholisch",
                        before: " das Fensterblech aufschlagen – ", after: ". »Wie wäre es, wenn ich noch ei",
                        color: .pink),
                    Highlight(
                        chapter: 2, offset: 150, text: "Er lag auf seinem panzerartig harten Rücken",
                        before: "eheueren Ungeziefer verwandelt. ", after: " und sah, wenn er den Kopf ein w",
                        color: .purple),
                    Highlight(
                        chapter: 2, offset: 525, text: "»Was ist mit mir geschehen?«, dachte er.",
                        before: "rten ihm hilflos vor den Augen.\n", after: " Es war kein Traum. Sein Zimmer,",
                        color: .green),
                ]
            case .frenchSections:
                [
                    Highlight(
                        chapter: 1, offset: 267, text: "Claire regarde tout cela depuis sa fenêtre.",
                        before: "ur un banc près de la fontaine.\n", after: " Elle tient une tasse de café en",
                        color: .yellow)
                ]
            case .frenchNoCover, .arabic, .minimalMetadata, .corrupted, .drm:
                nil
            }
        }

        fileprivate var title: String {
            switch self {
            case .german: "Die Verwandlung"
            case .frenchNoCover: "Un matin en ville"
            case .frenchSections: "Un soir en ville"
            case .arabic: "صباح في المدينة"
            case .minimalMetadata: "Minimal"
            case .corrupted: "Corrupted"
            case .drm: "Encrypted"
            }
        }

        fileprivate var author: String? {
            switch self {
            case .german, .drm: "Franz Kafka"
            case .frenchNoCover, .frenchSections, .arabic: "Scholia"
            case .minimalMetadata, .corrupted: nil
            }
        }

        fileprivate var language: String {
            switch self {
            case .german, .drm: "de"
            case .frenchNoCover, .frenchSections: "fr"
            case .arabic: "ar"
            case .minimalMetadata, .corrupted: "en"
            }
        }
    }
#endif
