import XCTest

struct SpringboardScreen: Screen {
    let app = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    var root: XCUIElement { appIcon }

    var appIcon: XCUIElement { app.icons["Scholia"] }

    func scrollToAppIcon() -> XCUIElement {
        if !appIcon.isHittable {
            app.swipeLeft()
        }
        return appIcon.waitUntil(\.isHittable, equals: true)
    }
}
