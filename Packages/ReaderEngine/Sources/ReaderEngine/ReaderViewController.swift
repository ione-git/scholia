import ReadiumNavigator
import ReadiumShared
import UIKit
import WebKit

final class ReaderViewController: UIViewController {
    weak var controller: ReaderController?
    private let book: ReaderBook
    private let style: ReaderStyle
    private var jumpTarget: ReaderJump?
    private var landing: Landing?
    private let highlightTitle: String
    private let navigator: EPUBNavigatorViewController
    private let backdrop = UIView()
    private let curtain = UIView()
    private var colors: ReaderColors
    private var pageTurn: ReaderPageTurn
    private var swipes: [UISwipeGestureRecognizer] = []
    private var pressOrigin: CGPoint?
    private var isPainting = false
    private var isCurling = false
    private var isShowing = false
    private var isShown = false
    private weak var pager: UIScrollView?
    private var observations: [ScrollObservation] = []
    private var shownPage: ChapterPage?
    private var pageCounts: [PageCount]?
    private var countedLayout: PageLayout?
    private var pageCounter: PageCounter?
    private var countTask: Task<Void, Never>?
    private var locateTask: Task<Void, Never>?
    private var jumpTask: Task<Void, Never>?
    private var voiceOverTask: Task<Void, Never>?

    private static let highlightGroup = "highlights"
    private static let cssFontWeights = 1...1000
    private static let revealDuration: TimeInterval = 0.25

    init(
        book: ReaderBook, location: ReaderLocation?, style: ReaderStyle, colors: ReaderColors, pageTurn: ReaderPageTurn,
        highlightTitle: String
    ) {
        self.book = book
        self.style = style
        self.colors = colors
        self.pageTurn = pageTurn
        self.highlightTitle = highlightTitle
        jumpTarget = location.map(ReaderJump.location)
        navigator = try! EPUBNavigatorViewController(
            publication: book.publication,
            initialLocation: Self.locator(for: location, in: book.publication),
            config: Self.configuration(style: style, colors: colors, highlightTitle: highlightTitle)
        )
        super.init(nibName: nil, bundle: nil)
        navigator.delegate = self
    }

