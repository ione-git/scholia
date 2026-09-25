import SwiftData

nonisolated enum HighlightColor: String, Codable {
    case yellow
    case green
    case blue
    case pink
    case purple
}

@Model
final class Highlight {
    var start: ReadingPosition
    var end: ReadingPosition
    var color: HighlightColor
    var text: String
    var book: Book?

    init(start: ReadingPosition, end: ReadingPosition, color: HighlightColor, text: String) {
        self.start = start
        self.end = end
        self.color = color
        self.text = text
    }
}
