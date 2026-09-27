import XCTest

private let reminder = "reading-reminder · Time to read · Pick up where you left off."

final class ReminderTests: UITestCase {
    func testTurningOnSchedulesDailyReminder() {
        let settings = openSettings(launch(.withoutBooks))

        settings.turnOnReminder()

        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:00 · repeats")
        XCTAssertEqual(settings.readingReminder.value as? String, "authorized")
    }

    func testDecliningPermissionLeavesReminderOff() {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.notificationPermission = .declined
        let settings = openSettings(launch(configuration))
        settings.readingReminder.waitUntil(\.label, equals: "none")

        settings.tapReminder()

        settings.reminder.waitUntil(\.isOn, equals: false)
        XCTAssertFalse(NotificationsOffScreen(app: settings.app).root.exists)
        settings.readingReminder.waitUntil(\.label, equals: "none")
    }

    func testDeniedPermissionShowsNotificationsOffAlert() {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.notificationPermission = .denied
        let settings = openSettings(launch(configuration))
        settings.readingReminder.waitUntil(\.label, equals: "none")

        settings.tapReminder()

        let alert = NotificationsOffScreen(app: settings.app).waitUntilShown()
        XCTAssertEqual(alert.root.label, "Notifications are off")
        alert.notNow()
        settings.reminder.waitUntil(\.isOn, equals: false)
        settings.readingReminder.waitUntil(\.label, equals: "none")
    }

    func testNotificationsOffAlertOpensSettings() {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.notificationPermission = .denied
        let settings = openSettings(launch(configuration))
        settings.tapReminder()

        NotificationsOffScreen(app: settings.app).waitUntilShown().openSettings()

        XCTAssertTrue(
            XCUIApplication(bundleIdentifier: "com.apple.Preferences").wait(for: .runningForeground, timeout: timeout))
    }

    func testTurningOffCancelsReminder() {
        let settings = openSettings(launch(.withoutBooks))
        settings.turnOnReminder()
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:00 · repeats")

        settings.turnOffReminder()

        settings.readingReminder.waitUntil(\.label, equals: "none")
    }

    func testChangingTimeReschedulesReminder() throws {
        let settings = openSettings(launch(.withoutBooks))
        settings.turnOnReminder()

        settings.openReminderTime().setMinute("30").close()

        settings.reminderTime.waitUntil(\.label, equals: try reminderLabel(hour: 21, minute: 30))
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:30 · repeats")
        XCTAssertTrue(settings.reminder.isOn)
    }

    func testToggleAndTimePersistAcrossRelaunch() throws {
        var settings = openSettings(launch(.withoutBooks))
        settings.openReminderTime().setMinute("45").close()
        settings.reminderTime.waitUntil(\.label, equals: try reminderLabel(hour: 21, minute: 45))
        settings.turnOnReminder()
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:45 · repeats")
        settings.app.terminate()

        var relaunch = LaunchConfiguration.withoutBooks
        relaunch.resetsState = false
        settings = openSettings(launch(relaunch))

        settings.reminderTime.waitUntil(\.label, equals: try reminderLabel(hour: 21, minute: 45))
        settings.reminder.waitUntil(\.isOn, equals: true)
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:45 · repeats")
    }

    func testSettingsReminderTimeSnapshotLight() {
        assertSnapshot(of: openReminderTime(appearance: .light), named: "Settings-ReminderTime")
    }

    func testSettingsReminderTimeSnapshotDark() {
        assertSnapshot(of: openReminderTime(appearance: .dark), named: "Settings-ReminderTime")
    }

    private func openReminderTime(appearance: XCUIDevice.Appearance) -> ReminderTimeScreen {
        openSettings(launch(.withoutBooks, appearance: appearance)).openReminderTime()
    }

    private func reminderLabel(hour: Int, minute: Int) throws -> String {
        let time = try XCTUnwrap(Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now))
        return "Reminder at \(time.formatted(.dateTime.hour().minute()))"
    }
}
