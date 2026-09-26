import XCTest

private let bookOpenTimeout: TimeInterval = 30

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
    var wordTint: XCUIElement { app.descendants(matching: .any)["reader.wordTint"] }
    var highlights: XCUIElement { app.descendants(matching: .any)["debug.highlights"] }
    var paintedHighlights: XCUIElement { app.descendants(matching: .any)["debug.paintedHighlights"] }
    var highlightMenuItem: XCUIElement { app.menuItems["Highlight"] }

    func theme(_ name: String) -> XCUIElement { app.buttons["reader.theme.\(name)"] }
    func pageTurn(_ name: String) -> XCUIElement { app.buttons["reader.pageTurn.\(name)"] }

    func paragraph(startingWith text: String) -> XCUIElement {
        app.webViews.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
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

    func openMenu() -> ReaderMenuScreen {
        menuButton.waitUntil(\.isHittable, equals: true).tap()
        return ReaderMenuScreen(app: app).waitUntilShown()
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

    func choosePageTurn(_ name: String) {
        showControls()
        pageTurn(name).tap()
        pageTurn(name).waitUntil(\.isSelected, equals: true)
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
}
