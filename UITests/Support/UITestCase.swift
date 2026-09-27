import XCTest

@MainActor
class UITestCase: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func launch(_ configuration: LaunchConfiguration, timeZone: TimeZone = .gmt) -> XCUIApplication {
        launch(configuration, timeZone: timeZone, arguments: [], animations: TestAnimations.off)
    }

    func launch(_ configuration: LaunchConfiguration, appearance: XCUIDevice.Appearance) -> XCUIApplication {
        switchAppearance(to: appearance)
        return launch(configuration)
    }

    func launchWithAnimations(_ configuration: LaunchConfiguration, appearance: XCUIDevice.Appearance)
        -> XCUIApplication
    {
        switchAppearance(to: appearance)
        return launch(configuration, timeZone: .gmt, arguments: [], animations: nil)
    }

    func launch(_ configuration: LaunchConfiguration, deviceLanguage: String) -> XCUIApplication {
        launch(
            configuration, timeZone: .gmt, arguments: ["-AppleLanguages", "(\(deviceLanguage))"],
            animations: TestAnimations.off)
    }

    func launch(
        _ configuration: LaunchConfiguration, appearance: XCUIDevice.Appearance, deviceLanguage: String
    ) -> XCUIApplication {
        switchAppearance(to: appearance)
        return launch(configuration, deviceLanguage: deviceLanguage)
    }

    func openSettings(_ app: XCUIApplication) -> SettingsScreen {
        HomeScreen(app: app).waitUntilShown().openSettings()
    }

    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launch(
        _ configuration: LaunchConfiguration, timeZone: TimeZone, arguments: [String], animations: String?
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = configuration.environment
        app.launchEnvironment["TZ"] = timeZone.identifier
        app.launchEnvironment[TestAnimations.environmentKey] = animations
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func switchAppearance(to appearance: XCUIDevice.Appearance) {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = appearance
    }
}
