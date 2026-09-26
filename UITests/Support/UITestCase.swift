import XCTest

@MainActor
class UITestCase: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func launch(_ configuration: LaunchConfiguration, timeZone: TimeZone = .gmt) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = configuration.environment
        app.launchEnvironment["TZ"] = timeZone.identifier
        app.launchEnvironment[TestAnimations.environmentKey] = TestAnimations.off
        app.launch()
        return app
    }

    func launch(_ configuration: LaunchConfiguration, appearance: XCUIDevice.Appearance) -> XCUIApplication {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = appearance
        return launch(configuration)
    }

    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
