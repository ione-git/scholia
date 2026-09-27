import Observation
import SwiftUI

@Observable
public final class ReaderController {
    public let book: ReaderBook
    public internal(set) var page: ReaderPage?
    public internal(set) var location: ReaderLocation?
    public internal(set) var pageSpan: ReaderPageSpan?
    public internal(set) var word: ReaderWord?
    public internal(set) var selection: ReaderSelection?
    var startPages: [Int]?
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
    @ObservationIgnored public var onHighlight: ((ReaderTextRange) -> Void)?
    @ObservationIgnored let viewController: ReaderViewController

    public init(
        book: ReaderBook, language: String?, location: ReaderLocation?, style: ReaderStyle, colors: ReaderColors,
        highlightColor: UIColor, pageTurn: ReaderPageTurn
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
            book: book, language: language, location: location, style: style, colors: colors, pageTurn: pageTurn)
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
        guard let startPages, startPages.indices.contains(index) else {
            return nil
        }
        return startPages[index]
    }

    public func highlightSelection() {
        viewController.highlightSelection()
    }

    public func translateSelection() {
        viewController.translateSelection()
    }

    public func copySelection() {
        viewController.copySelection()
    }

    public func clearSelection() {
        viewController.clearSelection()
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
