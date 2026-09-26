import UIKit

public struct ReaderAppearance: Equatable, Sendable {
    public var style: ReaderStyle
    public var colors: ReaderColors
    public var pageTurn: ReaderPageTurn

    public init(style: ReaderStyle, colors: ReaderColors, pageTurn: ReaderPageTurn) {
        self.style = style
        self.colors = colors
        self.pageTurn = pageTurn
    }
}

public struct ReaderStyle: Equatable, Sendable {
    public var font: ReaderTypeface
    public var fontSize: CGFloat
    public var lineHeight: CGFloat
    public var paragraphIndent: CGFloat
    public var sideMargin: CGFloat
    public var topMargin: CGFloat
    public var minimumBottomMargin: CGFloat
    public var highlightRadius: CGFloat

    public init(
        font: ReaderTypeface, fontSize: CGFloat, lineHeight: CGFloat, paragraphIndent: CGFloat, sideMargin: CGFloat,
        topMargin: CGFloat, minimumBottomMargin: CGFloat, highlightRadius: CGFloat
    ) {
        self.font = font
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.paragraphIndent = paragraphIndent
        self.sideMargin = sideMargin
        self.topMargin = topMargin
        self.minimumBottomMargin = minimumBottomMargin
        self.highlightRadius = highlightRadius
    }
}

public enum ReaderTypeface: Hashable, Sendable {
    case bundled(family: String, regular: URL, italic: URL)
    case installed(family: String)

    public var family: String {
        switch self {
        case .bundled(let family, _, _), .installed(let family): family
        }
    }
}

public struct ReaderColors: Equatable, Sendable {
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
    case fade
    case scroll
}

#if DEBUG
    public struct ReaderRenderedStyle: Equatable, Sendable {
        public var background: String
        public var text: String
        public var fontFamily: String
        public var fontSize: Double
        public var lineHeight: Double
    }
#endif
