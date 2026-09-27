import ReadiumNavigator
import ReadiumShared
import UIKit
import WebKit

final class ReaderViewController: UIViewController {
    weak var controller: ReaderController?
    private let book: ReaderBook
    private let language: String?
    private let style: ReaderStyle
    private let initialLocation: ReaderLocation?
    private let navigator: EPUBNavigatorViewController
    private let backdrop = UIView()
    private let curtain = UIView()
    private var colors: ReaderColors
    private var pageTurn: ReaderPageTurn
    private var swipes: [UISwipeGestureRecognizer] = []
    private var press = Press.idle {
        didSet {
            if press.isHeld != oldValue.isHeld {
                enablePans()
            }
            publishSelection()
        }
    }
    private var pressGeneration = 0
    private var touchClearedSelection = false
    private weak var livePaint: WKWebView?
    private var isCurling = false
    private var isShowing = false
    private var isShown = false
    private weak var pager: UIScrollView?
    private var pageSelection: PageSelection?
    private var observations: [ScrollObservation] = []
    private var shownPage: ChapterPage?
    private var laidOutSize: CGSize?
    private var tapGeneration = 0
    private var pageCounts: [Int]?
    private var countedLayout: PageLayout?
    private var pageCounter: PageCounter?
    private var countTask: Task<Void, Never>?
    private var locateTask: Task<Void, Never>?
    private var selectionTask: Task<Void, Never>?
    private var voiceOverTask: Task<Void, Never>?

    private static let highlightGroup = "highlights"
    private static let wordGroup = "word"
    private static let wordDecoration = "word"
    private static let cssFontWeights = 1...1000
    private static let revealDuration: TimeInterval = 0.25

    init(
        book: ReaderBook, language: String?, location: ReaderLocation?, style: ReaderStyle, colors: ReaderColors,
        pageTurn: ReaderPageTurn
    ) {
        self.book = book
        self.language = language
        self.style = style
        self.colors = colors
        self.pageTurn = pageTurn
        initialLocation = location
        navigator = try! EPUBNavigatorViewController(
            publication: book.publication,
            initialLocation: Self.locator(for: location, in: book.publication),
            config: Self.configuration(style: style, colors: colors)
        )
        super.init(nibName: nil, bundle: nil)
        navigator.delegate = self
    }

    isolated deinit {
        countTask?.cancel()
        locateTask?.cancel()
        selectionTask?.cancel()
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

        view.addGestureRecognizer(
            TouchObserver(
                onTouchDown: { [weak self] in self?.touchedDown(at: $0) },
                onTouchUp: { [weak self] in self?.touchedUp() }))

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
        if view.bounds.size != laidOutSize {
            laidOutSize = view.bounds.size
            clearWord()
            press = .idle
            stopPainting()
            clearSelection()
        }
        countPages()
    }

    func apply(_ colors: ReaderColors) {
        self.colors = colors
        backdrop.backgroundColor = colors.page
        curtain.backgroundColor = colors.page
        view.tintColor = colors.selection
        navigator.submitPreferences(Self.preferences(style: style, colors: colors))
        paintWord()
    }

    func clearWord() {
        tapGeneration += 1
        guard controller?.word != nil else {
            return
        }
        controller?.word = nil
        paintWord()
    }

    private func show(_ word: ReaderWord) {
        controller?.word = word
        paintWord()
    }

    func highlightSelection() {
        guard let webView = withdrawSelection() else {
            return
        }
        selectionTask?.cancel()
        selectionTask = Task { [weak self] in
            guard let range = await self?.takeSelection(in: webView)?.range else {
                return
            }
            _ = self?.controller?.onHighlight?(range)
        }
    }

    func translateSelection() {
        guard let webView = withdrawSelection() else {
            return
        }
        tapGeneration += 1
        let generation = tapGeneration
        selectionTask?.cancel()
        selectionTask = Task { [weak self] in
            guard let word = await self?.takeSelection(in: webView), let self, generation == tapGeneration else {
                return
            }
            show(word)
        }
    }

