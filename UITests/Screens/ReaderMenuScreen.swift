import XCTest

struct ReaderMenuScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.buttons["readerMenu.contents"] }
    var entries: [XCUIElement] {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "readerMenu.")).allElementsBoundByIndex
    }
    var settingsItem: XCUIElement { app.buttons["readerMenu.settings"] }

    func item(_ tab: String) -> XCUIElement { app.buttons["readerMenu.\(tab)"] }

    func open(_ tab: String) -> ReaderIndexScreen {
        item(tab).waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return ReaderIndexScreen(app: app).waitUntilShown()
    }

    func openSettings() -> ReaderSettingsScreen {
        settingsItem.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return ReaderSettingsScreen(app: app).waitUntilShown()
    }

    func closeByTappingOutside() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
        root.waitUntilGone()
    }
}
