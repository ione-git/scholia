import XCTest

struct FilePickerScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.tabBars.buttons["Browse"] }

    var cancelButton: XCUIElement { app.navigationBars.buttons["Cancel"] }

    @discardableResult
    func cancel() -> HomeScreen {
        cancelButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }
}
