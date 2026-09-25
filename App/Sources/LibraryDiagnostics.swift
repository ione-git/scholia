#if DEBUG
    import SwiftData
    import SwiftUI

    struct LibraryDiagnostics: View {
        @Query(sort: \Book.title) private var books: [Book]

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.storedLibrary")
                .accessibilityLabel(Text(verbatim: summary))
        }

        private var summary: String {
            books.map { book in
                let file =
                    FileManager.default.fileExists(atPath: book.fileURL.path(percentEncoded: false))
                    ? book.fileName : "no file"
                return [book.title, book.author ?? "no author", book.language, file].joined(separator: " · ")
            }
            .joined(separator: "\n")
        }
    }
#endif
