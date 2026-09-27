import XCTest

final class HomeTests: UITestCase {
    func testLibraryOpensFromHome() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()
        home.goalRing.waitUntil(\.label, equals: "Daily goal")
        XCTAssertEqual(home.goalRing.stringValue, 0.0.formatted(.percent.precision(.fractionLength(0))))

        let library = home.openLibrary()
        XCTAssertEqual(library.backButton.label, "Back to Home")
        library.goBack()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
    }

    func testMostRecentlyOpenedBookIsHero() throws {
        var configuration = try seeded([.german, .frenchNoCover, .minimalMetadata])
        configuration.opened = [.frenchNoCover]
        let home = HomeScreen(app: launch(configuration)).waitUntilShown()

        home.heroTitle.waitUntil(\.label, equals: "Un matin en ville")
    }

    func testMainSnapshotLight() throws {
        assertSnapshot(of: try launchMain(appearance: .light), named: "Main")
    }

    func testMainSnapshotDark() throws {
        assertSnapshot(of: try launchMain(appearance: .dark), named: "Main")
    }

    func testMainOneBookSnapshotLight() throws {
        assertSnapshot(of: try launchOneBook(appearance: .light), named: "Main-OneBook")
    }

    func testMainOneBookSnapshotDark() throws {
        assertSnapshot(of: try launchOneBook(appearance: .dark), named: "Main-OneBook")
    }

    private func launchMain(appearance: XCUIDevice.Appearance) throws -> HomeScreen {
        let app = launch(try seeded([.german, .frenchNoCover, .minimalMetadata]), appearance: appearance)
        let home = HomeScreen(app: app).waitUntilShown()
        home.book("Un matin en ville").waitUntilExists()
        return home
    }

    private func launchOneBook(appearance: XCUIDevice.Appearance) throws -> HomeScreen {
        let home = HomeScreen(app: launch(try seeded([.minimalMetadata]), appearance: appearance))
        home.heroTitle.waitUntilExists()
        return home
    }

    private func seeded(_ fixtures: [Fixture]) throws -> LaunchConfiguration {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = fixtures
        configuration.now = try Date("2026-03-14T09:30:00Z", strategy: .iso8601)
        return configuration
    }
}
