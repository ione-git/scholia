import XCTest

struct FilePickerScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.tabBars.buttons["Browse"] }
}
