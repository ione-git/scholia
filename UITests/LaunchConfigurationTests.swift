import XCTest

final class LaunchConfigurationTests: UITestCase {
    func testAppReceivesLaunchConfiguration() throws {
        let configuration = LaunchConfiguration(
            resetsState: true,
            fixtures: [.german, .frenchNoCover],
            opened: [.german],
            inProgress: [.german],
            highlighted: [.frenchNoCover],
            translation: .immediate,
            now: try Date("2026-03-14T09:30:00Z", strategy: .iso8601),
            notificationPermission: .authorized,
            collections: [
                FixtureCollection(name: "Classics", books: [.german, .frenchNoCover]),
                FixtureCollection(name: "Poetry", books: []),
            ]
        )
        let root = HomeScreen(app: launch(configuration)).waitUntilShown()
        root.launchConfiguration.waitUntil(\.label, equals: configuration.summary)
        XCTAssertEqual(root.launchConfiguration.value as? String, TimeZone.gmt.identifier)
    }
}