    func copySelection() {
        guard let selection = controller?.selection else {
            return
        }
        UIPasteboard.general.string = selection.text
        clearSelection()
    }

    func clearSelection() {
        pageSelection = nil
        publishSelection()
        navigator.clearSelection()
    }

    private func withdrawSelection() -> WKWebView? {
        guard controller?.selection != nil, let webView = pageSelection?.webView else {
            return nil
        }
        pageSelection = nil
        publishSelection()
        return webView
    }

    private func publishSelection() {
        let shown = press == .idle ? pageSelection?.selection : nil
        guard shown != controller?.selection else {
            return
        }
        if shown != nil {
            clearWord()
        }
        controller?.selection = shown
    }

    fileprivate func selectionChanged(_ body: Any, in webView: WKWebView?) {
        guard let webView else {
            return
        }
        guard let found = body as? [String: Any] else {
            if webView === pageSelection?.webView {
                pageSelection = nil
                publishSelection()
            }
            return
        }
        guard let text = found["text"] as? String, let rect = rect(found, in: webView) else {
            return
        }
        pageSelection = PageSelection(selection: ReaderSelection(text: text, rect: rect), webView: webView)
        publishSelection()
    }

    private func takeSelection(in webView: WKWebView) async -> ReaderWord? {
        guard
            let found = try? await webView.callAsyncJavaScript(
                "return scholia.takeSelection(language)", arguments: ["language": language ?? NSNull()],
                contentWorld: .page) as? [String: Any],
            let text = found["word"] as? String,
            let sentence = found["sentence"] as? String,
            let offsetInSentence = found["offsetInSentence"] as? Int,
            let rect = rect(found, in: webView),
            let range = textRange(found["range"], in: webView)
        else {
            return nil
        }
        return ReaderWord(text: text, sentence: sentence, offsetInSentence: offsetInSentence, rect: rect, range: range)
    }

    private func paintWord() {
        let decorations = controller?.word.flatMap { word in
            locator(for: word.range).map {
                Decoration(
                    id: Self.wordDecoration, locator: $0,
                    style: Decoration.Style(
                        id: .wordTap, config: Decoration.Style.HighlightConfig(tint: colors.wordTap)))
            }
        }
        navigator.apply(decorations: decorations.map { [$0] } ?? [], in: Self.wordGroup)
    }

    func apply(_ highlights: [ReaderHighlight]) {
        let decorations = highlights.compactMap { highlight in
            locator(for: highlight.range).map {
                Decoration(id: highlight.id, locator: $0, style: .highlight(tint: highlight.color))
            }
        }
        navigator.apply(decorations: decorations, in: Self.highlightGroup)
    }

    func apply(_ pageTurn: ReaderPageTurn) {
        self.pageTurn = pageTurn
        for swipe in swipes {
            swipe.isEnabled = pageTurn == .curl
        }
        enablePans()
    }

