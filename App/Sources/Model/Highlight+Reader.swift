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

    func readerHighlight(color: UIColor) -> ReaderHighlight {
        ReaderHighlight(id: "\(start.chapter):\(start.offset)-\(end.offset)", range: range, color: color)
    }
}
