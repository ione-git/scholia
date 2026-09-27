import SwiftData

@Model
final class Bookmark {
    var position: ReadingPosition
    var text: String?
    var book: Book?

    init(position: ReadingPosition, text: String?) {
        self.position = position
        self.text = text
    }
}
