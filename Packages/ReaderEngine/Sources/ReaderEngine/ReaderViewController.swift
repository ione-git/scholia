import ReadiumNavigator
import ReadiumShared
import UIKit
import WebKit

final class ReaderViewController: UIViewController {
    weak var controller: ReaderController?
    private let book: ReaderBook
    private let style: ReaderStyle
    private let navigator: EPUBNavigatorViewController
    private var colors: ReaderColors
    private var pageTurn: ReaderPageTurn
    private var swipes: [UISwipeGestureRecognizer] = []
    private var pressOrigin: CGPoint?
    private var isPainting = false
    private var isCurling = false

    private static let highlightGroup = "highlights"
    private static let cssFontWeights = 1...1000

    init(book: ReaderBook, style: ReaderStyle, colors: ReaderColors, pageTurn: ReaderPageTurn, highlightTitle: String) {
        self.book = book
        self.style = style
        self.colors = colors
        self.pageTurn = pageTurn
        navigator = try! EPUBNavigatorViewController(
            publication: book.publication,
            initialLocation: nil,
            config: .init(
                preferences: Self.preferences(style: style, colors: colors),
                editingActions: [EditingAction(title: highlightTitle, action: #selector(highlightSelection)), .copy],
                decorationTemplates: [.highlight: Self.highlightTemplate(radius: style.highlightRadius)],
                fontFamilyDeclarations: [Self.fontDeclaration(style.font)],
                readiumCSSRSProperties: CSSRSProperties(
                    pageGutter: CSSPxLength(style.sideMargin),
                    baseLineHeight: .length(CSSPxLength(style.lineHeight)),
                    overrides: ["font-size": CSSPxLength(style.fontSize).css()]
                )
            )
        )
        super.init(nibName: nil, bundle: nil)
        navigator.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = colors.page
        view.tintColor = colors.selection
        addChild(navigator)
        navigator.view.frame = view.bounds
        navigator.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(navigator.view)
        navigator.didMove(toParent: self)
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
    }

    func apply(_ colors: ReaderColors) {
        self.colors = colors
        view.backgroundColor = colors.page
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

    func apply(_ pageTurn: ReaderPageTurn) {
        self.pageTurn = pageTurn
        for swipe in swipes {
            swipe.isEnabled = pageTurn == .curl
        }
        for scrollView in navigator.view.descendants(of: UIScrollView.self) {
            scrollView.panGestureRecognizer.isEnabled = pageTurn == .slide
        }
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

    private func updatePage(_ viewport: NavigatorViewport?) {
        apply(pageTurn)
        guard let resource = viewport?.resources.first else {
            return
        }
        let visible = resource.progression.upperBound - resource.progression.lowerBound
        guard visible > 0 else {
            return
        }
        let page = ReaderPage(
            location: ReaderLocation(chapter: resource.href.string, progression: resource.progression.lowerBound),
            number: Int((resource.progression.lowerBound / visible).rounded()) + 1,
            count: Int((1 / visible).rounded())
        )
        if page.location != controller?.page?.location {
            controller?.word = nil
        }
        controller?.page = page
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
        updatePage(viewport)
    }

    func navigatorContentInset(_ navigator: any VisualNavigator) -> UIEdgeInsets? {
        let available = view.bounds.height - style.topMargin - style.minimumBottomMargin
        let lines = (available / style.lineHeight).rounded(.down)
        return UIEdgeInsets(
            top: style.topMargin, left: 0, bottom: view.bounds.height - style.topMargin - lines * style.lineHeight,
            right: 0)
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
