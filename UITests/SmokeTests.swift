import XCTest

final class SmokeTests: UITestCase {
    func testAppLaunches() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil,
                notificationPermission: nil, unreadableStore: false))
        HomeScreen(app: app).waitUntilShown()
    }
}
