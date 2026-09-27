import XCTest

@MainActor
class UITestCase: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func launch(_ configuration: LaunchConfiguration, timeZone: TimeZone = .gmt) -> XCUIApplication {
        start(configuration, timeZone: timeZone, animations: TestAnimations.off)
    }

    func launch(_ configuration: LaunchConfiguration, appearance: XCUIDevice.Appearance) -> XCUIApplication {
        use(appearance)
        return launch(configuration)
    }

    func launchWithAnimations(_ configuration: LaunchConfiguration, appearance: XCUIDevice.Appearance)
        -> XCUIApplication
    {
        use(appearance)
        return start(configuration, timeZone: .gmt, animations: nil)
    }

    private func start(_ configuration: LaunchConfiguration, timeZone: TimeZone, animations: String?)
        -> XCUIApplication
    {
        let app = XCUIApplication()
        app.launchEnvironment = configuration.environment
        app.launchEnvironment["TZ"] = timeZone.identifier
        app.launchEnvironment[TestAnimations.environmentKey] = animations
        app.launch()
        return app
    }

    private func use(_ appearance: XCUIDevice.Appearance) {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = appearance
    }

    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
