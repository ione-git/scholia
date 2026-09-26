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
                .accessibilityValue(Text(verbatim: files))
        }

        private var files: String {
            let directory = Storage.booksDirectory.path(percentEncoded: false)
            let names = (try? FileManager.default.contentsOfDirectory(atPath: directory)) ?? []
            return names.sorted().joined(separator: "\n")
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
