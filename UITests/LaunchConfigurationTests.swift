import XCTest

final class LaunchConfigurationTests: UITestCase {
    func testAppReceivesFixturesAndTranslationMock() throws {
        let configuration = LaunchConfiguration(
            resetsState: true,
            fixtures: [.german, .frenchNoCover],
            mocksTranslation: true,
            now: try Date("2026-03-14T09:30:00Z", strategy: .iso8601)
        )
        let root = RootScreen(app: launch(configuration)).waitUntilShown()
        root.launchConfiguration.waitUntil(\.label, equals: configuration.summary)
    }
}
