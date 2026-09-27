import XCTest

private let bookOpenTimeout: TimeInterval = 30
private let germanFirstParagraph = "Als Gregor Samsa"
private let germanFirstHeading = "Erster Teil"

struct ReaderScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.descendants(matching: .any)["reader.page"] }
    var runningHead: XCUIElement { app.staticTexts["reader.runningHead"] }
    var title: XCUIElement { app.staticTexts["reader.title"] }
    var subtitle: XCUIElement { app.staticTexts["reader.subtitle"] }
    var pageCounter: XCUIElement { app.staticTexts["reader.pageCounter"] }
    var backButton: XCUIElement { app.buttons["reader.back"] }
    var bookmarkButton: XCUIElement { app.buttons["reader.bookmark"] }
    var menuButton: XCUIElement { app.buttons["reader.menu"] }
    var failure: XCUIElement { app.staticTexts["reader.failure"] }
    var word: XCUIElement { app.staticTexts["reader.word"] }
    var sentence: XCUIElement { app.staticTexts["reader.sentence"] }
    var translation: XCUIElement { app.staticTexts["reader.translation"] }
    var translationRequests: XCUIElement { app.descendants(matching: .any)["debug.translationRequests"] }
    var wordTint: XCUIElement { app.descendants(matching: .any)["reader.wordTint"] }
    var highlights: XCUIElement { app.descendants(matching: .any)["debug.highlights"] }
    var paintedHighlights: XCUIElement { app.descendants(matching: .any)["debug.paintedHighlights"] }
    var paintedWordTints: XCUIElement { app.descendants(matching: .any)["debug.paintedWordTints"] }
    var bubble: XCUIElement { app.otherElements["reader.bubble"] }
    var bubbleWord: XCUIElement { app.staticTexts["reader.bubble.word"] }
    var bubbleIPA: XCUIElement { app.staticTexts["reader.bubble.ipa"] }
    var bubbleTranslation: XCUIElement { app.staticTexts["reader.bubble.translation"] }
    var bubbleGrammar: XCUIElement { app.staticTexts["reader.bubble.grammar"] }
    var bubbleLoading: XCUIElement { app.descendants(matching: .any)["reader.bubble.loading"] }
    var bubbleFailure: XCUIElement { app.staticTexts["reader.bubble.failure"] }
    var germanParagraph: XCUIElement { paragraph(startingWith: germanFirstParagraph) }
    var germanHeading: XCUIElement { paragraph(startingWith: germanFirstHeading) }
    var highlightMenuItem: XCUIElement { app.menuItems["Highlight"] }
    var appearance: XCUIElement { app.descendants(matching: .any)["debug.readerAppearance"] }
    var pageCurl: XCUIElement { app.descendants(matching: .any)["debug.pageCurl"] }

    func theme(_ name: String) -> XCUIElement { app.buttons["reader.theme.\(name)"] }

    func paragraph(startingWith text: String) -> XCUIElement {
        app.webViews.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
    }

    func wordPoint(onLine index: Int, x: CGFloat) throws -> XCUICoordinate {
        let line = try TokenValues.load().lineHeight("reading-body")
        return germanParagraph.waitUntilExists()
            .coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: x, dy: line * CGFloat(index) + line / 2))
    }

    func tapWord(onLine index: Int, x: CGFloat) throws {
        try wordPoint(onLine: index, x: x).tap()
    }

    @discardableResult
    func waitUntilOpened(file: StaticString = #filePath, line: UInt = #line) -> ReaderScreen {
        waitUntilShown(file: file, line: line)
        XCTAssertTrue(
            pageCounter.waitForExistence(timeout: bookOpenTimeout), "\(pageCounter.description) did not appear",
            file: file, line: line)
        return self
    }

    func showChrome() {
        tapMargin()
        backButton.waitUntil(\.isHittable, equals: true)
    }

    func hideChrome() {
        tapMargin()
        backButton.waitUntilGone()
    }

    @discardableResult
    func openMenu() -> ReaderMenuScreen {
        menuButton.waitUntil(\.isHittable, equals: true).tap()
        return ReaderMenuScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func openSettings() -> ReaderSettingsScreen {
        if !menuButton.exists {
            showChrome()
        }
        return openMenu().openSettings()
    }

    func toggleBookmark() {
        bookmarkButton.waitUntil(\.isEnabled, equals: true).tap()
    }

    @discardableResult
    func backToHome() -> HomeScreen {
        goBack()
        return HomeScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func backToLibrary() -> LibraryScreen {
        goBack()
        return LibraryScreen(app: app).waitUntilShown()
    }

    private func goBack() {
        if !backButton.exists {
            showChrome()
        }
        backButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
    }

    func tapMargin() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: 5, dy: 0)).tap()
    }

    func showControls() {
        tapMargin()
        theme("paper").waitUntil(\.isHittable, equals: true)
    }

    func hideControls() {
        tapMargin()
        theme("paper").waitUntilGone()
    }

    func chooseTheme(_ name: String) {
        showControls()
        theme(name).tap()
        theme(name).waitUntil(\.isSelected, equals: true)
        hideControls()
    }

    func turnForward(expecting counter: String, file: StaticString = #filePath, line: UInt = #line) {
        app.swipeLeft()
        pageCounter.waitUntil(\.label, equals: counter, file: file, line: line)
    }

    func turnBackward(expecting counter: String, file: StaticString = #filePath, line: UInt = #line) {
        app.swipeRight()
        pageCounter.waitUntil(\.label, equals: counter, file: file, line: line)
    }

    func turnForwardRightToLeft(expecting counter: String, file: StaticString = #filePath, line: UInt = #line) {
        app.swipeRight()
        pageCounter.waitUntil(\.label, equals: counter, file: file, line: line)
    }

    func turnBackwardRightToLeft(expecting counter: String, file: StaticString = #filePath, line: UInt = #line) {
        app.swipeLeft()
        pageCounter.waitUntil(\.label, equals: counter, file: file, line: line)
    }

    func curlForward(expecting counter: String, file: StaticString = #filePath, line: UInt = #line) {
        curl(from: curlRightSide, to: curlLeftSide, file: file, line: line)
        pageCounter.waitUntil(\.label, equals: counter, file: file, line: line)
    }

    func curlBackward(expecting counter: String, file: StaticString = #filePath, line: UInt = #line) {
        curl(from: curlLeftSide, to: curlRightSide, file: file, line: line)
        pageCounter.waitUntil(\.label, equals: counter, file: file, line: line)
    }

    func curlForwardRightToLeft(expecting counter: String, file: StaticString = #filePath, line: UInt = #line) {
        curl(from: curlLeftSide, to: curlRightSide, file: file, line: line)
        pageCounter.waitUntil(\.label, equals: counter, file: file, line: line)
    }

    func curlBackwardRightToLeft(expecting counter: String, file: StaticString = #filePath, line: UInt = #line) {
        curl(from: curlRightSide, to: curlLeftSide, file: file, line: line)
        pageCounter.waitUntil(\.label, equals: counter, file: file, line: line)
    }

    func curlBackwardDiagonally(file: StaticString = #filePath, line: UInt = #line) {
        curl(from: CGVector(dx: 0.2, dy: 0.35), to: CGVector(dx: 0.75, dy: 0.65), file: file, line: line)
    }

    func curlAndRelease(file: StaticString = #filePath, line: UInt = #line) {
        pageCurl.waitUntil(\.label, equals: "ready", file: file, line: line)
        pagePoint(curlRightSide)
            .press(
                forDuration: curlPressDuration, thenDragTo: pagePoint(CGVector(dx: 0.65, dy: 0.5)),
                withVelocity: .slow, thenHoldForDuration: 0.5)
    }

    private var curlRightSide: CGVector { CGVector(dx: 0.8, dy: 0.5) }
    private var curlLeftSide: CGVector { CGVector(dx: 0.2, dy: 0.5) }
    private var curlPressDuration: TimeInterval { 0.05 }

    private func curl(from start: CGVector, to end: CGVector, file: StaticString, line: UInt) {
        pageCurl.waitUntil(\.label, equals: "ready", file: file, line: line)
        pagePoint(start)
            .press(
                forDuration: curlPressDuration, thenDragTo: pagePoint(end), withVelocity: .fast,
                thenHoldForDuration: 0)
    }

    private func pagePoint(_ offset: CGVector) -> XCUICoordinate {
        root.coordinate(withNormalizedOffset: offset)
    }
}
