import XCTest

@MainActor
final class SmokeTests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["root.placeholder"].waitForExistence(timeout: 5))
    }
}
