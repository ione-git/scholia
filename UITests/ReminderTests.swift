import XCTest

private let reminder = "reading-reminder · Time to read · Pick up where you left off."

final class ReminderTests: UITestCase {
    func testTurningOnSchedulesDailyReminder() {
        let settings = openSettings(resetsState: true, notificationPermission: nil)

        settings.turnOnReminder()

        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:00 · repeats")
        XCTAssertEqual(settings.readingReminder.value as? String, "authorized")
    }

    func testDecliningPermissionLeavesReminderOff() {
        let settings = openSettings(resetsState: true, notificationPermission: .declined)
        settings.readingReminder.waitUntil(\.label, equals: "none")

        settings.reminder.waitUntil(\.isHittable, equals: true).tap()

        settings.reminder.waitUntil(\.isOn, equals: false)
        settings.readingReminder.waitUntil(\.label, equals: "none")
    }

    func testDeniedPermissionShowsNotificationsOffAlert() {
        let settings = openSettings(resetsState: true, notificationPermission: .denied)
        settings.readingReminder.waitUntil(\.label, equals: "none")

        settings.reminder.waitUntil(\.isHittable, equals: true).tap()

        let alert = NotificationsOffScreen(app: settings.app).waitUntilShown()
        XCTAssertEqual(alert.root.label, "Notifications are off")
        alert.notNow()
        XCTAssertFalse(settings.reminder.isOn)
        settings.readingReminder.waitUntil(\.label, equals: "none")
    }

    func testTurningOffCancelsReminder() {
        let settings = openSettings(resetsState: true, notificationPermission: nil)
        settings.turnOnReminder()
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:00 · repeats")

        settings.turnOffReminder()

        settings.readingReminder.waitUntil(\.label, equals: "none")
    }

    func testChangingTimeReschedulesReminder() throws {
        let settings = openSettings(resetsState: true, notificationPermission: nil)
        settings.turnOnReminder()

        settings.openReminderTime().setMinute("30").close()

        settings.reminderTime.waitUntil(\.label, equals: try reminderLabel(hour: 21, minute: 30))
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:30 · repeats")
        XCTAssertTrue(settings.reminder.isOn)
    }

    func testToggleAndTimePersistAcrossRelaunch() throws {
        var settings = openSettings(resetsState: true, notificationPermission: nil)
        settings.openReminderTime().setMinute("45").close()
        settings.reminderTime.waitUntil(\.label, equals: try reminderLabel(hour: 21, minute: 45))
        settings.turnOnReminder()
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:45 · repeats")
        settings.app.terminate()

        settings = openSettings(resetsState: false, notificationPermission: nil)

        settings.reminderTime.waitUntil(\.label, equals: try reminderLabel(hour: 21, minute: 45))
        settings.reminder.waitUntil(\.isOn, equals: true)
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:45 · repeats")
    }

    private func openSettings(resetsState: Bool, notificationPermission: NotificationPermission?) -> SettingsScreen {
        let app = launch(
            LaunchConfiguration(
                resetsState: resetsState, fixtures: [], opened: [], mocksTranslation: true, now: nil,
                notificationPermission: notificationPermission))
        return HomeScreen(app: app).waitUntilShown().openSettings()
    }

    private func reminderLabel(hour: Int, minute: Int) throws -> String {
        let time = try XCTUnwrap(Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now))
        return "Reminder at \(time.formatted(.dateTime.hour().minute()))"
    }
}
