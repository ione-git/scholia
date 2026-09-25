import XCTest

final class AppIconTests: UITestCase {
    func testHomeScreenShowsAppIcon() {
        XCUIDevice.shared.press(.home)
        let icon = SpringboardScreen().waitUntilShown().scrollToAppIcon()
        XCTAssertEqual(icon.label, "Scholia")
        attachScreenshot("Icon-V1")
    }
}
