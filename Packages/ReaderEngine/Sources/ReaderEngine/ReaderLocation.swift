import UIKit

public struct ReaderLocation: Codable, Hashable, Sendable {
    public var chapter: Int
    public var offset: Int

    public init(chapter: Int, offset: Int) {
        self.chapter = chapter
        self.offset = offset
    }
}

extension ReaderLocation: Comparable {
    public static func < (lhs: ReaderLocation, rhs: ReaderLocation) -> Bool {
        (lhs.chapter, lhs.offset) < (rhs.chapter, rhs.offset)
    }
}

public struct ReaderPageSpan: Equatable, Sendable {
    public var chapter: Int
    public var start: Int
    public var end: Int

    public func contains(_ location: ReaderLocation) -> Bool {
        location.chapter == chapter && start <= location.offset
            && (location.offset < end || location.offset == start)
    }
}

public struct ReaderChapter: Equatable, Sendable {
    public var title: String
    public var location: ReaderLocation
}

public struct ReaderTextRange: Codable, Hashable, Sendable {
    public var chapter: String
    public var text: String
    public var before: String
    public var after: String

    public init(chapter: String, text: String, before: String, after: String) {
        self.chapter = chapter
        self.text = text
        self.before = before
        self.after = after
    }
}

public struct ReaderPage: Equatable, Sendable {
    public var chapter: Int
    public var number: Int
    public var count: Int
}

public struct ReaderWord: Equatable, Sendable {
    public var text: String
    public var sentence: String
    public var rect: CGRect
    public var range: ReaderTextRange
}

public struct ReaderHighlight: Identifiable, Equatable {
    public var id: String
    public var range: ReaderTextRange
    public var color: UIColor

    public init(id: String, range: ReaderTextRange, color: UIColor) {
        self.id = id
        self.range = range
        self.color = color
    }
}
