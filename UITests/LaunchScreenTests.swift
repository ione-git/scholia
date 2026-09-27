import XCTest

final class LaunchScreenTests: UITestCase {
    func testLaunchLightSnapshotLight() {
        assertSnapshot(of: openLaunchScreen(.light), named: "Launch-Light")
    }

    func testLaunchLightSnapshotDark() {
        assertSnapshot(of: openLaunchScreen(.dark), named: "Launch-Light")
    }

    private func openLaunchScreen(_ appearance: XCUIDevice.Appearance) -> LaunchScreen {
        let launchScreen = HomeScreen(app: launch(.withoutBooks, appearance: appearance)).waitUntilShown()
            .openLaunchScreen()
        launchScreen.glyph.waitUntil(\.isHittable, equals: true)
        return launchScreen
    }
}
