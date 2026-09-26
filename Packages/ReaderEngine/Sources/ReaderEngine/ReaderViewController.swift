import ReadiumNavigator
import ReadiumShared
import UIKit
import WebKit

final class ReaderViewController: UIViewController {
    weak var controller: ReaderController?
    private(set) var appearance: ReaderAppearance
    private let book: ReaderBook
    private let typefaces: [ReaderTypeface]
    private let highlightTitle: String
    private var navigator: EPUBNavigatorViewController
    private var restoreLocation: ReaderLocation?
    private let backdrop = UIView()
    private let curtain = UIView()
    private var cover: UIView?
    private var swipes: [UISwipeGestureRecognizer] = []
    private var pressOrigin: CGPoint?
    private var isPainting = false
    private var isTurning = false
    private var isShowing = false
    private var isShown = false
    private var showWaiters: [CheckedContinuation<Void, Never>] = []
    private var generation = 0
    private var epoch = 0
    private var applyTask: Task<Void, Never>?
    private weak var pager: UIScrollView?
    private var observations: [ScrollObservation] = []
    private var shownPage: ChapterPage?
    private var pageCounts: [Int]?
    private var countedLayout: PageLayout?
    private var pageCounter: PageCounter?
    private var countTask: Task<Void, Never>?
    private var locateTask: Task<Void, Never>?
    private var turnTask: Task<Void, Never>?
    private var voiceOverTask: Task<Void, Never>?

    private static let highlightGroup = "highlights"
    private static let cssFontWeights = 1...1000
    private static let revealDuration: TimeInterval = 0.25
    private static let fadeDuration: TimeInterval = 0.2
    private static let scrollSettleDelay = Duration.milliseconds(150)
    private static let renderTimeout = 1000

    init(
        book: ReaderBook, location: ReaderLocation?, appearance: ReaderAppearance, typefaces: [ReaderTypeface],
        highlightTitle: String
    ) {
        self.book = book
        self.appearance = appearance
        self.typefaces = typefaces
        self.highlightTitle = highlightTitle
        restoreLocation = location
        navigator = Self.navigator(
            book: book, location: location,
            configuration: Self.configuration(
                appearance: appearance, typefaces: typefaces, highlightTitle: highlightTitle))
        super.init(nibName: nil, bundle: nil)
        configure(navigator)
    }

