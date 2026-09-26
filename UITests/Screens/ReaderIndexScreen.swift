import XCTest

struct ReaderIndexScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.buttons["readerIndex.done"] }
    var title: XCUIElement { app.staticTexts["readerIndex.title"] }
    var subtitle: XCUIElement { app.staticTexts["readerIndex.subtitle"] }

    var chapters: [XCUIElement] {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "readerIndex.chapter."))
            .allElementsBoundByIndex
    }

    func tab(_ name: String) -> XCUIElement { app.buttons["readerIndex.tab.\(name)"] }

    func chapter(at index: Int) -> XCUIElement { app.buttons["readerIndex.chapter.\(index)"] }

    @discardableResult
    func waitUntilStartPagesShown(file: StaticString = #filePath, line: UInt = #line) -> ReaderIndexScreen {
        chapter(at: 0).waitUntil(\.stringValue, equals: "Page 1", file: file, line: line)
        return self
    }

    @discardableResult
    func jump(toChapterAt index: Int) -> ReaderScreen {
        chapter(at: index).waitUntil(\.isHittable, equals: true).tap()
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
