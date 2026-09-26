import Foundation
import SwiftData

@Model
final class BookCollection {
    var name: String
    var createdAt: Date
    @Relationship(inverse: \Book.collections) var books: [Book]

    init(name: String, createdAt: Date) {
        self.name = name
        self.createdAt = createdAt
        books = []
    }

    static let order = [SortDescriptor(\BookCollection.createdAt), SortDescriptor(\BookCollection.name)]
}
