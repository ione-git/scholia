import XCTest

struct SpringboardScreen: Screen {
    let app = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    var root: XCUIElement { appIcon }

    var appIcon: XCUIElement { app.icons["Scholia"] }

    var dock: XCUIElement { app.otherElements["Dock"] }

    var editButton: XCUIElement { app.buttons["Edit"] }

    var customizeButton: XCUIElement { app.buttons["Customize"] }

    func scrollToAppIcon() -> XCUIElement {
        if !appIcon.isHittable {
            app.swipeLeft()
        }
        return appIcon.waitUntil(\.isHittable, equals: true)
    }

    @discardableResult
    func customizeIcons(_ options: String...) -> Self {
        dock.waitUntilExists().coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).press(forDuration: 1.5)
        editButton.waitUntilExists().tap()
        customizeButton.waitUntilExists().tap()
        for option in options {
            app.buttons[option].waitUntil(\.isHittable, equals: true).tap()
            app.buttons[option].waitUntil(\.isSelected, equals: true)
        }
        XCUIDevice.shared.press(.home)
        editButton.waitUntilGone()
        return self
    }
}
