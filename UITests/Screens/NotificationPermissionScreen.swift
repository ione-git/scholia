import XCTest

struct NotificationPermissionScreen: Screen {
    let app = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    var root: XCUIElement { app.alerts.firstMatch }

    var allowButton: XCUIElement { root.buttons["Allow"] }

    func allow() {
        allowButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
    }
}
