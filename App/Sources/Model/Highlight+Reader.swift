import ReaderEngine
import UIKit

extension Highlight {
    convenience init(range: ReaderTextRange, color: HighlightColor) {
        self.init(
            start: ReadingPosition(chapter: range.start.chapter, offset: range.start.offset),
            end: ReadingPosition(chapter: range.end.chapter, offset: range.end.offset),
            color: color, text: range.text, before: range.before, after: range.after)
    }

    var range: ReaderTextRange {
        ReaderTextRange(
            start: ReaderLocation(chapter: start.chapter, offset: start.offset),
            end: ReaderLocation(chapter: end.chapter, offset: end.offset),
            text: text, before: before, after: after)
    }

    func covers(_ range: ReaderTextRange) -> Bool {
        self.range.start == range.start && self.range.end == range.end
    }

    var key: String {
        "\(start.chapter):\(start.offset)-\(end.offset)"
    }

    func readerHighlight(color: UIColor) -> ReaderHighlight {
        ReaderHighlight(id: key, range: range, color: color)
    }

    static func isInBookOrder(_ lhs: Highlight, _ rhs: Highlight) -> Bool {
        (lhs.start.chapter, lhs.start.offset, lhs.end.offset) < (rhs.start.chapter, rhs.start.offset, rhs.end.offset)
    }
}
