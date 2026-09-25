import XCTest

private let reminder = "reading-reminder · Time to read · Pick up where you left off."

final class ReminderTests: UITestCase {
    func testTurningOnAsksPermissionAndSchedulesDailyReminder() throws {
        let settings = openSettings(resetsState: true)
        settings.readingReminder.waitUntil(\.label, equals: "none")
        let permission = try XCTUnwrap(settings.readingReminder.value as? String)
        XCTAssertNotEqual(permission, "denied", "notifications were denied on this simulator: reinstall the app")

        settings.reminder.waitUntil(\.isHittable, equals: true).tap()

        if permission == "notDetermined" {
            let prompt = NotificationPermissionScreen().waitUntilShown()
            XCTAssertEqual(prompt.root.label, "“Scholia” Would Like to Send You Notifications")
            prompt.allow()
        }
        settings.reminder.waitUntil(\.isOn, equals: true)
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:00 · repeats")
        XCTAssertEqual(settings.readingReminder.value as? String, "authorized")
    }

    func testTurningOffCancelsReminder() {
        let settings = openSettings(resetsState: true)
        settings.turnOnReminder()
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:00 · repeats")

        settings.turnOffReminder()

        settings.readingReminder.waitUntil(\.label, equals: "none")
    }

    func testChangingTimeReschedulesReminder() throws {
        let settings = openSettings(resetsState: true)
        settings.turnOnReminder()

        settings.openReminderTime().setMinute("30").close()

        settings.reminderTime.waitUntil(\.label, equals: try reminderLabel(hour: 21, minute: 30))
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:30 · repeats")
        XCTAssertTrue(settings.reminder.isOn)
    }

    func testToggleAndTimePersistAcrossRelaunch() throws {
        var settings = openSettings(resetsState: true)
        settings.openReminderTime().setMinute("45").close()
        settings.reminderTime.waitUntil(\.label, equals: try reminderLabel(hour: 21, minute: 45))
        settings.turnOnReminder()
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:45 · repeats")
        settings.app.terminate()

        settings = openSettings(resetsState: false)

        settings.reminderTime.waitUntil(\.label, equals: try reminderLabel(hour: 21, minute: 45))
        settings.reminder.waitUntil(\.isOn, equals: true)
        settings.readingReminder.waitUntil(\.label, equals: "\(reminder) · 21:45 · repeats")
    }

    private func openSettings(resetsState: Bool) -> SettingsScreen {
        let app = launch(
            LaunchConfiguration(resetsState: resetsState, fixtures: [], mocksTranslation: true, now: nil))
        return HomeScreen(app: app).waitUntilShown().openSettings()
    }

    private func reminderLabel(hour: Int, minute: Int) throws -> String {
        let time = try XCTUnwrap(Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now))
        return "Reminder at \(time.formatted(.dateTime.hour().minute()))"
    }
}
