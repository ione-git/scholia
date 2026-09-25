import Observation
import SwiftUI

@Observable
public final class ReaderController {
    public let book: ReaderBook
    public internal(set) var page: ReaderPage?
    public internal(set) var word: ReaderWord?
    public var colors: ReaderColors {
        didSet { viewController.apply(colors) }
    }
    public var highlights: [ReaderHighlight] {
        didSet { viewController.apply(highlights) }
    }
    public internal(set) var paintedHighlights: Int
    public var highlightColor: UIColor
    public var pageTurn: ReaderPageTurn {
        didSet { viewController.apply(pageTurn) }
    }
    @ObservationIgnored public var onPageTap: (() -> Void)?
    @ObservationIgnored let viewController: ReaderViewController

    public init(
        book: ReaderBook, style: ReaderStyle, colors: ReaderColors, highlightColor: UIColor, pageTurn: ReaderPageTurn,
        highlightTitle: String
    ) {
        self.book = book
        self.colors = colors
        self.highlightColor = highlightColor
        self.pageTurn = pageTurn
        highlights = []
        paintedHighlights = 0
        viewController = ReaderViewController(
            book: book, style: style, colors: colors, pageTurn: pageTurn, highlightTitle: highlightTitle)
        viewController.controller = self
    }
}

public struct ReaderView: UIViewControllerRepresentable {
    private let controller: ReaderController

    public init(controller: ReaderController) {
        self.controller = controller
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        controller.viewController
    }

    public func updateUIViewController(_ viewController: UIViewController, context: Context) {}
}
