import XCTest

final class SettingsTests: UITestCase {
    func testOpensFromHomeAndGoesBack() {
        let home = HomeScreen(app: launch(.withoutBooks)).waitUntilShown()
        XCTAssertEqual(home.settingsButton.waitUntilExists().label, "Settings")

        let settings = home.openSettings()
        XCTAssertEqual(settings.backButton.label, "Back to Home")
        settings.goBack()

        home.settingsButton.waitUntil(\.isHittable, equals: true)
    }

    func testBackSwipeReturnsHomeAndAllowsAnotherPush() {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = [.minimalMetadata]
        let app = launchWithAnimations(configuration, appearance: .light)
        let home = HomeScreen(app: app).waitUntilShown()
        let settings = home.openSettings()

        settings.swipeBack()

        home.settingsButton.waitUntil(\.isHittable, equals: true)
        let library = home.openLibrary()
        library.swipeBack()
        home.openSettings().goBack()
        home.settingsButton.waitUntil(\.isHittable, equals: true)
    }

    func testCancelledBackSwipeKeepsSettingsAndBackButtonWorks() {
        let settings = openSettings(launchWithAnimations(.withoutBooks, appearance: .light))

        settings.cancelBackSwipe()

        settings.backButton.waitUntil(\.isHittable, equals: true)
        settings.chooseWordTapStyle("card")
        let home = settings.goBack()
        home.openSettings().onWordTap("card").waitUntil(\.isSelected, equals: true)
    }

    func testDraggingNativeSegmentsChangesWordTapAndTheme() {
        let settings = openSettings(launchWithAnimations(.withoutBooks, appearance: .light))

        settings.dragWordTap(from: "bubble", to: "card")
        settings.onWordTap("card").waitUntil(\.isSelected, equals: true)
        settings.dragTheme(from: "system", to: "dark")
        settings.theme("dark").waitUntil(\.isSelected, equals: true)
        settings.colorScheme.waitUntil(\.label, equals: "dark")
    }

    func testTranslateToDefaultsToSupportedDeviceLanguage() {
        let settings = openSettings(launch(.withoutBooks, deviceLanguage: "ru"))

        settings.translateTo.waitUntil(\.label, equals: "Translate to, Russian")
    }

    func testTranslateToFallsBackToEnglishForUnsupportedDeviceLanguage() {
        let settings = openSettings(launch(.withoutBooks, deviceLanguage: "fi"))

        settings.translateTo.waitUntil(\.label, equals: "Translate to, English")
    }

    func testChoicesPersistAcrossRelaunch() {
        let app = launch(.withoutBooks)
        var settings = openSettings(app)

        settings.chooseWordTapStyle("card")
        settings.chooseDailyGoal(30)
        settings.dailyGoal.waitUntil(\.label, equals: "Daily goal, 30 min")
        settings.chooseTheme("dark")
        settings.chooseSortOrder("title")
        settings.sortBooks.waitUntil(\.label, equals: "Sort books by, Title")
        app.terminate()

        var relaunch = LaunchConfiguration.withoutBooks
        relaunch.resetsState = false
        settings = openSettings(launch(relaunch))

        settings.onWordTap("card").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(settings.onWordTap("bubble").isSelected)
        XCTAssertEqual(settings.dailyGoal.label, "Daily goal, 30 min")
        settings.theme("dark").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(settings.theme("system").isSelected)
        XCTAssertEqual(settings.sortBooks.label, "Sort books by, Title")
    }

