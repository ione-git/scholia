import Foundation

extension LibrarySort {
    var title: LocalizedStringResource {
        switch self {
        case .recentlyOpened: "Recently opened"
        case .recentlyAdded: "Recently added"
        case .title: "Title"
        case .author: "Author"
        }
    }

    var shortTitle: LocalizedStringResource {
        switch self {
        case .recentlyOpened: "Recent"
        case .recentlyAdded: "Added"
        case .title: "Title"
        case .author: "Author"
        }
    }

    func sorted(_ books: [Book]) -> [Book] {
        books.sorted { order($0, $1) == .orderedAscending }
    }

    private func order(_ first: Book, _ second: Book) -> ComparisonResult {
        let byTitle = first.title.localizedStandardCompare(second.title)
        let byAuthor = missingLast(first.author, second.author) { $0.localizedStandardCompare($1) }
        let byAdded = second.addedAt.compare(first.addedAt)
        let orders: [ComparisonResult] =
            switch self {
            case .recentlyOpened: [missingLast(first.openedAt, second.openedAt) { $1.compare($0) }, byAdded, byTitle]
            case .recentlyAdded: [byAdded, byTitle]
            case .title: [byTitle, byAuthor]
            case .author: [byAuthor, byTitle]
            }
        return orders.first { $0 != .orderedSame } ?? .orderedSame
    }

    private func missingLast<Value>(
        _ first: Value?, _ second: Value?, _ compare: (Value, Value) -> ComparisonResult
    ) -> ComparisonResult {
        switch (first, second) {
        case (let first?, let second?): compare(first, second)
        case (nil, nil): .orderedSame
        case (nil, _): .orderedDescending
        case (_, nil): .orderedAscending
        }
    }
}

extension Book {
    func matches(_ query: String) -> Bool {
        title.localizedStandardContains(query) || author?.localizedStandardContains(query) == true
    }
}
