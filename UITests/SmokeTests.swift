import XCTest

final class SmokeTests: UITestCase {
    func testAppLaunches() {
        let app = launch(LaunchConfiguration(resetsState: true, fixtures: [], mocksTranslation: true, now: nil))
        RootScreen(app: app).waitUntilShown()
    }
}
