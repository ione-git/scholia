import XCTest

final class LaunchScreenTests: UITestCase {
    func testLaunchScreenShowsGlyphInLightAppearance() {
        let launchScreen = openLaunchScreen(in: .light)
        launchScreen.glyph.waitUntil(\.isHittable, equals: true)
        XCTAssertEqual(launchScreen.glyph.value as? String, "light")
        attachScreenshot("Launch-Light")
    }

    func testLaunchScreenShowsGlyphInDarkAppearance() {
        let launchScreen = openLaunchScreen(in: .dark)
        launchScreen.glyph.waitUntil(\.isHittable, equals: true)
        XCTAssertEqual(launchScreen.glyph.value as? String, "dark")
        attachScreenshot("Launch-Dark")
    }

    private func openLaunchScreen(in appearance: XCUIDevice.Appearance) -> LaunchScreen {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        XCUIDevice.shared.appearance = appearance
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        return RootScreen(app: app).waitUntilShown().openLaunchScreen()
    }
}
