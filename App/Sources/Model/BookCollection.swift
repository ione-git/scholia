import SwiftData

@Model
final class BookCollection {
    var name: String
    @Relationship(inverse: \Book.collections) var books: [Book]

    init(name: String) {
        self.name = name
        books = []
    }
}
