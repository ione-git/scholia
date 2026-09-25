import XCTest

struct LaunchScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { glyph }

    var glyph: XCUIElement { app.images["launchScreen.glyph"] }
}
