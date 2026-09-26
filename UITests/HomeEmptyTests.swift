import XCTest

final class HomeEmptyTests: UITestCase {
    func testLandscapeAddBookPillOpensFilesPicker() {
        turnToLandscape()
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()
        home.emptyCover.waitUntilExists()

        app.swipeUp()
        home.pickFile(tapping: home.emptyAddBookButton).cancel()

        home.emptyTitle.waitUntil(\.label, equals: "No books yet")
        XCTAssertFalse(AddBookScreen(app: app).root.exists)
    }

    func testAddingFirstBookShowsNormalHome() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()
        home.emptyCover.waitUntilExists()

        try home.openFromOtherApp(.german).add()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
        home.emptyCover.waitUntilGone()
    }

    func testEmptyCoverOpensFilesPicker() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()
        XCTAssertEqual(home.emptyCover.waitUntilExists().label, "Add a book")

        home.pickFile(tapping: home.emptyCover).cancel()

        home.emptyTitle.waitUntil(\.label, equals: "No books yet")
        XCTAssertFalse(AddBookScreen(app: app).root.exists)
    }

    func testAddBookPillOpensFilesPicker() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let home = HomeScreen(app: app).waitUntilShown()

        home.pickFile(tapping: home.emptyAddBookButton).cancel()

        home.emptyTitle.waitUntil(\.label, equals: "No books yet")
        XCTAssertFalse(AddBookScreen(app: app).root.exists)
    }

    func testHomeEmptySnapshotLight() throws {
        assertSnapshot(of: try launchEmptyHome(appearance: .light), named: "Home-Empty")
    }

    func testHomeEmptySnapshotDark() throws {
        assertSnapshot(of: try launchEmptyHome(appearance: .dark), named: "Home-Empty")
    }

    func testHomeEmptyLandscapeSnapshotLight() throws {
        turnToLandscape()
        assertSnapshot(of: try launchEmptyHome(appearance: .light), named: "Home-Empty-Landscape")
    }

    func testHomeEmptyLandscapeSnapshotDark() throws {
        turnToLandscape()
        assertSnapshot(of: try launchEmptyHome(appearance: .dark), named: "Home-Empty-Landscape")
    }

    private func launchEmptyHome(appearance: XCUIDevice.Appearance) throws -> HomeScreen {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.now = try Date("2026-03-14T09:30:00Z", strategy: .iso8601)
        let home = HomeScreen(app: launch(configuration, appearance: appearance)).waitUntilShown()
        home.emptyCover.waitUntilExists()
        return home
    }

    private func turnToLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
    }
}
