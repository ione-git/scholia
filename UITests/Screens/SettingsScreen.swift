import XCTest

struct SettingsScreen: Screen {
    let app: XCUIApplication

    var root: XCUIElement { app.staticTexts["settings.title"] }

    var backButton: XCUIElement { app.buttons["settings.back"] }
    var translateTo: XCUIElement { app.buttons["settings.translateTo"] }
    var dailyGoal: XCUIElement { app.buttons["settings.dailyGoal"] }
    var reminder: XCUIElement { app.switches["settings.reminder"] }
    var reminderTime: XCUIElement { app.buttons["settings.reminderTime"] }
    var sortBooks: XCUIElement { app.buttons["settings.sortBooks"] }
    var version: XCUIElement { app.staticTexts["settings.version"] }

    func onWordTap(_ style: String) -> XCUIElement { app.buttons["settings.onWordTap.\(style)"] }

    func theme(_ theme: String) -> XCUIElement { app.buttons["settings.theme.\(theme)"] }

    func chooseTranslationLanguage(_ identifier: String) {
        choose("settings.translateTo.\(identifier)", from: translateTo)
    }

    func chooseDailyGoal(_ minutes: Int) {
        choose("settings.dailyGoal.\(minutes)", from: dailyGoal)
    }

    func chooseSortOrder(_ order: String) {
        choose("settings.sortBooks.\(order)", from: sortBooks)
    }

    func openReminderTime() -> ReminderTimeScreen {
        reminderTime.waitUntil(\.isHittable, equals: true).tap()
        return ReminderTimeScreen(app: app).waitUntilShown()
    }

    func turnOnReminder() {
        let asksPermission = readingReminder.waitUntilExists().value as? String == "notDetermined"
        reminder.waitUntil(\.isHittable, equals: true).tap()
        if asksPermission {
            NotificationPermissionScreen().waitUntilShown().allow()
        }
        reminder.waitUntil(\.isOn, equals: true)
    }

    func turnOffReminder() {
        reminder.waitUntil(\.isHittable, equals: true).tap()
        reminder.waitUntil(\.isOn, equals: false)
    }

    func background() throws -> RGBColor {
        try app.screenshot().color(at: CGPoint(x: 0.02, y: 0.9))
    }

    @discardableResult
    func goBack() -> HomeScreen {
        backButton.waitUntilExists().tap()
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }

    private func choose(_ item: String, from menu: XCUIElement) {
        menu.waitUntil(\.isHittable, equals: true).tap()
        let button = app.buttons[item]
        button.waitUntil(\.isHittable, equals: true).tap()
        button.waitUntilGone()
    }
}
