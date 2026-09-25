import UIKit

public struct ReaderStyle {
    public var font: ReaderTypeface
    public var fontSize: CGFloat
    public var lineHeight: CGFloat
    public var sideMargin: CGFloat
    public var topMargin: CGFloat
    public var minimumBottomMargin: CGFloat
    public var highlightRadius: CGFloat

    public init(
        font: ReaderTypeface, fontSize: CGFloat, lineHeight: CGFloat, sideMargin: CGFloat, topMargin: CGFloat,
        minimumBottomMargin: CGFloat, highlightRadius: CGFloat
    ) {
        self.font = font
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.sideMargin = sideMargin
        self.topMargin = topMargin
        self.minimumBottomMargin = minimumBottomMargin
        self.highlightRadius = highlightRadius
    }
}

public struct ReaderTypeface {
    public var family: String
    public var regular: URL
    public var italic: URL

    public init(family: String, regular: URL, italic: URL) {
        self.family = family
        self.regular = regular
        self.italic = italic
    }
}

public struct ReaderColors: Equatable {
    public var page: UIColor
    public var text: UIColor
    public var selection: UIColor

    public init(page: UIColor, text: UIColor, selection: UIColor) {
        self.page = page
        self.text = text
        self.selection = selection
    }
}

public enum ReaderPageTurn: String, CaseIterable, Sendable {
    case slide
    case curl
}
