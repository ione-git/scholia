import XCTest

struct GoalPopoverScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.descendants(matching: .any)["goal.summary"] }

    var dismissRegion: XCUIElement { app.descendants(matching: .any)["PopoverDismissRegion"] }

    @discardableResult
    func dismiss() -> HomeScreen {
        dismissRegion.waitUntilExists().tap()
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }
}