    isolated deinit {
        applyTask?.cancel()
        countTask?.cancel()
        locateTask?.cancel()
        turnTask?.cancel()
        voiceOverTask?.cancel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = appearance.colors.selection
        for layer in [backdrop, curtain] {
            layer.backgroundColor = appearance.colors.page
            layer.frame = view.bounds
            layer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        view.addSubview(backdrop)
        embed(navigator)
        view.addSubview(curtain)

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
        applyGestures()

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

    func apply(_ appearance: ReaderAppearance) async {
        generation += 1
        let current = generation
        let previous = applyTask
        let task = Task { [weak self] in
            await previous?.value
            await self?.render(appearance, generation: current)
        }
        applyTask = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    func apply(_ highlights: [ReaderHighlight]) {
        let decorations = highlights.compactMap { highlight in
            locator(for: highlight.range).map {
                Decoration(id: highlight.id, locator: $0, style: .highlight(tint: highlight.color))
            }
        }
        navigator.apply(decorations: decorations, in: Self.highlightGroup)
    }

    private func render(_ target: ReaderAppearance, generation current: Int) async {
        defer {
            if current == generation {
                revealCover()
            }
        }
        guard current == generation, !Task.isCancelled, target != appearance else {
            return
        }
        let restore = controller?.location ?? restoreLocation
        let changesLayout =
            layoutStyle(appearance) != layoutStyle(target) || isScrolled(appearance) != isScrolled(target)
        let changesFont = appearance.style.font != target.style.font
        if changesLayout {
            coverPage()
            await rebuild(target, at: restore)
        } else {
            if changesFont {
                coverPage()
            }
            appearance = target
            recolor()
            navigator.submitPreferences(Self.preferences(target))
            applyGestures()
            if changesFont {
                await reflow(to: restore)
            } else {
                await waitUntilRendered()
            }
        }
        guard current == generation, !Task.isCancelled else {
            return
        }
        #if DEBUG
            await publishRenderedStyle()
        #endif
    }

    private func layoutStyle(_ appearance: ReaderAppearance) -> ReaderStyle {
        var style = appearance.style
        style.font = self.appearance.style.font
        return style
    }

    private func isScrolled(_ appearance: ReaderAppearance) -> Bool {
        appearance.pageTurn == .scroll
    }

    private func rebuild(_ target: ReaderAppearance, at location: ReaderLocation?) async {
        forgetPages()
        isShowing = false
        pager = nil
        observations = []
        restoreLocation = location
        appearance = target
        recolor()
        let old = navigator
        old.delegate = nil
        navigator = Self.navigator(
            book: book, location: location,
            configuration: Self.configuration(
                appearance: target, typefaces: typefaces, highlightTitle: highlightTitle))
        configure(navigator)
        embed(navigator, at: view.subviews.firstIndex(of: old.view).map { $0 + 1 })
        old.willMove(toParent: nil)
        old.view.removeFromSuperview()
        old.removeFromParent()
        applyGestures()
        apply(controller?.highlights ?? [])
        await waitUntilShown()
    }

    private func reflow(to location: ReaderLocation?) async {
        forgetPages()
        let epoch = epoch
        await waitUntilRendered()
        if let location {
            await present(location)
        }
        guard epoch == self.epoch else {
            return
        }
        isShown = true
        trackPage()
        countPages()
    }

    private func forgetPages() {
        epoch += 1
        stopCounting()
        locateTask?.cancel()
        turnTask?.cancel()
        isShown = false
        shownPage = nil
        pageCounts = nil
        countedLayout = nil
        controller?.word = nil
        controller?.pageSpan = nil
        controller?.page = nil
    }

    private func recolor() {
        backdrop.backgroundColor = appearance.colors.page
        curtain.backgroundColor = appearance.colors.page
        view.tintColor = appearance.colors.selection
    }

    private func applyGestures() {
        let isScrolled = navigator.presentation.scroll
        for swipe in swipes {
            swipe.isEnabled = !isScrolled && (appearance.pageTurn == .curl || appearance.pageTurn == .fade)
        }
        for scrollView in navigator.view.descendants(of: UIScrollView.self) {
            scrollView.panGestureRecognizer.isEnabled = isScrolled || appearance.pageTurn == .slide
        }
    }

    private func coverPage() {
        guard cover == nil, let snapshot = view.snapshotView(afterScreenUpdates: false) else {
            return
        }
        snapshot.frame = view.bounds
        snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        snapshot.isUserInteractionEnabled = false
        view.addSubview(snapshot)
        cover = snapshot
    }

    private func revealCover() {
        guard let cover else {
            return
        }
        self.cover = nil
        UIView.animate(withDuration: Self.revealDuration) {
            cover.alpha = 0
        } completion: { _ in
            cover.removeFromSuperview()
        }
    }

    private func waitUntilShown() async {
        guard !isShown else {
            return
        }
        await withTaskCancellationHandler {
            await withCheckedContinuation { showWaiters.append($0) }
        } onCancel: {
            Task { @MainActor [weak self] in self?.resumeShowWaiters() }
        }
    }

    private func resumeShowWaiters() {
        let waiters = showWaiters
        showWaiters = []
        for waiter in waiters {
            waiter.resume()
        }
    }

    private func waitUntilRendered() async {
        guard let webView = visibleWebView() else {
            return
        }
        let expected: [String: Any] = [
            "background": appearance.colors.page.hex, "text": appearance.colors.text.hex,
            "fontFamily": appearance.style.font.family,
        ]
        _ = try? await webView.callAsyncJavaScript(
            "return await scholia.rendered(expected, timeout)",
            arguments: ["expected": expected, "timeout": Self.renderTimeout], contentWorld: .page)
    }

    #if DEBUG
        private func publishRenderedStyle() async {
            guard
                let webView = visibleWebView(),
                let found = try? await webView.callAsyncJavaScript(
                    "return scholia.style()", contentWorld: .page) as? [String: Any],
                let background = found["background"] as? String,
                let text = found["text"] as? String,
                let fontFamily = found["fontFamily"] as? String,
                let fontSize = found["fontSize"] as? Double,
                let lineHeight = found["lineHeight"] as? Double
            else {
                return
            }
            controller?.renderedStyle = ReaderRenderedStyle(
                background: background, text: text, fontFamily: fontFamily, fontSize: fontSize,
                lineHeight: lineHeight)
        }
    #endif

    private func configure(_ navigator: EPUBNavigatorViewController) {
        navigator.delegate = self
        navigator.addObserver(
            .tap { [weak self] event in
                await self?.tapped(at: event.location)
                return true
            })
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
        let epoch = epoch
        pager = navigator.view.descendants(of: UIScrollView.self).first { !($0.superview is WKWebView) }
        if let pager {
            observations.append(ScrollObservation(pager, keyPath: \.contentOffset) { [weak self] in self?.trackPage() })
        }
        if let restoreLocation {
            await present(restoreLocation)
        }
        guard epoch == self.epoch else {
            return
        }
        isShown = true
        trackPage()
        countPages()
        resumeShowWaiters()
        if curtain.superview != nil {
            UIView.animate(withDuration: Self.revealDuration) {
                self.curtain.alpha = 0
            } completion: { _ in
                self.curtain.removeFromSuperview()
            }
        }
        #if DEBUG
            await publishRenderedStyle()
        #endif
    }

    private func present(_ location: ReaderLocation) async {
        guard let webView = webView(inChapter: location.chapter) else {
            return
        }
        let function = navigator.presentation.scroll ? "scrollToOffset" : "showOffset"
        _ = try? await webView.callAsyncJavaScript(
            "return await scholia.\(function)(offset)", arguments: ["offset": location.offset], contentWorld: .page)
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

    private func currentPage() -> ChapterPage? {
        guard let chapter = visibleChapter(), let scrollView = webView(inChapter: chapter)?.scrollView else {
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

    private func visibleChapter() -> Int? {
        guard let pager, pager.bounds.width > 0 else {
            return nil
        }
        return Int((distanceFromStart(of: pager.bounds, in: pager) / pager.bounds.width).rounded())
    }

    private func visibleWebView() -> WKWebView? {
        visibleChapter().flatMap(webView(inChapter:))
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
        let isScrolled = navigator.presentation.scroll
        let script =
            isScrolled
            ? "return scholia.visibleOffsets()" : "return [scholia.offsetOfPage(page), scholia.offsetOfPage(page + 1)]"
        let epoch = epoch
        locateTask = Task {
            if isScrolled {
                try? await Task.sleep(for: Self.scrollSettleDelay)
                guard !Task.isCancelled, !webView.scrollView.isDragging, !webView.scrollView.isDecelerating else {
                    return
                }
            }
            await resolveFragments(inChapter: page.chapter, in: webView)
            let offsets =
                try? await webView.callAsyncJavaScript(script, arguments: ["page": page.page], contentWorld: .page)
                as? [Int]
            guard !Task.isCancelled, epoch == self.epoch, let offsets, let start = offsets.first, let end = offsets.last
            else {
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
        let key = PageCountCache.key(book: book, style: appearance.style, size: layout.size)
        pageCounts = layout.isScrolled ? nil : PageCountCache.counts(for: key)
        shownPage = nil
        controller?.pageSpan = nil
        publishPage()
        trackPage()
        guard !layout.isScrolled, pageCounts == nil else {
            return
        }
        let counter = PageCounter(
            book: book,
            configuration: Self.configuration(
                appearance: appearance, typefaces: typefaces, highlightTitle: highlightTitle),
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
        let style = appearance.style
        let available = view.bounds.height - style.topMargin - style.minimumBottomMargin
        let lines = (available / style.lineHeight).rounded(.down)
        return UIEdgeInsets(
            top: style.topMargin, left: 0, bottom: view.bounds.height - style.topMargin - lines * style.lineHeight,
            right: 0)
    }

    private func tapped(at point: CGPoint) async {
        guard controller?.looksUpWords == true else {
            controller?.onPageTap?()
            return
        }
        let epoch = epoch
        let word = await word(at: point)
        guard epoch == self.epoch else {
            return
        }
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
        view.tintColor = appearance.colors.selection
    }

    @objc private func swiped(_ swipe: UISwipeGestureRecognizer) {
        guard !isTurning else {
            return
        }
        isTurning = true
        let forward = (swipe.direction == .left) == (navigator.presentation.readingProgression != .rtl)
        let pageTurn = appearance.pageTurn
        turnTask = Task {
            switch pageTurn {
            case .fade: await fade(forward: forward)
            default: await curl(forward: forward)
            }
            isTurning = false
        }
    }

    private func fade(forward: Bool) async {
        guard let snapshot = navigator.view.snapshotView(afterScreenUpdates: false) else {
            return
        }
        snapshot.frame = navigator.view.frame
        snapshot.isUserInteractionEnabled = false
        view.insertSubview(snapshot, aboveSubview: navigator.view)
        let options = NavigatorGoOptions(animated: false)
        _ = forward ? await navigator.goForward(options: options) : await navigator.goBackward(options: options)
        _ = await UIView.animate(withDuration: Self.fadeDuration) {
            snapshot.alpha = 0
        }
        snapshot.removeFromSuperview()
    }

    private func curl(forward: Bool) async {
        guard let current = await pageSnapshot() else {
            return
        }
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
        page.view.backgroundColor = appearance.colors.page
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

    private static func navigator(
        book: ReaderBook, location: ReaderLocation?, configuration: EPUBNavigatorViewController.Configuration
    ) -> EPUBNavigatorViewController {
        try! EPUBNavigatorViewController(
            publication: book.publication, initialLocation: locator(for: location, in: book.publication),
            config: configuration)
    }

    private static func locator(for location: ReaderLocation?, in publication: Publication) -> Locator? {
        guard let location, publication.readingOrder.indices.contains(location.chapter) else {
            return nil
        }
        let link = publication.readingOrder[location.chapter]
        return Locator(
            href: link.url(), mediaType: link.mediaType ?? .xhtml, locations: Locator.Locations(progression: 0))
    }

    private static func configuration(
        appearance: ReaderAppearance, typefaces: [ReaderTypeface], highlightTitle: String
    ) -> EPUBNavigatorViewController.Configuration {
        let style = appearance.style
        return EPUBNavigatorViewController.Configuration(
            preferences: preferences(appearance),
            editingActions: [EditingAction(title: highlightTitle, action: #selector(highlightSelection)), .copy],
            decorationTemplates: [.highlight: highlightTemplate(radius: style.highlightRadius)],
            fontFamilyDeclarations: typefaces.compactMap(fontDeclaration),
            readiumCSSRSProperties: CSSRSProperties(
                pageGutter: CSSPxLength(style.sideMargin),
                paraIndent: CSSPxLength(style.paragraphIndent),
                baseLineHeight: .length(CSSPxLength(style.lineHeight)),
                overrides: ["font-size": CSSPxLength(style.fontSize).css()]
            )
        )
    }

    private static func preferences(_ appearance: ReaderAppearance) -> EPUBPreferences {
        EPUBPreferences(
            backgroundColor: ReadiumNavigator.Color(uiColor: appearance.colors.page),
            fontFamily: FontFamily(rawValue: appearance.style.font.family),
            hyphens: true,
            publisherStyles: false,
            scroll: appearance.pageTurn == .scroll,
            textColor: ReadiumNavigator.Color(uiColor: appearance.colors.text)
        )
    }

    private static func fontDeclaration(_ typeface: ReaderTypeface) -> AnyHTMLFontFamilyDeclaration? {
        guard case .bundled(let family, let regular, let italic) = typeface else {
            return nil
        }
        return CSSFontFamilyDeclaration(
            fontFamily: FontFamily(rawValue: family),
            fontFaces: [
                CSSFontFace(file: FileURL(url: regular)!, style: .normal, weight: .variable(cssFontWeights)),
                CSSFontFace(file: FileURL(url: italic)!, style: .italic, weight: .variable(cssFontWeights)),
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
        applyGestures()
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
        userContentController.add(PaintedHighlights(controller: controller), name: "paintedHighlights")
    }

    func navigator(_ navigator: any SelectableNavigator, shouldShowMenuForSelection selection: Selection) -> Bool {
        !isPainting
    }

    private static let script = try! String(
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
        let (red, green, blue, alpha) = components
        return "rgba(\(Int(red * 255)), \(Int(green * 255)), \(Int(blue * 255)), \(alpha))"
    }

    fileprivate var hex: String {
        let (red, green, blue, _) = components
        return String(
            format: "#%02x%02x%02x", Int((red * 255).rounded()), Int((green * 255).rounded()),
            Int((blue * 255).rounded()))
    }

    private var components: (CGFloat, CGFloat, CGFloat, CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}
