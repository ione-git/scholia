import XCTest

struct NotificationsOffScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.alerts.containing(.button, identifier: "notificationsOff.notNow").firstMatch }

    var notNowButton: XCUIElement { root.buttons["notificationsOff.notNow"].firstMatch }

    var openSettingsButton: XCUIElement { root.buttons["notificationsOff.openSettings"].firstMatch }

    @discardableResult
    func notNow() -> SettingsScreen {
        notNowButton.waitUntil(\.isHittable, equals: true).tap()
        root.waitUntilGone()
        return SettingsScreen(app: app).waitUntilShown()
    }

    func openSettings() {
        openSettingsButton.waitUntil(\.isHittable, equals: true).tap()
    }
}