    private func enablePans() {
        for scrollView in navigator.view.descendants(of: UIScrollView.self) {
            scrollView.panGestureRecognizer.isEnabled = pageTurn == .slide && !press.isHeld
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
            observations.append(ScrollObservation(pager, keyPath: \.contentOffset) { [weak self] in self?.pageMoved() })
        }
        if let initialLocation, let webView = webView(inChapter: initialLocation.chapter) {
            let function = navigator.presentation.scroll ? "scrollToOffset" : "showOffset"
            _ = try? await webView.callAsyncJavaScript(
                "return await scholia.\(function)(offset)", arguments: ["offset": initialLocation.offset],
                contentWorld: .page)
        }
        isShown = true
        trackPage()
        countPages()
        UIView.animate(withDuration: Self.revealDuration) {
            self.curtain.alpha = 0
        } completion: { _ in
            self.curtain.removeFromSuperview()
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
        clearWord()
        controller?.pageSpan = nil
        publishPage()
        locate(page)
    }

    private func currentPage() -> ChapterPage? {
        guard let pager, pager.bounds.width > 0 else {
            return nil
        }
        let chapter = Int((distanceFromStart(of: pager.bounds, in: pager) / pager.bounds.width).rounded())
        guard let scrollView = webView(inChapter: chapter)?.scrollView else {
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
            ScrollObservation(scrollView, keyPath: \.contentOffset) { [weak self] in self?.pageMoved() })
        observations.append(ScrollObservation(scrollView, keyPath: \.contentSize) { [weak self] in self?.trackPage() })
    }

    private func pageMoved() {
        clearWord()
        if !press.isHeld {
            stopPainting()
            if pageSelection != nil {
                clearSelection()
            }
        }
        trackPage()
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

    private func chapter(of webView: WKWebView) -> Int? {
        guard
            let pager, pager.bounds.width > 0,
            let spread = pager.subviews.first(where: { webView.isDescendant(of: $0) })
        else {
            return nil
        }
        return Int((distanceFromStart(of: spread.frame, in: pager) / pager.bounds.width).rounded())
    }

    private func textRange(_ found: Any?, in webView: WKWebView) -> ReaderTextRange? {
        guard
            let found = found as? [String: Any],
            let chapter = chapter(of: webView),
            let start = found["start"] as? Int,
            let end = found["end"] as? Int,
            let text = found["text"] as? String,
            let before = found["before"] as? String,
            let after = found["after"] as? String
        else {
            return nil
        }
        return ReaderTextRange(
            start: ReaderLocation(chapter: chapter, offset: start), end: ReaderLocation(chapter: chapter, offset: end),
            text: text, before: before, after: after)
    }

    private func rect(_ found: [String: Any], in webView: WKWebView) -> CGRect? {
        guard
            let x = found["x"] as? CGFloat,
            let y = found["y"] as? CGFloat,
            let width = found["width"] as? CGFloat,
            let height = found["height"] as? CGFloat
        else {
            return nil
        }
        return webView.convert(CGRect(x: x, y: y, width: width, height: height), to: view)
    }

    private func publishPage() {
        guard let shownPage, let pageCounts, pageCounts.indices.contains(shownPage.chapter) else {
            controller?.page = nil
            return
        }
        let before = pageCounts[..<shownPage.chapter].reduce(0, +)
        controller?.page = ReaderPage(
            chapter: shownPage.chapter,
            number: before + min(shownPage.page, pageCounts[shownPage.chapter] - 1) + 1,
            count: pageCounts.reduce(0, +)
        )
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
            controller?.location = ReaderLocation(chapter: page.chapter, offset: start)
            controller?.pageSpan = ReaderPageSpan(chapter: page.chapter, start: start, end: end)
        }
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
            book: book, configuration: Self.configuration(style: style, colors: colors),
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
        guard !touchClearedSelection else {
            return
        }
        tapGeneration += 1
        let generation = tapGeneration
        let isShowingWord = controller?.word != nil
        let word = await word(at: point)
        guard generation == tapGeneration else {
            return
        }
        if let word {
            show(word)
        } else if isShowingWord {
            clearWord()
        } else {
            controller?.onPageTap?()
        }
    }

    private func word(at point: CGPoint) async -> ReaderWord? {
        guard let webView = webView(at: point) else {
            return nil
        }
        let local = navigator.view.convert(point, to: webView)
        let arguments: [String: Any] = ["x": local.x, "y": local.y, "language": language ?? NSNull()]
        guard
            let found = try? await webView.callAsyncJavaScript(
                "return scholia.wordAt(x, y, language)", arguments: arguments, contentWorld: .page)
                as? [String: Any],
            let text = found["text"] as? String,
            let sentence = found["sentence"] as? String,
            let offsetInSentence = found["offsetInSentence"] as? Int,
            let rect = rect(found, in: webView),
            let range = textRange(found["range"], in: webView)
        else {
            return nil
        }
        return ReaderWord(text: text, sentence: sentence, offsetInSentence: offsetInSentence, rect: rect, range: range)
    }

    private func webView(at point: CGPoint) -> WKWebView? {
        var candidate = navigator.view.hitTest(point, with: nil)
        while let view = candidate, !(view is WKWebView) {
            candidate = view.superview
        }
        return candidate as? WKWebView
    }

    private func touchedDown(at location: CGPoint) {
        stopPainting()
        touchClearedSelection = false
        if let pageSelection {
            let selectionArea = pageSelection.selection.rect.insetBy(dx: -style.lineHeight, dy: -style.lineHeight)
            guard !selectionArea.contains(location) else {
                return
            }
            touchClearedSelection = true
            clearSelection()
        }
        pressGeneration += 1
        press = .touched(generation: pressGeneration)
    }

    private func touchedUp() {
        if case .touched = press {
            press = .idle
        }
    }

    @objc private func pressed(_ recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.location(in: view)
        switch (recognizer.state, press) {
        case (.began, .touched(let generation)):
            clearWord()
            guard let webView = webView(at: location) else {
                press = .idle
                return
            }
            let point = view.convert(location, to: webView)
            webView.callAsyncJavaScript(
                "scholia.beginPress(x, y, language)",
                arguments: ["x": point.x, "y": point.y, "language": language ?? NSNull()], in: nil, in: .page)
            press = .pressing(generation: generation, origin: location, webView: webView)
        case (.changed, .pressing(let generation, let origin, let webView)):
            guard hypot(location.x - origin.x, location.y - origin.y) > recognizer.allowableMovement else {
                return
            }
            startPainting(in: webView)
            paint(to: location, in: webView)
            press = .painting(generation: generation, webView: webView)
        case (.changed, .painting(_, let webView)):
            paint(to: location, in: webView)
        case (.ended, .painting(let generation, let webView)):
            commit(generation, in: webView)
        case (.ended, .pressing(_, _, let webView)):
            webView.callAsyncJavaScript("scholia.selectPress()", in: nil, in: .page)
            press = .idle
        case (.cancelled, .pressing), (.failed, .pressing):
            press = .idle
        case (.cancelled, .painting), (.failed, .painting):
            press = .idle
            stopPainting()
        default:
            break
        }
    }

    private func commit(_ generation: Int, in webView: WKWebView) {
        press = .committing(generation: generation)
        selectionTask?.cancel()
        selectionTask = Task { [weak self] in
            let found =
                try? await webView.callAsyncJavaScript("return scholia.takePaint()", contentWorld: .page)
                as? [String: Any]
            guard let self, !Task.isCancelled, press == .committing(generation: generation) else {
                return
            }
            press = .idle
            let isAdded = textRange(found?["range"], in: webView).flatMap { controller?.onHighlight?($0) } ?? false
            if !isAdded {
                stopPainting()
            }
        }
    }

    private func startPainting(in webView: WKWebView) {
        guard let color = controller?.highlightColor else {
            return
        }
        livePaint = webView
        webView.callAsyncJavaScript(
            "scholia.startPainting(fill, radius)", arguments: ["fill": color.css, "radius": style.highlightRadius],
            in: nil, in: .page)
    }

    private func paint(to location: CGPoint, in webView: WKWebView) {
        let point = view.convert(location, to: webView)
        webView.callAsyncJavaScript(
            "scholia.paintTo(x, y)", arguments: ["x": point.x, "y": point.y], in: nil, in: .page)
    }

    private func stopPainting() {
        guard let webView = livePaint else {
            return
        }
        livePaint = nil
        webView.callAsyncJavaScript("scholia.stopPainting()", in: nil, in: .page)
    }

    @objc private func swiped(_ swipe: UISwipeGestureRecognizer) {
        Task { await curl(forward: swipe.direction == .left) }
    }

    private func curl(forward: Bool) async {
        guard !isCurling else {
            return
        }
        clearWord()
        clearSelection()
        guard let current = await pageSnapshot() else {
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
        guard book.publication.readingOrder.indices.contains(range.start.chapter) else {
            return nil
        }
        let link = book.publication.readingOrder[range.start.chapter]
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

    private static func configuration(style: ReaderStyle, colors: ReaderColors)
        -> EPUBNavigatorViewController.Configuration
    {
        EPUBNavigatorViewController.Configuration(
            preferences: preferences(style: style, colors: colors),
            editingActions: [],
            decorationTemplates: [
                .highlight: tintTemplate(className: "scholia-highlight", radius: style.highlightRadius),
                .wordTap: tintTemplate(className: "scholia-word-tap", radius: style.highlightRadius),
            ],
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

    private static func tintTemplate(className: String, radius: CGFloat) -> HTMLDecorationTemplate {
        HTMLDecorationTemplate(
            layout: .boxes,
            element: { decoration in
                let tint = (decoration.style.config as? Decoration.Style.HighlightConfig)?.tint ?? .clear
                return "<div class=\"\(className)\" style=\"background-color: \(tint.css) !important\"/>"
            },
            stylesheet: ".\(className) { border-radius: \(radius)px; z-index: -1; }"
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
        userContentController.add(
            PaintedCount(controller: controller, count: \.paintedHighlights), name: "paintedHighlights")
        userContentController.add(
            PaintedCount(controller: controller, count: \.paintedWordTints), name: "paintedWordTints")
        userContentController.add(PaintedCount(controller: controller, count: \.paintedLive), name: "paintedLive")
        userContentController.add(SelectionMessages(viewController: self), name: "scholiaSelection")
    }

    func navigator(_ navigator: any SelectableNavigator, shouldShowMenuForSelection selection: Selection) -> Bool {
        false
    }

    private static let script = try! String(
        contentsOf: Bundle.module.url(forResource: "reader", withExtension: "js")!, encoding: .utf8)
}

private final class PaintedCount: NSObject, WKScriptMessageHandler {
    private weak var controller: ReaderController?
    private let count: ReferenceWritableKeyPath<ReaderController, Int>

    init(controller: ReaderController?, count: ReferenceWritableKeyPath<ReaderController, Int>) {
        self.controller = controller
        self.count = count
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let value = message.body as? Int {
            controller?[keyPath: count] = value
        }
    }
}

private final class SelectionMessages: NSObject, WKScriptMessageHandler {
    private weak var viewController: ReaderViewController?

    init(viewController: ReaderViewController) {
        self.viewController = viewController
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        viewController?.selectionChanged(message.body, in: message.webView)
    }
}

extension ReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        !(gestureRecognizer is UISwipeGestureRecognizer && press.isHeld)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

private enum Press: Equatable {
    case idle
    case touched(generation: Int)
    case pressing(generation: Int, origin: CGPoint, webView: WKWebView)
    case painting(generation: Int, webView: WKWebView)
    case committing(generation: Int)

    var isHeld: Bool {
        switch self {
        case .pressing, .painting: true
        case .idle, .touched, .committing: false
        }
    }
}

private struct PageSelection {
    let selection: ReaderSelection
    weak var webView: WKWebView?
}

private final class TouchObserver: UIGestureRecognizer {
    private let onTouchDown: (CGPoint) -> Void
    private let onTouchUp: () -> Void
    private var isTouching = false

    init(onTouchDown: @escaping (CGPoint) -> Void, onTouchUp: @escaping () -> Void) {
        self.onTouchDown = onTouchDown
        self.onTouchUp = onTouchUp
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard !isTouching, let touch = touches.first else {
            return
        }
        isTouching = true
        onTouchDown(touch.location(in: view))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        finishWhenLifted(event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        finishWhenLifted(event)
    }

    override func reset() {
        isTouching = false
    }

    private func finishWhenLifted(_ event: UIEvent) {
        let isLifted = event.touches(for: self)?.allSatisfy { $0.phase == .ended || $0.phase == .cancelled } ?? true
        guard isLifted else {
            return
        }
        onTouchUp()
        state = .failed
    }
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

    init<Value: Equatable & Sendable>(
        _ scrollView: UIScrollView, keyPath: KeyPath<UIScrollView, Value>, onChange: @escaping @MainActor () -> Void
    ) {
        self.scrollView = scrollView
        observation = scrollView.observe(keyPath, options: [.old, .new]) { _, change in
            guard change.oldValue != change.newValue else {
                return
            }
            MainActor.assumeIsolated { onChange() }
        }
    }
}

extension Decoration.Style.Id {
    fileprivate static let wordTap: Self = "wordTap"
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
