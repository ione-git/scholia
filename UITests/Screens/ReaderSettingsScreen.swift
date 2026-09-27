import XCTest

struct ReaderSettingsScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.descendants(matching: .any)["readerSettings.sheet"] }
}
