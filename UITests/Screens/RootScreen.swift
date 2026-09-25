import XCTest

struct RootScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["root.placeholder"] }
}
