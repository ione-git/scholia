import XCTest

final class SettingsTests: UITestCase {
    func testOpensFromHomeAndGoesBack() {
        let home = HomeScreen(app: launch(withoutBooks)).waitUntilShown()

        let settings = home.openSettings()
        XCTAssertEqual(settings.backButton.label, "Back to Home")
        settings.goBack()

        home.settingsButton.waitUntil(\.isHittable, equals: true)
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
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        var settings = HomeScreen(app: app).waitUntilShown().openSettings()

        settings.chooseTranslationLanguage("de")
        settings.translateTo.waitUntil(\.label, equals: "Translate to, German")
        settings.onWordTap("card").tap()
        settings.onWordTap("card").waitUntil(\.isSelected, equals: true)
        settings.chooseDailyGoal(30)
        settings.dailyGoal.waitUntil(\.label, equals: "Daily goal, 30 min")
        settings.turnOnReminder()
        settings.theme("dark").tap()
        settings.theme("dark").waitUntil(\.isSelected, equals: true)
        settings.chooseSortOrder("title")
        settings.sortBooks.waitUntil(\.label, equals: "Sort books by, Title")
        XCTAssertEqual(settings.reminder.value as? String, "1")
        app.terminate()

        let relaunched = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
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

    func testThemeOverridesSystemAppearance() {
        let settings = HomeScreen(app: launch(withoutBooks, appearance: .light)).waitUntilShown().openSettings()
        settings.colorScheme.waitUntil(\.label, equals: "light")

        settings.theme("dark").waitUntilExists().tap()
        settings.colorScheme.waitUntil(\.label, equals: "dark")

        settings.theme("system").tap()
        settings.colorScheme.waitUntil(\.label, equals: "light")
        XCUIDevice.shared.appearance = .dark
        settings.colorScheme.waitUntil(\.label, equals: "dark")

        settings.theme("light").tap()
        settings.colorScheme.waitUntil(\.label, equals: "light")
    }

    func testSettingsSnapshotLight() {
        assertSnapshot(of: openSettingsWithReminder(appearance: .light), named: "Settings")
    }

    func testSettingsSnapshotDark() {
        assertSnapshot(of: openSettingsWithReminder(appearance: .dark), named: "Settings")
    }

    private var withoutBooks: LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
            now: nil,
            notificationPermission: nil)
    }

    private func openSettingsWithReminder(appearance: XCUIDevice.Appearance) -> SettingsScreen {
        let settings = HomeScreen(app: launch(withoutBooks, appearance: appearance)).waitUntilShown().openSettings()
        settings.turnOnReminder()
        return settings
    }

    private func openSettings(deviceLanguage: String) -> SettingsScreen {
        let app = XCUIApplication()
        app.launchEnvironment =
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil
            )
            .environment
        app.launchArguments = ["-AppleLanguages", "(\(deviceLanguage))"]
        app.launch()
        return HomeScreen(app: app).waitUntilShown().openSettings()
    }
}
