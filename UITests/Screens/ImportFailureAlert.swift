import XCTest

struct ImportFailureAlert: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.alerts.firstMatch }

    var messages: [String] { root.staticTexts.allElementsBoundByIndex.map(\.label) }
    var okButton: XCUIElement { root.buttons.firstMatch }

    @discardableResult
    func dismiss() -> HomeScreen {
        okButton.waitUntilExists().tap()
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }
}
