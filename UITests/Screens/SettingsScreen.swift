import XCTest

struct SettingsScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["settings.title"] }

    @discardableResult
    func goBack() -> HomeScreen {
        app.navigationBars.buttons["BackButton"].waitUntilExists().tap()
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }
}
