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
    var pageStarts: [[Int]]?
    public internal(set) var tappedHighlight: ReaderTappedHighlight?
    public var highlights: [ReaderHighlight] {
        didSet { viewController.apply(highlights) }
    }
    public internal(set) var paintedHighlights: Int
    public internal(set) var paintedWordTints: Int
    public internal(set) var paintedLive: Int
    public internal(set) var paintedHighlightRings: Int
    public var highlightColor: UIColor
    #if DEBUG
        public internal(set) var renderedStyle: ReaderRenderedStyle?
        public internal(set) var pageCurl: ReaderPageCurl
    #endif
    @ObservationIgnored public var onPageTap: (() -> Void)?
    @ObservationIgnored public var onHighlight: ((ReaderTextRange) -> Bool)?
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
        paintedLive = 0
        paintedHighlightRings = 0
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
        return page(of: book.tableOfContents[index].location)
    }

    public func page(of location: ReaderLocation) -> Int? {
        guard let pageStarts, pageStarts.indices.contains(location.chapter) else {
            return nil
        }
        let before = pageStarts[..<location.chapter].reduce(0) { $0 + $1.count }
        let index = pageStarts[location.chapter].lastIndex { $0 <= location.offset } ?? 0
        return before + index + 1
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

    public func clearTappedHighlight() {
        viewController.clearTappedHighlight()
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
