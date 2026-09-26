import Observation
import SwiftUI

@Observable
public final class ReaderController {
    public let book: ReaderBook
    public internal(set) var page: ReaderPage?
    public internal(set) var location: ReaderLocation?
    public internal(set) var pageSpan: ReaderPageSpan?
    public internal(set) var word: ReaderWord?
    public private(set) var appearance: ReaderAppearance
    public var highlights: [ReaderHighlight] {
        didSet { viewController.apply(highlights) }
    }
    public internal(set) var paintedHighlights: Int
    public var highlightColor: UIColor
    #if DEBUG
        public internal(set) var renderedStyle: ReaderRenderedStyle?
    #endif
    @ObservationIgnored public var onPageTap: (() -> Void)?
    @ObservationIgnored public var looksUpWords: Bool
    @ObservationIgnored let viewController: ReaderViewController

    public init(
        book: ReaderBook, location: ReaderLocation?, appearance: ReaderAppearance, typefaces: [ReaderTypeface],
        highlightColor: UIColor, highlightTitle: String
    ) {
        self.book = book
        self.location = location
        self.appearance = appearance
        self.highlightColor = highlightColor
        highlights = []
        paintedHighlights = 0
        looksUpWords = true
        viewController = ReaderViewController(
            book: book, location: location, appearance: appearance, typefaces: typefaces,
            highlightTitle: highlightTitle)
        viewController.controller = self
    }

    public func apply(_ appearance: ReaderAppearance) async {
        await viewController.apply(appearance)
        self.appearance = viewController.appearance
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
