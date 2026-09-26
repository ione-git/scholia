import Observation
import SwiftUI

@Observable
public final class ReaderController {
    public let book: ReaderBook
    public internal(set) var page: ReaderPage?
    public internal(set) var location: ReaderLocation?
    public internal(set) var pageSpan: ReaderPageSpan?
    public internal(set) var word: ReaderWord?
    var startPages: [Int]?
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
        book: ReaderBook, location: ReaderLocation?, style: ReaderStyle, colors: ReaderColors, highlightColor: UIColor,
        pageTurn: ReaderPageTurn, highlightTitle: String
    ) {
        self.book = book
        self.location = location
        self.colors = colors
        self.highlightColor = highlightColor
        self.pageTurn = pageTurn
        highlights = []
        paintedHighlights = 0
        viewController = ReaderViewController(
            book: book, location: location, style: style, colors: colors, pageTurn: pageTurn,
            highlightTitle: highlightTitle)
        viewController.controller = self
    }

    public func go(to location: ReaderLocation) {
        viewController.go(to: .location(location))
    }

    public func go(toChapterAt index: Int) {
        viewController.go(to: .chapter(index))
    }

    public func startPage(of chapter: ReaderChapter) -> Int? {
        guard
            chapter.unresolvedFragment == nil, chapter.location.offset == 0, let startPages,
            startPages.indices.contains(chapter.location.chapter)
        else {
            return nil
        }
        return startPages[chapter.location.chapter]
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
