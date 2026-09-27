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
    public private(set) var appearance: ReaderAppearance
    public var highlights: [ReaderHighlight] {
        didSet { viewController.apply(highlights) }
    }
    public internal(set) var paintedHighlights: Int
    public internal(set) var paintedWordTints: Int
    public var highlightColor: UIColor
    #if DEBUG
        public internal(set) var renderedStyle: ReaderRenderedStyle?
        public internal(set) var pageCurl: ReaderPageCurl
    #endif
    @ObservationIgnored public var onPageTap: (() -> Void)?
    @ObservationIgnored public var onHighlight: ((ReaderTextRange) -> Void)?
    @ObservationIgnored public var looksUpWords: Bool
    @ObservationIgnored let viewController: ReaderViewController

    public init(
        book: ReaderBook, language: String?, location: ReaderLocation?, appearance: ReaderAppearance,
        typefaces: [ReaderTypeface], highlightColor: UIColor
    ) {
        self.book = book
        self.location = location
        self.appearance = appearance
        self.highlightColor = highlightColor
        highlights = []
        paintedHighlights = 0
        paintedWordTints = 0
        #if DEBUG
            pageCurl = ReaderPageCurl(state: .off, completed: 0, cancelled: 0)
        #endif
        looksUpWords = true
        viewController = ReaderViewController(
            book: book, language: language, location: location, appearance: appearance, typefaces: typefaces)
        viewController.controller = self
    }

    public func clearWord() {
        viewController.clearWord()
    }

    public func apply(_ appearance: ReaderAppearance) async {
        await viewController.apply(appearance)
        self.appearance = viewController.appearance
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
