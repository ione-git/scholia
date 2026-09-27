import Foundation
import SwiftData

extension SchemaV1 {
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
    }
}

extension BookCollection {
    static let order = [SortDescriptor(\BookCollection.createdAt), SortDescriptor(\BookCollection.name)]
}
