import XCTest

struct RemoveBooksDialog: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.sheets.firstMatch }

    var texts: [String] { root.staticTexts.allElementsBoundByIndex.map(\.label) }
    var removeButton: XCUIElement { root.buttons["removeBooks.remove"].firstMatch }
    var dismissRegion: XCUIElement { app.otherElements["PopoverDismissRegion"] }

    @discardableResult
    func remove() -> LibraryScreen {
        removeButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return LibraryScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func cancel<Next: Screen>(returningTo next: Next) -> Next {
        dismissRegion.waitUntilExists().coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        root.waitUntilGone()
        return next.waitUntilShown()
    }
}
