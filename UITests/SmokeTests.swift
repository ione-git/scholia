import XCTest

final class SmokeTests: UITestCase {
    func testAppLaunches() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))
        HomeScreen(app: app).waitUntilShown()
    }
}
