import ReadiumNavigator
import ReadiumShared
import UIKit
import WebKit

final class ReaderViewController: UIViewController {
    weak var controller: ReaderController?
    private(set) var appearance: ReaderAppearance
    private let book: ReaderBook
    private let language: String?
    private let typefaces: [ReaderTypeface]
    private var navigator: EPUBNavigatorViewController
    private var restoreLocation: ReaderLocation?
    private var jumpTarget: ReaderJump?
    private var landing: Landing?
    private let backdrop = UIView()
    private let curtain = UIView()
    private var cover: UIView?
    private var swipes: [UISwipeGestureRecognizer] = []
    private var press: UILongPressGestureRecognizer?
    private var pageCurl: PageCurl?
    private var neighbours: NeighbourPages?
    private var highlightDecorations: [Decoration] = []
    private var isCommittingCurl = false
    private var pressOrigin: CGPoint?
    private var isPressing = false
    private var isPainting = false
    private var isTurning = false
    private var isShowing = false
    private var isShown = false
    private var showWaiters: [CheckedContinuation<Void, Never>] = []
    private var generation = 0
    private var epoch = 0
    private var applyTask: Task<Void, Never>?
    private weak var pager: UIScrollView?
    private weak var selectionWebView: WKWebView?
    private var pageSelection: ReaderSelection?
    private var observations: [ScrollObservation] = []
    private var shownPage: ChapterPage?
    private var laidOutSize: CGSize?
    private var tapGeneration = 0
    private var pageCounts: [PageCount]?
    private var countedLayout: PageLayout?
    private var pageCounter: PageCounter?
    private var countTask: Task<Void, Never>?
    private var locateTask: Task<Void, Never>?
    private var turnTask: Task<Void, Never>?
    private var jumpTask: Task<Void, Never>?
    private var selectionTask: Task<Void, Never>?
    private var voiceOverTask: Task<Void, Never>?

    static let highlightGroup = "highlights"
    private static let wordGroup = "word"
    private static let wordDecoration = "word"
    private static let cssFontWeights = 1...1000
    private static let revealDuration: TimeInterval = 0.25
    private static let fadeDuration: TimeInterval = 0.2
    private static let scrollSettleDelay = Duration.milliseconds(150)
    static let renderTimeout = 1000

    init(
        book: ReaderBook, language: String?, location: ReaderLocation?, appearance: ReaderAppearance,
        typefaces: [ReaderTypeface]
    ) {
        self.book = book
        self.language = language
        self.appearance = appearance
        self.typefaces = typefaces
        restoreLocation = location
        navigator = Self.navigator(
            book: book, location: location,
            configuration: Self.configuration(appearance: appearance, typefaces: typefaces))
        super.init(nibName: nil, bundle: nil)
        configure(navigator)
    }

    isolated deinit {
        applyTask?.cancel()
        countTask?.cancel()
        locateTask?.cancel()
        turnTask?.cancel()
        jumpTask?.cancel()
        selectionTask?.cancel()
        voiceOverTask?.cancel()
        neighbours?.cancel()
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
        self.press = press

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
        if view.bounds.size != laidOutSize {
            laidOutSize = view.bounds.size
            clearWord()
            clearSelection()
            stopNeighbours()
        }
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
            self?.controller?.onHighlight?(range)
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
        guard controller?.selection != nil, let webView = selectionWebView else {
            return nil
        }
        pageSelection = nil
        publishSelection()
        return webView
    }

