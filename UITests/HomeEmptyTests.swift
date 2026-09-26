import XCTest

final class HomeEmptyTests: UITestCase {
    func testFirstLaunchShowsEmptyState() {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let home = HomeScreen(app: app).waitUntilShown()

        XCTAssertEqual(home.emptyCover.waitUntilExists().label, "Add a book")
        XCTAssertEqual(home.emptyCover.frame.width, 160, accuracy: 0.01)
        XCTAssertEqual(home.emptyCover.frame.height, 240, accuracy: 0.01)
        XCTAssertEqual(home.emptyTitle.label, "No books yet")
        XCTAssertEqual(home.emptyMessage.label, "Add an EPUB from Files, or share one to Scholia from any app.")
        XCTAssertEqual(home.emptyAddBookButton.label, "Add a Book")
        XCTAssertEqual(home.emptyAddBookButton.frame.height, 48, accuracy: 0.01)
        XCTAssertEqual(home.goalRing.value as? String, 0.0.formatted(.percent.precision(.fractionLength(0))))
        XCTAssertEqual(home.addBookButton.label, "Add a book")
        XCTAssertTrue(home.settingsButton.exists)
        XCTAssertFalse(home.heroCover.exists)
        XCTAssertFalse(home.libraryButton.exists)
        attachScreenshot("Home-Empty")
    }

    func testLandscapeKeepsEmptyStateBelowHeaderAndScrollsToPill() {
        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let home = HomeScreen(app: app).waitUntilShown()

        home.emptyCover.waitUntilExists()
        XCTAssertGreaterThanOrEqual(home.emptyCover.frame.minY, home.addBookButton.frame.maxY - 0.5)

        app.swipeUp()

        home.emptyAddBookButton.waitUntil(\.isHittable, equals: true)
        XCTAssertLessThanOrEqual(home.emptyAddBookButton.frame.maxY, app.windows.firstMatch.frame.maxY)
    }

    func testAddingFirstBookShowsNormalHome() throws {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let home = HomeScreen(app: app).waitUntilShown()
        home.emptyCover.waitUntilExists()

        try home.openFromOtherApp(.german).add()

        home.heroTitle.waitUntil(\.label, equals: "Die Verwandlung")
        XCTAssertEqual(home.libraryButton.label, "Library, All 1")
        XCTAssertFalse(home.emptyCover.exists)
        XCTAssertFalse(home.emptyTitle.exists)
        XCTAssertFalse(home.emptyAddBookButton.exists)
    }

    func testEmptyCoverOpensFilesPicker() {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let home = HomeScreen(app: app).waitUntilShown()

        home.pickFile(tapping: home.emptyCover).cancel()

        home.emptyTitle.waitUntil(\.label, equals: "No books yet")
        XCTAssertFalse(AddBookScreen(app: app).root.exists)
    }

    func testAddBookPillOpensFilesPicker() {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let home = HomeScreen(app: app).waitUntilShown()

        home.pickFile(tapping: home.emptyAddBookButton).cancel()

        home.emptyTitle.waitUntil(\.label, equals: "No books yet")
        XCTAssertFalse(AddBookScreen(app: app).root.exists)
    }
}
