import ReaderEngine
import SwiftData

@MainActor
extension Book {
    var bookmarksInReadingOrder: [Bookmark] {
        bookmarks.sorted { $0.position.location < $1.position.location }
    }

    func bookmarks(in span: ReaderPageSpan) -> [Bookmark] {
        bookmarks.filter { span.contains($0.position.location) }
    }

    func toggleBookmark(in span: ReaderPageSpan, context: ModelContext) {
        let marked = bookmarks(in: span)
        if marked.isEmpty {
            bookmarks.append(
                Bookmark(position: ReadingPosition(chapter: span.chapter, offset: span.start), text: span.firstLine))
        } else {
            marked.forEach(context.delete)
        }
        try? context.save()
    }
}