    private func publishSelection() {
        let shown = isPressing || isPainting ? nil : pageSelection
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
            if webView === selectionWebView {
                pageSelection = nil
                publishSelection()
            }
            return
        }
        guard let text = found["text"] as? String, let rect = rect(found, in: webView) else {
            return
        }
        selectionWebView = webView
        pageSelection = ReaderSelection(text: text, rect: rect)
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
                        id: .wordTap, config: Decoration.Style.HighlightConfig(tint: appearance.colors.wordTap)))
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
        highlightDecorations = decorations
        stopNeighbours()
        settleCurl()
    }

    func go(to target: ReaderJump) {
        jumpTarget = target
        jump()
    }

    private func render(_ target: ReaderAppearance, generation current: Int) async {
        defer {
            if current == generation, !Task.isCancelled {
                revealCover()
            }
        }
        guard current == generation, !Task.isCancelled, target != appearance else {
            return
        }
        let restore = controller?.location ?? restoreLocation
        let changesLayout =
            !isShown || layoutStyle(appearance) != layoutStyle(target) || isScrolled(appearance) != isScrolled(target)
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
            stopNeighbours()
            applyGestures()
            settleCurl()
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
            configuration: Self.configuration(appearance: target, typefaces: typefaces))
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
        jumpTask?.cancel()
        stopNeighbours()
        isShown = false
        shownPage = nil
        pageCounts = nil
        countedLayout = nil
        clearWord()
        clearSelection()
        controller?.pageSpan = nil
        controller?.page = nil
    }

    private func recolor() {
        backdrop.backgroundColor = appearance.colors.page
        curtain.backgroundColor = appearance.colors.page
        view.tintColor = appearance.colors.selection
        paintWord()
    }

    private func applyGestures() {
        let isScrolled = navigator.presentation.scroll
        for swipe in swipes {
            swipe.isEnabled = !isScrolled && appearance.pageTurn == .fade
        }
        let curls = !isScrolled && appearance.pageTurn == .curl
        if curls, pageCurl == nil {
            startCurl()
        } else if !curls, pageCurl != nil {
            stopCurl()
        }
        for scrollView in navigator.view.descendants(of: UIScrollView.self) {
            scrollView.panGestureRecognizer.isEnabled = isScrolled || appearance.pageTurn == .slide
        }
    }

    private func startCurl() {
        let curl = PageCurl(isRightToLeft: navigator.presentation.readingProgression == .rtl)
        guard let pan = curl.pan else {
            return
        }
        curl.allowsCurl = { [weak self] pan in
            self?.allowsCurl(pan) ?? false
        }
        curl.onBegin = { [weak self] in
            self?.clearWord()
            self?.publishCurl()
        }
        curl.onEnd = { [weak self] forward, completed in
            self?.curlEnded(forward: forward, completed: completed)
        }
        addChild(curl.controller)
        curl.controller.view.frame = view.bounds
        curl.controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(curl.controller.view, aboveSubview: navigator.view)
        curl.controller.didMove(toParent: self)
        view.addGestureRecognizer(pan)
        pageCurl = curl
        settleCurl()
    }

    private func stopCurl() {
        stopNeighbours()
        guard let pageCurl else {
            return
        }
        if let pan = pageCurl.pan {
            view.removeGestureRecognizer(pan)
        }
        pageCurl.controller.willMove(toParent: nil)
        pageCurl.controller.view.removeFromSuperview()
        pageCurl.controller.removeFromParent()
        self.pageCurl = nil
        publishCurl()
    }

    private func settleCurl() {
        guard let pageCurl, !pageCurl.isCurling, !isCommittingCurl, isShown, let shownPage else {
            refreshCurl()
            return
        }
        if neighbours == nil {
            let neighbours = NeighbourPages(
                book: book, appearance: appearance,
                configuration: Self.configuration(appearance: appearance, typefaces: typefaces),
                decorations: highlightDecorations, host: self,
                contentInset: { [weak self] in self?.contentInset ?? .zero })
            neighbours.onChange = { [weak self] in self?.refreshCurl() }
            self.neighbours = neighbours
        }
        neighbours?.show(shownPage)
        refreshCurl()
    }

    private func stopNeighbours() {
        neighbours?.stop()
        neighbours = nil
        pageCurl?.unstage()
        refreshCurl()
    }

    private func refreshCurl() {
        if let pageCurl, let neighbours, let shownPage, isShown, neighbours.page == shownPage, neighbours.isReady,
            !pageCurl.isCurling, !isCommittingCurl
        {
            pageCurl.stage(neighbours, color: appearance.colors.page)
        }
        publishCurl()
    }

    private func allowsCurl(_ pan: UIPanGestureRecognizer) -> Bool {
        guard
            let pageCurl, let neighbours, isCurlReady, !isPainting, navigator.currentSelection == nil,
            press?.state != .began, press?.state != .changed
        else {
            return false
        }
        let translation = pan.translation(in: view).x
        let distance = translation != 0 ? translation : pan.velocity(in: view).x
        guard distance != 0 else {
            return false
        }
        let forward = (distance < 0) != (navigator.presentation.readingProgression == .rtl)
        guard (forward ? neighbours.next : neighbours.previous) != .end else {
            return false
        }
        pageCurl.reveal()
        return true
    }

    private func curlEnded(forward: Bool, completed: Bool) {
        guard completed else {
            pageCurl?.rest()
            #if DEBUG
                controller?.pageCurl.cancelled += 1
            #endif
            refreshCurl()
            return
        }
        isCommittingCurl = true
        let navigator = navigator
        let epoch = epoch
        turnTask = Task {
            var isTurned = false
            defer {
                pageCurl?.rest()
                isCommittingCurl = false
                #if DEBUG
                    if isTurned {
                        controller?.pageCurl.completed += 1
                    }
                #endif
                settleCurl()
            }
            let options = NavigatorGoOptions(animated: false)
            let moved =
                forward ? await navigator.goForward(options: options) : await navigator.goBackward(options: options)
            guard moved, !Task.isCancelled, epoch == self.epoch else {
                return
            }
            await waitUntilRendered()
            guard !Task.isCancelled, epoch == self.epoch else {
                return
            }
            trackPage()
            isTurned = true
        }
    }

    private var isCurlReady: Bool {
        guard let pageCurl, let neighbours, let shownPage else {
            return false
        }
        return isShown && neighbours.page == shownPage && neighbours.isReady && !pageCurl.isCurling
            && !isCommittingCurl && pageCurl.isStaged(neighbours, color: appearance.colors.page)
    }

    private func publishCurl() {
        #if DEBUG
            let state: ReaderPageCurl.State = pageCurl == nil ? .off : isCurlReady ? .ready : .preparing
            if controller?.pageCurl.state != state {
                controller?.pageCurl.state = state
            }
        #endif
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
        _ = try? await webView.callAsyncJavaScript(
            "return await scholia.rendered(expected, timeout)",
            arguments: ["expected": Self.renderedStyle(appearance), "timeout": Self.renderTimeout],
            contentWorld: .page)
    }

    static func renderedStyle(_ appearance: ReaderAppearance) -> [String: Any] {
        [
            "background": appearance.colors.page.hex, "text": appearance.colors.text.hex,
            "fontFamily": appearance.style.font.family,
        ]
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
            observations.append(ScrollObservation(pager, keyPath: \.contentOffset) { [weak self] in self?.pageMoved() })
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
        jump()
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
        visibleChapter() == chapter
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
        clearWord()
        controller?.pageSpan = nil
        publishPage()
        locate(page)
        settleCurl()
    }

    private func currentPage() -> ChapterPage? {
        guard let chapter = visibleChapter(), let scrollView = webView(inChapter: chapter)?.scrollView else {
            return nil
        }
        observe(scrollView)
        if navigator.presentation.scroll {
            return ChapterPage(chapter: chapter, page: scrolledPage(in: scrollView, chapter: chapter))
        }
        let width = scrollView.bounds.width
        guard width > 0, scrollView.contentSize.width >= width else {
            return nil
        }
        let count = Int((scrollView.contentSize.width / width).rounded())
        let page = Int((distanceFromStart(of: scrollView.bounds, in: scrollView) / width).rounded())
        return ChapterPage(chapter: chapter, page: min(max(page, 0), count - 1))
    }

    private func scrolledPage(in scrollView: UIScrollView, chapter: Int) -> Int {
        guard let pageCounts, pageCounts.indices.contains(chapter) else {
            return 0
        }
        let inset = scrollView.adjustedContentInset
        let scrollable = scrollView.contentSize.height + inset.top + inset.bottom - scrollView.bounds.height
        guard scrollable > 0 else {
            return 0
        }
        let fraction = (scrollView.contentOffset.y + inset.top) / scrollable
        return min(max(Int(fraction * CGFloat(pageCounts[chapter].pages)), 0), pageCounts[chapter].pages - 1)
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
            ScrollObservation(scrollView, keyPath: \.contentOffset) { [weak self] in self?.pageMoved() })
        observations.append(ScrollObservation(scrollView, keyPath: \.contentSize) { [weak self] in self?.trackPage() })
    }

    private func pageMoved() {
        clearWord()
        if !isPainting, pageSelection != nil {
            clearSelection()
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
        let key = PageCountCache.key(book: book, style: appearance.style, size: layout.size)
        pageCounts = PageCountCache.counts(for: key)
        shownPage = nil
        controller?.pageSpan = nil
        publishPage()
        trackPage()
        guard pageCounts == nil else {
            return
        }
        var paged = appearance
        paged.pageTurn = .slide
        let counter = PageCounter(
            book: book, configuration: Self.configuration(appearance: paged, typefaces: typefaces),
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
            if navigator.presentation.scroll {
                shownPage = currentPage()
            }
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
        tapGeneration += 1
        let tap = tapGeneration
        let isShowingWord = controller?.word != nil
        let word = await word(at: point)
        guard tap == tapGeneration else {
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

    @objc private func pressed(_ press: UILongPressGestureRecognizer) {
        let location = press.location(in: view)
        switch press.state {
        case .began:
            pressOrigin = location
            isPressing = true
            publishSelection()
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
            isPressing = false
            paintSelection()
        default:
            isPressing = false
            stopPainting()
            publishSelection()
        }
    }

    private func paintSelection() {
        pageSelection = nil
        guard let webView = selectionWebView ?? pressOrigin.flatMap(webView(at:)) else {
            stopPainting()
            return
        }
        selectionTask?.cancel()
        selectionTask = Task { [weak self] in
            let range = await self?.takeSelection(in: webView)?.range
            guard let self else {
                return
            }
            stopPainting()
            if let range {
                controller?.onHighlight?(range)
            }
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
        clearWord()
        clearSelection()
        let forward = (swipe.direction == .left) == (navigator.presentation.readingProgression != .rtl)
        turnTask = Task {
            await fade(forward: forward)
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

    static func navigator(
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

    private static func configuration(appearance: ReaderAppearance, typefaces: [ReaderTypeface])
        -> EPUBNavigatorViewController.Configuration
    {
        let style = appearance.style
        return EPUBNavigatorViewController.Configuration(
            preferences: preferences(appearance),
            editingActions: [],
            decorationTemplates: [
                .highlight: tintTemplate(className: "scholia-highlight", radius: style.highlightRadius),
                .wordTap: tintTemplate(className: "scholia-word-tap", radius: style.highlightRadius),
            ],
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
        applyGestures()
        guard viewport != nil else {
            return
        }
        if isShown {
            trackPage()
            jump()
        } else {
            let epoch = epoch
            Task {
                guard epoch == self.epoch else {
                    return
                }
                await show()
            }
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
        userContentController.add(SelectionMessages(viewController: self), name: "scholiaSelection")
    }

    func navigator(_ navigator: any SelectableNavigator, shouldShowMenuForSelection selection: Selection) -> Bool {
        false
    }

    static let script = try! String(
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

struct ChapterPage: Hashable {
    var chapter: Int
    var page: Int
}

private struct PageLayout: Equatable {
    var size: CGSize
    var isScrolled: Bool
}

struct ScrollObservation {
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
    func descendants<T: UIView>(of type: T.Type) -> [T] {
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
