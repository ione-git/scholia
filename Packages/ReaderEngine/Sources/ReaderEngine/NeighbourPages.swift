import ReadiumNavigator
import ReadiumShared
import UIKit
import WebKit

struct PageShot {
    let image: UIImage
    let frame: CGRect
}

enum Neighbour: Equatable {
    case page(ChapterPage)
    case end
}

final class NeighbourPages: NSObject {
    private(set) var page: ChapterPage?
    private(set) var previous: Neighbour?
    private(set) var next: Neighbour?
    private(set) var shots: [ChapterPage: PageShot] = [:]
    var onChange: (() -> Void)?

    private let book: ReaderBook
    private let appearance: ReaderAppearance
    private let configuration: EPUBNavigatorViewController.Configuration
    private let decorations: [Decoration]
    private let contentInset: () -> UIEdgeInsets
    private weak var host: UIViewController?
    private var navigator: EPUBNavigatorViewController?
    private var chapter: Int?
    private var isLoaded = false
    private var visibility: ScrollObservation?
    private var loadWaiters: [CheckedContinuation<Void, Never>] = []
    private var pageCounts: [Int: Int] = [:]
    private var epoch = 0
    private var task: Task<Void, Never>?

    private static let lastPage = -1
    private static let shotAttempts = 2

    init(
        book: ReaderBook, appearance: ReaderAppearance, configuration: EPUBNavigatorViewController.Configuration,
        decorations: [Decoration], host: UIViewController, contentInset: @escaping () -> UIEdgeInsets
    ) {
        var configuration = configuration
        configuration.preloadPreviousPositionCount = 0
        configuration.preloadNextPositionCount = 0
        self.book = book
        self.appearance = appearance
        self.configuration = configuration
        self.decorations = decorations
        self.host = host
        self.contentInset = contentInset
    }

    var isReady: Bool {
        guard let page, shots[page] != nil, let previous, let next else {
            return false
        }
        return [previous, next].allSatisfy { $0 == .end || shot($0) != nil }
    }

    func shot(_ neighbour: Neighbour?) -> PageShot? {
        guard case .page(let page) = neighbour else {
            return nil
        }
        return shots[page]
    }

