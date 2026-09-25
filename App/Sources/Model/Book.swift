import Foundation
import SwiftData

@Model
final class Book {
    var fileName: String
    var title: String
    var author: String?
    var language: String
    @Attribute(.externalStorage) var cover: Data?
    var addedAt: Date
    var openedAt: Date?
    var isFinished: Bool
    var position: ReadingPosition?
    var collections: [BookCollection]
    @Relationship(deleteRule: .cascade, inverse: \Highlight.book) var highlights: [Highlight]
    @Relationship(deleteRule: .cascade, inverse: \Bookmark.book) var bookmarks: [Bookmark]

    init(fileName: String, title: String, author: String?, language: String, cover: Data?, addedAt: Date) {
        self.fileName = fileName
        self.title = title
        self.author = author
        self.language = language
        self.cover = cover
        self.addedAt = addedAt
        openedAt = nil
        isFinished = false
        position = nil
        collections = []
        highlights = []
        bookmarks = []
    }

    var fileURL: URL {
        Storage.booksDirectory.appending(path: fileName)
    }
}
