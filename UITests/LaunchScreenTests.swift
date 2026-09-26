import XCTest

private let lightBackground = RGBColor(red: 244, green: 242, blue: 237)
private let darkBackground = RGBColor(red: 21, green: 20, blue: 18)

final class LaunchScreenTests: UITestCase {
    func testLaunchScreenShowsGlyphInLightAppearance() throws {
        let launchScreen = openLaunchScreen(in: .light)
        launchScreen.glyph.waitUntil(\.isHittable, equals: true)
        XCTAssertEqual(launchScreen.glyph.value as? String, "light")
        let background = try launchScreen.background()
        XCTAssertTrue(
            background.isClose(to: lightBackground), "background is \(background), expected \(lightBackground)")
        attachScreenshot("Launch-Light")
    }

    func testLaunchScreenShowsGlyphInDarkAppearance() throws {
        let launchScreen = openLaunchScreen(in: .dark)
        launchScreen.glyph.waitUntil(\.isHittable, equals: true)
        XCTAssertEqual(launchScreen.glyph.value as? String, "dark")
        let background = try launchScreen.background()
        XCTAssertTrue(
            background.isClose(to: darkBackground), "background is \(background), expected \(darkBackground)")
        attachScreenshot("Launch-Dark")
    }

    private func openLaunchScreen(in appearance: XCUIDevice.Appearance) -> LaunchScreen {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = appearance
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil,
                notificationPermission: nil, unreadableStore: false))
        return HomeScreen(app: app).waitUntilShown().openLaunchScreen()
    }
}
