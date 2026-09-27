import Observation
import SwiftUI

@Observable
public final class ReaderController {
    public let book: ReaderBook
    public internal(set) var page: ReaderPage?
    public internal(set) var location: ReaderLocation?
    public internal(set) var pageSpan: ReaderPageSpan?
    public internal(set) var word: ReaderWord?
    var filePages: [FilePages]?
    public var colors: ReaderColors {
        didSet { viewController.apply(colors) }
    }
    public var highlights: [ReaderHighlight] {
        didSet { viewController.apply(highlights) }
    }
    public internal(set) var paintedHighlights: Int
    public internal(set) var paintedWordTints: Int
    public var highlightColor: UIColor
    public var pageTurn: ReaderPageTurn {
        didSet { viewController.apply(pageTurn) }
    }
    @ObservationIgnored public var onPageTap: (() -> Void)?
    @ObservationIgnored let viewController: ReaderViewController

    public init(
        book: ReaderBook, language: String?, location: ReaderLocation?, style: ReaderStyle, colors: ReaderColors,
        highlightColor: UIColor, pageTurn: ReaderPageTurn, highlightTitle: String
    ) {
        self.book = book
        self.location = location
        self.colors = colors
        self.highlightColor = highlightColor
        self.pageTurn = pageTurn
        highlights = []
        paintedHighlights = 0
        paintedWordTints = 0
        viewController = ReaderViewController(
            book: book, language: language, location: location, style: style, colors: colors, pageTurn: pageTurn,
            highlightTitle: highlightTitle)
        viewController.controller = self
    }

    public func clearWord() {
        viewController.clearWord()
    }

    public func go(to location: ReaderLocation) {
        viewController.go(to: .location(location))
    }

    public func go(toChapterAt index: Int) {
        viewController.go(to: .chapter(index))
    }

    public func startPage(ofChapterAt index: Int) -> Int? {
        guard book.tableOfContents.indices.contains(index) else {
            return nil
        }
        return page(at: book.tableOfContents[index].location)
    }

    public func page(at location: ReaderLocation) -> Int? {
        guard let filePages, filePages.indices.contains(location.chapter) else {
            return nil
        }
        return filePages[location.chapter].page(at: location.offset)
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