    func testSortChosenInSettingsOrdersLibrary() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata], opened: [.frenchNoCover],
                inProgress: [], highlighted: [],
                translation: .immediate, now: nil, notificationPermission: nil))
        let settings = openSettings(app)

        settings.chooseSortOrder("title")
        let library = settings.goBack().openLibrary()
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Minimal", "Un matin en ville"])

        library.sort(by: "author")
        library.goBack().openSettings().sortBooks.waitUntil(\.label, equals: "Sort books by, Author")
    }

    func testThemeOverridesSystemAppearance() {
        let settings = openSettings(launch(.withoutBooks, appearance: .light))
        settings.colorScheme.waitUntil(\.label, equals: "light")

        settings.chooseTheme("dark")
        settings.colorScheme.waitUntil(\.label, equals: "dark")

        settings.chooseTheme("system")
        settings.colorScheme.waitUntil(\.label, equals: "light")
        XCUIDevice.shared.appearance = .dark
        settings.colorScheme.waitUntil(\.label, equals: "dark")

        settings.chooseTheme("light")
        settings.colorScheme.waitUntil(\.label, equals: "light")
    }

    func testThemeChoicesMatchingLightSystemAndBackKeepControlsInteractive() {
        themeChoicesAndBack(appearance: .light, matchingTheme: "light", oppositeTheme: "dark")
    }

    func testThemeChoicesMatchingDarkSystemAndBackKeepControlsInteractive() {
        themeChoicesAndBack(appearance: .dark, matchingTheme: "dark", oppositeTheme: "light")
    }

    private func themeChoicesAndBack(appearance: XCUIDevice.Appearance, matchingTheme: String, oppositeTheme: String) {
        let app = launchWithAnimations(.withoutBooks, appearance: appearance)
        let home = HomeScreen(app: app).waitUntilShown()
        let settings = home.openSettings()
        settings.theme(matchingTheme).tap()
        settings.theme("system").tap()
        settings.theme(oppositeTheme).tap()
        settings.dragTheme(from: oppositeTheme, to: "system")
        settings.backButton.tap()
        home.settingsButton.waitUntil(\.isHittable, equals: true)
        home.openSettings().theme("system").waitUntil(\.isSelected, equals: true)
    }

    func testAnimatedThemeSwitchesKeepControlsAndPersistLastChoice() {
        let app = launchWithAnimations(.withoutBooks, appearance: .light)
        let settings = openSettings(app)
        for theme in ["dark", "light", "dark", "light"] {
            settings.chooseTheme(theme)
            settings.colorScheme.waitUntil(\.label, equals: theme)
            settings.chooseWordTapStyle("card")
        }
        app.terminate()

        var configuration = LaunchConfiguration.withoutBooks
        configuration.resetsState = false
        let reopened = openSettings(launch(configuration, appearance: .light))
        reopened.theme("light").waitUntil(\.isSelected, equals: true)
        reopened.onWordTap("card").waitUntil(\.isSelected, equals: true)
    }

    func testSettingsSnapshotLight() {
        assertSnapshot(of: openSettingsWithReminder(appearance: .light), named: "Settings")
    }

    func testSettingsSnapshotDark() {
        assertSnapshot(of: openSettingsWithReminder(appearance: .dark), named: "Settings")
    }

    func testSettingsThemeDarkSnapshotLight() {
        assertSnapshot(of: openSettings(theme: "dark", appearance: .light), named: "Settings-ThemeDark")
    }

    func testHomeEmptyThemeDarkSnapshotLight() {
        assertSnapshot(of: openSettings(theme: "dark", appearance: .light).goBack(), named: "Home-Empty-ThemeDark")
    }

    func testSettingsThemeLightSnapshotDark() {
        assertSnapshot(of: openSettings(theme: "light", appearance: .dark), named: "Settings-ThemeLight")
    }

    private func openSettingsWithReminder(appearance: XCUIDevice.Appearance) -> SettingsScreen {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.notificationPermission = .authorized
        let settings = openSettings(launch(configuration, appearance: appearance, deviceLanguage: "ru"))
        settings.tapReminder()
        settings.reminder.waitUntil(\.isOn, equals: true)
        return settings
    }

    private func openSettings(theme: String, appearance: XCUIDevice.Appearance) -> SettingsScreen {
        let settings = openSettings(launch(.withoutBooks, appearance: appearance))
        settings.chooseTheme(theme)
        return settings
    }
}
