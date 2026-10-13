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
    var translationLanguages: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "settings.translateTo."))
    }

    func onWordTap(_ style: String) -> XCUIElement { app.buttons["settings.onWordTap.\(style)"] }

    func chooseOnWordTap(_ style: String) {
        onWordTap(style).waitUntil(\.isHittable, equals: true).tap()
        onWordTap(style).waitUntil(\.isSelected, equals: true)
    }

    func theme(_ theme: String) -> XCUIElement { app.buttons["settings.theme.\(theme)"] }

    func chooseWordTapStyle(_ style: String) {
        select(onWordTap(style))
    }

    func chooseTheme(_ name: String) {
        select(theme(name))
    }

    func openTranslationLanguages() {
        translateTo.waitUntil(\.isHittable, equals: true).tap()
        translationLanguages.firstMatch.waitUntil(\.isHittable, equals: true)
    }

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
            let prompt = NotificationPermissionScreen().waitUntilShown()
            prompt.root.waitUntil(\.label, equals: "“Scholia” Would Like to Send You Notifications")
            prompt.allow()
        }
        reminder.waitUntil(\.isOn, equals: true)
    }

    func tapReminder() {
        reminder.waitUntil(\.isHittable, equals: true).tap()
    }

    func turnOffReminder() {
        reminder.waitUntil(\.isHittable, equals: true).tap()
        reminder.waitUntil(\.isOn, equals: false)
    }

    @discardableResult
    func goBack() -> HomeScreen {
        backButton.waitUntilExists().tap()
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }

    @discardableResult
    func swipeBack() -> HomeScreen {
        root.waitUntil(\.isHittable, equals: true)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        root.waitUntilGone()
        return HomeScreen(app: app).waitUntilShown()
    }

    func cancelBackSwipe() {
        root.waitUntil(\.isHittable, equals: true)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.5)
    }

    func dragWordTap(from: String, to: String) {
        drag(from: onWordTap(from), to: onWordTap(to))
    }

    func dragTheme(from: String, to: String) {
        drag(from: theme(from), to: theme(to))
    }

    private func drag(from start: XCUIElement, to end: XCUIElement) {
        start.waitUntil(\.isHittable, equals: true)
        end.waitUntil(\.isHittable, equals: true)
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    private func select(_ segment: XCUIElement) {
        segment.waitUntil(\.isHittable, equals: true).tap()
        segment.waitUntil(\.isSelected, equals: true)
    }

    private func choose(_ item: String, from menu: XCUIElement) {
        menu.waitUntil(\.isHittable, equals: true).tap()
        let button = app.buttons[item]
        button.waitUntil(\.isHittable, equals: true).tap()
        button.waitUntilGone()
    }
}
