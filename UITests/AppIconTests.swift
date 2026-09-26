import XCTest

private let lightFill = RGBColor(red: 244, green: 242, blue: 237)
private let darkFill = RGBColor(red: 29, green: 27, blue: 23)

final class AppIconTests: UITestCase {
    func testHomeScreenShowsAppIcon() throws {
        let springboard = showHomeScreen().customizeIcons("Default")
        let icon = springboard.scrollToAppIcon()
        XCTAssertEqual(icon.label, "Scholia")
        let background = try springboard.appIconBackground()
        XCTAssertTrue(background.isClose(to: lightFill), "icon background is \(background), expected \(lightFill)")
        attachScreenshot("Icon-V1")
    }

    func testHomeScreenShowsDarkAppIcon() throws {
        addTeardownBlock { @MainActor in
            SpringboardScreen().customizeIcons("Default")
        }
        let springboard = showHomeScreen().customizeIcons("Dark", "Always")
        let icon = springboard.scrollToAppIcon()
        XCTAssertEqual(icon.label, "Scholia")
        let background = try springboard.appIconBackground()
        XCTAssertTrue(background.isClose(to: darkFill), "icon background is \(background), expected \(darkFill)")
        attachScreenshot("Icon-V1-Dark")
    }

    func testHomeScreenShowsTintedAppIcon() throws {
        addTeardownBlock { @MainActor in
            SpringboardScreen().customizeIcons("Default")
        }
        let springboard = showHomeScreen().customizeIcons("Tinted")
        let icon = springboard.scrollToAppIcon()
        XCTAssertEqual(icon.label, "Scholia")
        let background = try springboard.appIconBackground()
        XCTAssertFalse(background.isClose(to: lightFill), "icon background is the light fill \(background)")
        XCTAssertFalse(background.isClose(to: darkFill), "icon background is the dark fill \(background)")
        attachScreenshot("Icon-V1-Tinted")
    }

    private func showHomeScreen() -> SpringboardScreen {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], mocksTranslation: true, now: nil,
                notificationPermission: nil))
        HomeScreen(app: app).waitUntilShown()
        XCUIDevice.shared.press(.home)
        return SpringboardScreen().waitUntilShown()
    }
}
