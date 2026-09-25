import XCTest

@MainActor
class UITestCase: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func launch(_ configuration: LaunchConfiguration) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = configuration.environment
        app.launch()
        return app
    }

    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