    func show(_ live: ChapterPage) {
        guard live != page else {
            return
        }
        let shown = page
        switch (shown, previous, next) {
        case (let shown?, _, .page(live)):
            previous = .page(shown)
            next = nil
        case (let shown?, .page(live), _):
            next = .page(shown)
            previous = nil
        default:
            previous = nil
            next = nil
        }
        page = live
        let kept = Set(
            [Neighbour.page(live), previous, next].compactMap { neighbour -> ChapterPage? in
                guard case .page(let page) = neighbour else {
                    return nil
                }
                return page
            })
        shots = shots.filter { kept.contains($0.key) }
        render()
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func stop() {
        epoch += 1
        cancel()
        removeNavigator()
    }

    private func render() {
        epoch += 1
        cancel()
        let epoch = epoch
        task = Task { [weak self] in
            await self?.fill(epoch: epoch)
        }
        onChange?()
    }

    private func fill(epoch: Int) async {
        guard let live = page else {
            return
        }
        if shots[live] == nil {
            guard await shoot(live, epoch: epoch) != nil else {
                return
            }
        }
        guard let count = pageCounts[live.chapter] else {
            return
        }
        let chapters = book.publication.readingOrder.count
        if next == nil {
            next =
                live.page + 1 < count
                ? .page(ChapterPage(chapter: live.chapter, page: live.page + 1))
                : live.chapter + 1 < chapters ? .page(ChapterPage(chapter: live.chapter + 1, page: 0)) : .end
        }
        if previous == nil, live.page > 0 || live.chapter == 0 {
            previous = live.page > 0 ? .page(ChapterPage(chapter: live.chapter, page: live.page - 1)) : .end
        }
        var pending = [next, previous].compactMap { neighbour -> ChapterPage? in
            guard case .page(let page) = neighbour, shots[page] == nil else {
                return nil
            }
            return page
        }
        if previous == nil {
            pending.append(ChapterPage(chapter: live.chapter - 1, page: Self.lastPage))
        }
        let chapter = chapter
        pending.sort { ($0.chapter == chapter ? 0 : 1) < ($1.chapter == chapter ? 0 : 1) }
        for target in pending {
            guard let shown = await shoot(target, epoch: epoch) else {
                return
            }
            if target.page == Self.lastPage {
                previous = .page(shown)
            }
        }
        onChange?()
    }

    private func shoot(_ target: ChapterPage, epoch: Int) async -> ChapterPage? {
        guard await place(in: target.chapter, epoch: epoch), let navigator, let webView = visibleWebView() else {
            return nil
        }
        for _ in 1...Self.shotAttempts {
            guard
                let shown = try? await webView.callAsyncJavaScript(
                    "return scholia.showPage(page)", arguments: ["page": target.page], contentWorld: .page) as? [Int],
                shown.count == 2, isCurrent(epoch)
            else {
                return nil
            }
            pageCounts[target.chapter] = shown[1]
            _ = try? await webView.callAsyncJavaScript(
                "return await scholia.rendered(expected, timeout)",
                arguments: [
                    "expected": ReaderViewController.renderedStyle(appearance),
                    "timeout": ReaderViewController.renderTimeout,
                ],
                contentWorld: .page)
            guard isCurrent(epoch) else {
                return nil
            }
            _ = try? await webView.callAsyncJavaScript(
                "return await scholia.highlightsPainted(expected, timeout)",
                arguments: [
                    "expected": highlightCount(in: target.chapter), "timeout": ReaderViewController.renderTimeout,
                ],
                contentWorld: .page)
            guard isCurrent(epoch), let image = try? await webView.takeSnapshot(configuration: nil) else {
                return nil
            }
            let stayed =
                try? await webView.callAsyncJavaScript("return scholia.shownPage()", contentWorld: .page) as? Int
            guard isCurrent(epoch) else {
                return nil
            }
            if stayed == shown[0] {
                let page = ChapterPage(chapter: target.chapter, page: shown[0])
                shots[page] = PageShot(image: image, frame: webView.convert(webView.bounds, to: navigator.view))
                return page
            }
        }
        return nil
    }

    private func isCurrent(_ epoch: Int) -> Bool {
        !Task.isCancelled && epoch == self.epoch
    }

    private func highlightCount(in chapter: Int) -> Int {
        let href = book.publication.readingOrder[chapter].url()
        return decorations.filter { $0.locator.href.isEquivalentTo(href) }.count
    }

    private func visibleWebView() -> WKWebView? {
        navigator?.view.descendants(of: WKWebView.self).first
    }

    private func place(in chapter: Int, epoch: Int) async -> Bool {
        if chapter != self.chapter {
            load(chapter)
        }
        while !isLoaded, isCurrent(epoch) {
            await withTaskCancellationHandler {
                await withCheckedContinuation { loadWaiters.append($0) }
            } onCancel: {
                Task { @MainActor [weak self] in self?.resumeLoadWaiters() }
            }
        }
        return isLoaded && isCurrent(epoch)
    }

    private func load(_ chapter: Int) {
        removeNavigator()
        guard let host else {
            return
        }
        let navigator = ReaderViewController.navigator(
            book: book, location: ReaderLocation(chapter: chapter, offset: 0), configuration: configuration)
        navigator.delegate = self
        navigator.view.isUserInteractionEnabled = false
        navigator.view.accessibilityElementsHidden = true
        navigator.apply(decorations: decorations, in: ReaderViewController.highlightGroup)
        host.addChild(navigator)
        navigator.view.frame = host.view.bounds
        navigator.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.insertSubview(navigator.view, at: 0)
        navigator.didMove(toParent: host)
        self.navigator = navigator
        self.chapter = chapter
    }

    private func removeNavigator() {
        isLoaded = false
        visibility = nil
        chapter = nil
        resumeLoadWaiters()
        guard let navigator else {
            return
        }
        navigator.delegate = nil
        navigator.willMove(toParent: nil)
        navigator.view.removeFromSuperview()
        navigator.removeFromParent()
        self.navigator = nil
    }

    private func resumeLoadWaiters() {
        let waiters = loadWaiters
        loadWaiters = []
        for waiter in waiters {
            waiter.resume()
        }
    }

    fileprivate func didLoad(_ loaded: EPUBNavigatorViewController?) {
        guard loaded === navigator, let scrollView = visibleWebView()?.scrollView else {
            return
        }
        guard scrollView.alpha == 1 else {
            visibility = ScrollObservation(scrollView, keyPath: \.alpha) { [weak self] in self?.didLoad(loaded) }
            return
        }
        visibility = nil
        isLoaded = true
        resumeLoadWaiters()
    }
}

extension NeighbourPages: EPUBNavigatorDelegate {
    func navigator(_ navigator: any Navigator, presentError error: NavigatorError) {}

    func navigatorContentInset(_ navigator: any VisualNavigator) -> UIEdgeInsets? {
        contentInset()
    }

    func navigator(
        _ navigator: EPUBNavigatorViewController, setupUserScripts userContentController: WKUserContentController
    ) {
        for script in [ReaderViewController.script, PageCounter.script] {
            userContentController.addUserScript(
                WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
        userContentController.add(LoadMessages(pages: self, navigator: navigator), name: "pageCount")
        for name in ["paintedHighlights", "paintedWordTints", "paintedLive"] {
            userContentController.add(IgnoredMessages(), name: name)
        }
    }
}

private final class LoadMessages: NSObject, WKScriptMessageHandler {
    private weak var pages: NeighbourPages?
    private weak var navigator: EPUBNavigatorViewController?

    init(pages: NeighbourPages, navigator: EPUBNavigatorViewController) {
        self.pages = pages
        self.navigator = navigator
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        pages?.didLoad(navigator)
    }
}

private final class IgnoredMessages: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}
}
