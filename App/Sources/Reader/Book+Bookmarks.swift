import ReaderEngine
import SwiftData

@MainActor
extension Book {
    func bookmarks(in span: ReaderPageSpan) -> [Bookmark] {
        bookmarks.filter { span.contains(ReaderLocation(chapter: $0.position.chapter, offset: $0.position.offset)) }
    }

    func toggleBookmark(in span: ReaderPageSpan, context: ModelContext) {
        let marked = bookmarks(in: span)
        if marked.isEmpty {
            bookmarks.append(Bookmark(position: ReadingPosition(chapter: span.chapter, offset: span.start)))
        } else {
            marked.forEach(context.delete)
        }
        try? context.save()
    }
}
