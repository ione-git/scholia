import SwiftData

@Model
final class Bookmark {
    var position: ReadingPosition
    var book: Book?

    init(position: ReadingPosition) {
        self.position = position
    }
}
