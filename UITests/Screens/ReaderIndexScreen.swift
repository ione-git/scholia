import XCTest

struct ReaderIndexScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.buttons["readerIndex.done"] }
    var title: XCUIElement { app.staticTexts["readerIndex.title"] }
    var subtitle: XCUIElement { app.staticTexts["readerIndex.subtitle"] }

    func tab(_ name: String) -> XCUIElement { app.buttons["readerIndex.tab.\(name)"] }

    @discardableResult
    func done() -> ReaderScreen {
        root.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return ReaderScreen(app: app).waitUntilShown()
    }
}