    isolated deinit {
        countTask?.cancel()
        locateTask?.cancel()
        jumpTask?.cancel()
        voiceOverTask?.cancel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = colors.selection
        for cover in [backdrop, curtain] {
            cover.backgroundColor = colors.page
            cover.frame = view.bounds
            cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        view.addSubview(backdrop)
        embed(navigator)
        view.addSubview(curtain)
        navigator.addObserver(
            .tap { [weak self] event in
                await self?.tapped(at: event.location)
                return true
            })

        let press = UILongPressGestureRecognizer(target: self, action: #selector(pressed))
        press.cancelsTouchesInView = false
        press.delegate = self
        view.addGestureRecognizer(press)

        swipes = [UISwipeGestureRecognizer.Direction.left, .right].map { direction in
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
            swipe.direction = direction
            swipe.delegate = self
            view.addGestureRecognizer(swipe)
            return swipe
        }
        apply(pageTurn)

        voiceOverTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: UIAccessibility.voiceOverStatusDidChangeNotification)
            {
                self?.countPages()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        countPages()
    }

    func apply(_ colors: ReaderColors) {
        self.colors = colors
        backdrop.backgroundColor = colors.page
        curtain.backgroundColor = colors.page
        view.tintColor = colors.selection
        navigator.submitPreferences(Self.preferences(style: style, colors: colors))
    }

    func apply(_ highlights: [ReaderHighlight]) {
        let decorations = highlights.compactMap { highlight in
            locator(for: highlight.range).map {
                Decoration(id: highlight.id, locator: $0, style: .highlight(tint: highlight.color))
            }
        }
        navigator.apply(decorations: decorations, in: Self.highlightGroup)
    }

    func go(to target: ReaderJump) {
        jumpTarget = target
        jump()
    }

    func apply(_ pageTurn: ReaderPageTurn) {
        self.pageTurn = pageTurn
        for swipe in swipes {
            swipe.isEnabled = pageTurn == .curl
        }
        for scrollView in navigator.view.descendants(of: UIScrollView.self) {
            scrollView.panGestureRecognizer.isEnabled = pageTurn == .slide
        }
    }

    private func embed(_ child: UIViewController, at index: Int? = nil) {
        addChild(child)
        child.view.frame = view.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let index {
            view.insertSubview(child.view, at: index)
        } else {
            view.addSubview(child.view)
        }
        child.didMove(toParent: self)
    }

    private func show() async {
        guard !isShowing, !isShown else {
            return
        }
        isShowing = true
        pager = navigator.view.descendants(of: UIScrollView.self).first { !($0.superview is WKWebView) }
        if let pager {
            observations.append(ScrollObservation(pager, keyPath: \.contentOffset) { [weak self] in self?.trackPage() })
        }
        if let jumpTarget {
            await reach(jumpTarget)
        }
        isShown = true
        trackPage()
        countPages()
        jump()
        UIView.animate(withDuration: Self.revealDuration) {
            self.curtain.alpha = 0
        } completion: { _ in
            self.curtain.removeFromSuperview()
        }
    }

    private func jump() {
        guard isShown, let jumpTarget else {
            return
        }
        jumpTask?.cancel()
        jumpTask = Task { await reach(jumpTarget) }
    }

    private func reach(_ target: ReaderJump) async {
        let chapter = readingOrderIndex(of: target)
        guard shows(chapter), let webView = webView(inChapter: chapter) else {
            guard let locator = Self.locator(for: ReaderLocation(chapter: chapter, offset: 0), in: book.publication)
            else {
                jumpTarget = nil
                return
            }
            _ = await navigator.go(to: locator, options: NavigatorGoOptions(animated: false))
            return
        }
        let offset = await offset(of: target, in: webView)
        guard !Task.isCancelled, target == jumpTarget else {
            return
        }
        jumpTarget = nil
        guard let offset else {
            return
        }
        landing = Landing(location: ReaderLocation(chapter: chapter, offset: offset), isReached: false)
        let didShow = await show(offset, in: webView)
        guard !Task.isCancelled else {
            return
        }
        guard didShow else {
            landing = nil
            return
        }
        shownPage = nil
        trackPage()
    }

    private func readingOrderIndex(of target: ReaderJump) -> Int {
        switch target {
        case .location(let location): location.chapter
        case .chapter(let index): book.tableOfContents[index].location.chapter
        }
    }

    private func offset(of target: ReaderJump, in webView: WKWebView) async -> Int? {
        switch target {
        case .location(let location):
            return location.offset
        case .chapter(let index):
            await resolveFragments(inChapter: readingOrderIndex(of: target), in: webView)
            let chapter = book.tableOfContents[index]
            return chapter.unresolvedFragment == nil ? chapter.location.offset : nil
        }
    }

    private func shows(_ chapter: Int) -> Bool {
        shownChapter() == chapter
            && navigator.viewport?.resources.contains {
                book.publication.readingOrder.firstIndexWithHREF($0.href) == chapter
            } == true
    }

    private func show(_ offset: Int, in webView: WKWebView) async -> Bool {
        let function = navigator.presentation.scroll ? "scrollToOffset" : "showOffset"
        do {
            _ = try await webView.callAsyncJavaScript(
                "return await scholia.\(function)(offset)", arguments: ["offset": offset], contentWorld: .page)
            return true
        } catch {
            return false
        }
    }

    private func trackPage() {
        guard isShown, let page = currentPage() else {
            return
        }
        guard page != shownPage else {
            if navigator.presentation.scroll {
                locate(page)
            }
            return
        }
        shownPage = page
        controller?.word = nil
        controller?.pageSpan = nil
        publishPage()
        locate(page)
    }

    private func shownChapter() -> Int? {
        guard let pager, pager.bounds.width > 0 else {
            return nil
        }
        return Int((distanceFromStart(of: pager.bounds, in: pager) / pager.bounds.width).rounded())
    }

    private func currentPage() -> ChapterPage? {
        guard let chapter = shownChapter(), let scrollView = webView(inChapter: chapter)?.scrollView else {
            return nil
        }
        observe(scrollView)
        let width = scrollView.bounds.width
        guard width > 0, scrollView.contentSize.width >= width else {
            return nil
        }
        let count = Int((scrollView.contentSize.width / width).rounded())
        let page = Int((distanceFromStart(of: scrollView.bounds, in: scrollView) / width).rounded())
        return ChapterPage(chapter: chapter, page: min(max(page, 0), count - 1))
    }

    private func distanceFromStart(of rect: CGRect, in scrollView: UIScrollView) -> CGFloat {
        navigator.presentation.readingProgression == .rtl ? scrollView.contentSize.width - rect.maxX : rect.minX
    }

    private func observe(_ scrollView: UIScrollView) {
        observations.removeAll { $0.scrollView == nil }
        guard !observations.contains(where: { $0.scrollView === scrollView }) else {
            return
        }
        observations.append(
            ScrollObservation(scrollView, keyPath: \.contentOffset) { [weak self] in self?.trackPage() })
        observations.append(ScrollObservation(scrollView, keyPath: \.contentSize) { [weak self] in self?.trackPage() })
    }

    private func webView(inChapter chapter: Int) -> WKWebView? {
        guard let pager else {
            return nil
        }
        let distance = CGFloat(chapter) * pager.bounds.width
        return pager.subviews.lazy
            .filter { abs(self.distanceFromStart(of: $0.frame, in: pager) - distance) < 1 }
            .compactMap { $0.descendants(of: WKWebView.self).first }
            .first
    }

    private func publishPage() {
        let startPages = pageCounts.map(Self.startPages(of:))
        let chapterStartPages = pageCounts.flatMap(chapterStartPages(in:))
        if controller?.startPages != chapterStartPages {
            controller?.startPages = chapterStartPages
        }
        guard let shownPage, let pageCounts, let startPages, pageCounts.indices.contains(shownPage.chapter) else {
            controller?.page = nil
            return
        }
        controller?.page = ReaderPage(
            chapter: shownPage.chapter,
            number: startPages[shownPage.chapter] + min(shownPage.page, pageCounts[shownPage.chapter].pages - 1),
            count: pageCounts.map(\.pages).reduce(0, +)
        )
    }

    private func chapterStartPages(in pageCounts: [PageCount]) -> [Int]? {
        guard pageCounts.count == book.publication.readingOrder.count else {
            return nil
        }
        let startPages = Self.startPages(of: pageCounts)
        return book.tableOfContents.map { chapter in
            let file = chapter.location.chapter
            return startPages[file] + (chapter.fragment.flatMap { pageCounts[file].fragmentPages[$0] } ?? 0)
        }
    }

    private static func startPages(of pageCounts: [PageCount]) -> [Int] {
        var start = 1
        return pageCounts.map { count in
            defer { start += count.pages }
            return start
        }
    }

    private func locate(_ page: ChapterPage) {
        locateTask?.cancel()
        guard let webView = webView(inChapter: page.chapter) else {
            return
        }
        let script =
            navigator.presentation.scroll
            ? "return scholia.visibleOffsets()" : "return [scholia.offsetOfPage(page), scholia.offsetOfPage(page + 1)]"
        locateTask = Task {
            await resolveFragments(inChapter: page.chapter, in: webView)
            let offsets =
                try? await webView.callAsyncJavaScript(script, arguments: ["page": page.page], contentWorld: .page)
                as? [Int]
            guard !Task.isCancelled, let offsets, let start = offsets.first, let end = offsets.last else {
                return
            }
            let span = ReaderPageSpan(chapter: page.chapter, start: start, end: end)
            controller?.location = landed(in: span) ?? ReaderLocation(chapter: page.chapter, offset: start)
            controller?.pageSpan = span
        }
    }

    private func landed(in span: ReaderPageSpan) -> ReaderLocation? {
        guard let landing else {
            return nil
        }
        guard span.contains(landing.location) else {
            if landing.isReached {
                self.landing = nil
            }
            return nil
        }
        self.landing?.isReached = true
        return landing.location
    }

    private func resolveFragments(inChapter chapter: Int, in webView: WKWebView) async {
        let fragments = book.unresolvedFragments(inChapter: chapter)
        guard
            !fragments.isEmpty,
            let offsets = try? await webView.callAsyncJavaScript(
                "return scholia.offsetsOfElements(ids)", arguments: ["ids": fragments], contentWorld: .page)
                as? [String: Int]
        else {
            return
        }
        book.resolveFragments(offsets, inChapter: chapter)
    }

    private func countPages() {
        let layout = PageLayout(size: view.bounds.size, isScrolled: navigator.presentation.scroll)
        guard isShown, layout.size.width > 0, layout.size.height > 0, layout != countedLayout else {
            return
        }
        countedLayout = layout
        stopCounting()
        let key = PageCountCache.key(book: book, style: style, size: layout.size)
        pageCounts = layout.isScrolled ? nil : PageCountCache.counts(for: key)
        shownPage = nil
        controller?.pageSpan = nil
        publishPage()
        trackPage()
        guard !layout.isScrolled, pageCounts == nil else {
            return
        }
        let counter = PageCounter(
            book: book, configuration: Self.configuration(style: style, colors: colors, highlightTitle: highlightTitle),
            contentInset: { [weak self] in self?.contentInset ?? .zero })
        counter.navigator.view.isUserInteractionEnabled = false
        counter.navigator.view.accessibilityElementsHidden = true
        embed(counter.navigator, at: 0)
        pageCounter = counter
        countTask = Task { [weak self] in
            let counts = await counter.count()
            guard !Task.isCancelled, let self else {
                return
            }
            stopCounting()
            guard let counts else {
                return
            }
            PageCountCache.store(counts, for: key)
            pageCounts = counts
            publishPage()
        }
    }

    private func stopCounting() {
        countTask?.cancel()
        countTask = nil
        guard let pageCounter else {
            return
        }
        pageCounter.navigator.willMove(toParent: nil)
        pageCounter.navigator.view.removeFromSuperview()
        pageCounter.navigator.removeFromParent()
        self.pageCounter = nil
    }

    private var contentInset: UIEdgeInsets {
        let available = view.bounds.height - style.topMargin - style.minimumBottomMargin
        let lines = (available / style.lineHeight).rounded(.down)
        return UIEdgeInsets(
            top: style.topMargin, left: 0, bottom: view.bounds.height - style.topMargin - lines * style.lineHeight,
            right: 0)
    }

    private func tapped(at point: CGPoint) async {
        let word = await word(at: point)
        controller?.word = word
        if word == nil {
            controller?.onPageTap?()
        }
    }

    private func word(at point: CGPoint) async -> ReaderWord? {
        guard
            let chapter = navigator.currentLocation?.href.string,
            let webView = webView(at: point)
        else {
            return nil
        }
        let local = navigator.view.convert(point, to: webView)
        let arguments: [String: Any] = ["x": local.x, "y": local.y, "language": book.language ?? NSNull()]
        guard
            let found = try? await webView.callAsyncJavaScript(
                "return scholia.wordAt(x, y, language)", arguments: arguments, contentWorld: .page)
                as? [String: Any],
            let text = found["text"] as? String,
            let sentence = found["sentence"] as? String,
            let x = found["x"] as? CGFloat,
            let y = found["y"] as? CGFloat,
            let width = found["width"] as? CGFloat,
            let height = found["height"] as? CGFloat,
            let before = found["before"] as? String,
            let after = found["after"] as? String
        else {
            return nil
        }
        return ReaderWord(
            text: text,
            sentence: sentence,
            rect: webView.convert(CGRect(x: x, y: y, width: width, height: height), to: view),
            range: ReaderTextRange(chapter: chapter, text: text, before: before, after: after)
        )
    }

    private func webView(at point: CGPoint) -> WKWebView? {
        var candidate = navigator.view.hitTest(point, with: nil)
        while let view = candidate, !(view is WKWebView) {
            candidate = view.superview
        }
        return candidate as? WKWebView
    }

    @objc private func highlightSelection() {
        Task { await takeSelection() }
    }

    private func takeSelection() async {
        guard
            let controller,
            let chapter = navigator.currentLocation?.href.string,
            case .success(let value) = await navigator.evaluateJavaScript("scholia.takeSelection()"),
            let found = value as? [String: Any],
            let text = found["text"] as? String,
            let before = found["before"] as? String,
            let after = found["after"] as? String
        else {
            return
        }
        controller.highlights.append(
            ReaderHighlight(
                id: UUID().uuidString,
                range: ReaderTextRange(chapter: chapter, text: text, before: before, after: after),
                color: controller.highlightColor
            )
        )
    }

    @objc private func pressed(_ press: UILongPressGestureRecognizer) {
        let location = press.location(in: view)
        switch press.state {
        case .began:
            pressOrigin = location
        case .changed:
            guard
                !isPainting,
                let pressOrigin,
                hypot(location.x - pressOrigin.x, location.y - pressOrigin.y) > press.allowableMovement
            else {
                return
            }
            isPainting = true
            view.tintColor = controller?.highlightColor.withAlphaComponent(1)
        case .ended where isPainting:
            Task {
                await takeSelection()
                stopPainting()
            }
        default:
            stopPainting()
        }
    }

    private func stopPainting() {
        pressOrigin = nil
        isPainting = false
        view.tintColor = colors.selection
    }

    @objc private func swiped(_ swipe: UISwipeGestureRecognizer) {
        Task { await curl(forward: swipe.direction == .left) }
    }

    private func curl(forward: Bool) async {
        guard !isCurling, let current = await pageSnapshot() else {
            return
        }
        isCurling = true
        let pager = UIPageViewController(
            transitionStyle: .pageCurl, navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.min.rawValue])
        pager.isDoubleSided = true
        pager.setViewControllers([current], direction: .forward, animated: false)
        addChild(pager)
        pager.view.frame = view.bounds
        view.addSubview(pager.view)
        pager.didMove(toParent: self)
        let options = NavigatorGoOptions(animated: false)
        let moved = forward ? await navigator.goForward(options: options) : await navigator.goBackward(options: options)
        if moved, let next = await pageSnapshot() {
            await withCheckedContinuation { continuation in
                pager.setViewControllers([next, pageBack()], direction: forward ? .forward : .reverse, animated: true) {
                    _ in continuation.resume()
                }
            }
        }
        pager.willMove(toParent: nil)
        pager.view.removeFromSuperview()
        pager.removeFromParent()
        isCurling = false
    }

    private func pageSnapshot() async -> UIViewController? {
        guard
            let webView = webView(at: CGPoint(x: view.bounds.midX, y: view.bounds.midY)),
            let image = try? await webView.takeSnapshot(configuration: nil)
        else {
            return nil
        }
        let page = pageBack()
        let imageView = UIImageView(image: image)
        imageView.frame = webView.convert(webView.bounds, to: view)
        page.view.addSubview(imageView)
        return page
    }

    private func pageBack() -> UIViewController {
        let page = UIViewController()
        page.view.backgroundColor = colors.page
        return page
    }

    private func locator(for range: ReaderTextRange) -> Locator? {
        guard
            let href = AnyURL(string: range.chapter),
            let link = book.publication.linkWithHREF(href)
        else {
            return nil
        }
        return Locator(
            href: link.url(),
            mediaType: link.mediaType ?? .xhtml,
            text: Locator.Text(after: range.after, before: range.before, highlight: range.text)
        )
    }

    private static func locator(for location: ReaderLocation?, in publication: Publication) -> Locator? {
        guard let location, publication.readingOrder.indices.contains(location.chapter) else {
            return nil
        }
        let link = publication.readingOrder[location.chapter]
        return Locator(
            href: link.url(), mediaType: link.mediaType ?? .xhtml, locations: Locator.Locations(progression: 0))
    }

    private static func configuration(style: ReaderStyle, colors: ReaderColors, highlightTitle: String)
        -> EPUBNavigatorViewController.Configuration
    {
        EPUBNavigatorViewController.Configuration(
            preferences: preferences(style: style, colors: colors),
            editingActions: [EditingAction(title: highlightTitle, action: #selector(highlightSelection)), .copy],
            decorationTemplates: [.highlight: highlightTemplate(radius: style.highlightRadius)],
            fontFamilyDeclarations: [fontDeclaration(style.font)],
            readiumCSSRSProperties: CSSRSProperties(
                pageGutter: CSSPxLength(style.sideMargin),
                paraIndent: CSSPxLength(style.paragraphIndent),
                baseLineHeight: .length(CSSPxLength(style.lineHeight)),
                overrides: ["font-size": CSSPxLength(style.fontSize).css()]
            )
        )
    }

    private static func preferences(style: ReaderStyle, colors: ReaderColors) -> EPUBPreferences {
        EPUBPreferences(
            backgroundColor: ReadiumNavigator.Color(uiColor: colors.page),
            fontFamily: FontFamily(rawValue: style.font.family),
            hyphens: true,
            publisherStyles: false,
            scroll: false,
            textColor: ReadiumNavigator.Color(uiColor: colors.text)
        )
    }

    private static func fontDeclaration(_ font: ReaderTypeface) -> AnyHTMLFontFamilyDeclaration {
        CSSFontFamilyDeclaration(
            fontFamily: FontFamily(rawValue: font.family),
            fontFaces: [
                CSSFontFace(file: FileURL(url: font.regular)!, style: .normal, weight: .variable(cssFontWeights)),
                CSSFontFace(file: FileURL(url: font.italic)!, style: .italic, weight: .variable(cssFontWeights)),
            ]
        ).eraseToAnyHTMLFontFamilyDeclaration()
    }

    private static func highlightTemplate(radius: CGFloat) -> HTMLDecorationTemplate {
        HTMLDecorationTemplate(
            layout: .boxes,
            element: { decoration in
                let tint = (decoration.style.config as? Decoration.Style.HighlightConfig)?.tint ?? .clear
                return "<div class=\"scholia-highlight\" style=\"background-color: \(tint.css) !important\"/>"
            },
            stylesheet: ".scholia-highlight { border-radius: \(radius)px; z-index: -1; }"
        )
    }
}

extension ReaderViewController: EPUBNavigatorDelegate {
    func navigator(_ navigator: any Navigator, presentError error: NavigatorError) {}

    func navigator(_ navigator: any ViewportObservingNavigator, viewportDidChange viewport: NavigatorViewport?) {
        apply(pageTurn)
        guard viewport != nil else {
            return
        }
        if isShown {
            trackPage()
            jump()
        } else {
            Task { await show() }
        }
    }

    func navigatorContentInset(_ navigator: any VisualNavigator) -> UIEdgeInsets? {
        contentInset
    }

    func navigator(
        _ navigator: EPUBNavigatorViewController, setupUserScripts userContentController: WKUserContentController
    ) {
        userContentController.addUserScript(
            WKUserScript(source: Self.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        userContentController.add(PaintedHighlights(controller: controller), name: "paintedHighlights")
    }

    func navigator(_ navigator: any SelectableNavigator, shouldShowMenuForSelection selection: Selection) -> Bool {
        !isPainting
    }

    static let script = try! String(
        contentsOf: Bundle.module.url(forResource: "reader", withExtension: "js")!, encoding: .utf8)
}

private final class PaintedHighlights: NSObject, WKScriptMessageHandler {
    private weak var controller: ReaderController?

    init(controller: ReaderController?) {
        self.controller = controller
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let count = message.body as? Int {
            controller?.paintedHighlights = count
        }
    }
}

extension ReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

enum ReaderJump: Equatable {
    case location(ReaderLocation)
    case chapter(Int)
}

private struct Landing {
    var location: ReaderLocation
    var isReached: Bool
}

private struct ChapterPage: Equatable {
    var chapter: Int
    var page: Int
}

private struct PageLayout: Equatable {
    var size: CGSize
    var isScrolled: Bool
}

private struct ScrollObservation {
    weak var scrollView: UIScrollView?
    let observation: NSKeyValueObservation

    init<Value>(
        _ scrollView: UIScrollView, keyPath: KeyPath<UIScrollView, Value>, onChange: @escaping @MainActor () -> Void
    ) {
        self.scrollView = scrollView
        observation = scrollView.observe(keyPath) { _, _ in
            MainActor.assumeIsolated { onChange() }
        }
    }
}

extension UIView {
    fileprivate func descendants<T: UIView>(of type: T.Type) -> [T] {
        subviews.flatMap { [$0].compactMap { $0 as? T } + $0.descendants(of: type) }
    }
}

extension UIColor {
    fileprivate var css: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return "rgba(\(Int(red * 255)), \(Int(green * 255)), \(Int(blue * 255)), \(alpha))"
    }
}
