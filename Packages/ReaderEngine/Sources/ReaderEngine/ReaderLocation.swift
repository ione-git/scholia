import UIKit

public struct ReaderLocation: Codable, Hashable, Sendable {
    public var chapter: Int
    public var offset: Int

    public init(chapter: Int, offset: Int) {
        self.chapter = chapter
        self.offset = offset
    }
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
    public var offsetInSentence: Int
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
