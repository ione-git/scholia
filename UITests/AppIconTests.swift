import XCTest

final class AppIconTests: UITestCase {
    func testHomeScreenShowsAppIcon() {
        let icon = showHomeScreen().customizeIcons("Default").scrollToAppIcon()
        XCTAssertEqual(icon.label, "Scholia")
        attachScreenshot("Icon-V1")
    }

    func testHomeScreenShowsDarkAppIcon() {
        addTeardownBlock { @MainActor in
            SpringboardScreen().customizeIcons("Default")
        }
        let icon = showHomeScreen().customizeIcons("Dark", "Always").scrollToAppIcon()
        XCTAssertEqual(icon.label, "Scholia")
        attachScreenshot("Icon-V1-Dark")
    }

    private func showHomeScreen() -> SpringboardScreen {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        RootScreen(app: app).waitUntilShown()
        XCUIDevice.shared.press(.home)
        return SpringboardScreen().waitUntilShown()
    }
}
