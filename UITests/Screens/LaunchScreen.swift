import XCTest

struct LaunchScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { glyph }

    var glyph: XCUIElement { app.images["launchScreen.glyph"] }

    func background() throws -> RGBColor {
        try app.screenshot().color(at: CGPoint(x: 0.5, y: 0.1))
    }
}
