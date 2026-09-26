import XCTest

struct ImportFailureAlert: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.alerts.firstMatch }

    var messages: [String] { root.staticTexts.allElementsBoundByIndex.map(\.label) }
    var okButton: XCUIElement { root.buttons.firstMatch }

    @discardableResult
    func dismiss() -> HomeScreen {
        dismiss(to: HomeScreen(app: app))
    }

    @discardableResult
    func dismiss<Next: Screen>(to next: Next) -> Next {
        okButton.waitUntilExists().tap()
        root.waitUntilGone()
        return next.waitUntilShown()
    }
}
