import XCTest

struct ReaderIndexScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.buttons["readerIndex.done"] }
    var title: XCUIElement { app.staticTexts["readerIndex.title"] }
    var subtitle: XCUIElement { app.staticTexts["readerIndex.subtitle"] }

    var chapters: [XCUIElement] { chapterRows.allElementsBoundByIndex }

    private var chapterRows: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "readerIndex.chapter."))
    }

    func tab(_ name: String) -> XCUIElement { app.buttons["readerIndex.tab.\(name)"] }

    func chapter(_ title: String) -> XCUIElement { app.buttons["readerIndex.chapter.\(title)"] }

    @discardableResult
    func waitUntilStartPagesShown(file: StaticString = #filePath, line: UInt = #line) -> ReaderIndexScreen {
        chapterRows.firstMatch.waitUntil(\.stringValue, equals: "Page 1", file: file, line: line)
        return self
    }

    @discardableResult
    func jump(to title: String) -> ReaderScreen {
        chapter(title).waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return ReaderScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func done() -> ReaderScreen {
        root.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return ReaderScreen(app: app).waitUntilShown()
    }
}
