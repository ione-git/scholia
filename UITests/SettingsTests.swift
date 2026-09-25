import XCTest

private let lightBackground = RGBColor(red: 244, green: 242, blue: 237)
private let darkBackground = RGBColor(red: 21, green: 20, blue: 18)

final class SettingsTests: UITestCase {
    func testShowsDefaultsAndTogglesReminder() throws {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        let settings = HomeScreen(app: app).waitUntilShown().openSettings()

        XCTAssertEqual(settings.translateTo.waitUntilExists().label, "Translate to, English")
        settings.onWordTap("bubble").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(settings.onWordTap("minimal").isSelected)
        XCTAssertFalse(settings.onWordTap("card").isSelected)
        XCTAssertEqual(settings.dailyGoal.label, "Daily goal, 20 min")
        XCTAssertEqual(settings.reminderTitle.label, "Reminder at \(try time(hour: 21))")
        XCTAssertEqual(settings.reminder.label, "Reminder")
        XCTAssertEqual(settings.reminder.value as? String, "0")
        settings.theme("system").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(settings.theme("light").isSelected)
        XCTAssertFalse(settings.theme("dark").isSelected)
        XCTAssertEqual(settings.sortBooks.label, "Sort books by, Recently opened")
        XCTAssertEqual(settings.version.label, "Scholia \(try marketingVersion())")
        XCTAssertEqual(settings.backButton.label, "Back to Home")

        settings.reminder.tap()

        XCTAssertEqual(settings.reminder.value as? String, "1")
        attachScreenshot("Settings")
        settings.goBack()
    }

    func testTranslateToDefaultsToSupportedDeviceLanguage() {
        let settings = openSettings(deviceLanguage: "ru")

        XCTAssertEqual(settings.translateTo.waitUntilExists().label, "Translate to, Russian")
    }

    func testTranslateToFallsBackToEnglishForUnsupportedDeviceLanguage() {
        let settings = openSettings(deviceLanguage: "fi")

        XCTAssertEqual(settings.translateTo.waitUntilExists().label, "Translate to, English")
    }

    func testEveryValuePersistsAcrossRelaunch() {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        var settings = HomeScreen(app: app).waitUntilShown().openSettings()

        settings.chooseTranslationLanguage("de")
        settings.translateTo.waitUntil(\.label, equals: "Translate to, German")
        settings.onWordTap("card").tap()
        settings.onWordTap("card").waitUntil(\.isSelected, equals: true)
        settings.chooseDailyGoal(30)
        settings.dailyGoal.waitUntil(\.label, equals: "Daily goal, 30 min")
        settings.reminder.tap()
        settings.theme("dark").tap()
        settings.theme("dark").waitUntil(\.isSelected, equals: true)
        settings.chooseSortOrder("title")
        settings.sortBooks.waitUntil(\.label, equals: "Sort books by, Title")
        XCTAssertEqual(settings.reminder.value as? String, "1")
        app.terminate()

        let relaunched = launch(
            LaunchConfiguration(resetsState: false, fixtures: [], mocksTranslation: true, now: nil))
        settings = HomeScreen(app: relaunched).waitUntilShown().openSettings()

        XCTAssertEqual(settings.translateTo.waitUntilExists().label, "Translate to, German")
        settings.onWordTap("card").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(settings.onWordTap("bubble").isSelected)
        XCTAssertEqual(settings.dailyGoal.label, "Daily goal, 30 min")
        XCTAssertEqual(settings.reminder.value as? String, "1")
        settings.theme("dark").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(settings.theme("system").isSelected)
        XCTAssertEqual(settings.sortBooks.label, "Sort books by, Title")
    }

    func testThemeSwitchAppliesAppWide() {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = .light
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        let home = HomeScreen(app: app).waitUntilShown()
        waitUntilBackground(home.background, is: lightBackground)
        var settings = home.openSettings()

        settings.theme("dark").waitUntilExists().tap()

        settings.theme("dark").waitUntil(\.isSelected, equals: true)
        waitUntilBackground(settings.background, is: darkBackground)
        settings.goBack()
        waitUntilBackground(home.background, is: darkBackground)

        settings = home.openSettings()
        settings.theme("system").waitUntilExists().tap()

        settings.theme("system").waitUntil(\.isSelected, equals: true)
        waitUntilBackground(settings.background, is: lightBackground)
        XCUIDevice.shared.appearance = .dark
        waitUntilBackground(settings.background, is: darkBackground)

        settings.theme("light").tap()

        settings.theme("light").waitUntil(\.isSelected, equals: true)
        waitUntilBackground(settings.background, is: lightBackground)
    }

    private func openSettings(deviceLanguage: String) -> SettingsScreen {
        let app = XCUIApplication()
        app.launchEnvironment =
            LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil).environment
        app.launchArguments = ["-AppleLanguages", "(\(deviceLanguage))"]
        app.launch()
        return HomeScreen(app: app).waitUntilShown().openSettings()
    }

    private func time(hour: Int) throws -> String {
        try XCTUnwrap(Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now))
            .formatted(.dateTime.hour().minute())
    }

    private func marketingVersion() throws -> String {
        try XCTUnwrap(
            Bundle(for: UITestCase.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
    }

    private func waitUntilBackground(
        _ background: @escaping @MainActor () throws -> RGBColor, is expected: RGBColor,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let predicate = NSPredicate { _, _ in
            MainActor.assumeIsolated { (try? background())?.isClose(to: expected) ?? false }
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: 10)
        XCTAssertEqual(result, .completed, "background never became \(expected)", file: file, line: line)
    }
}
