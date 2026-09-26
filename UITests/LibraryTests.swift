import XCTest

final class LibraryTests: UITestCase {
    private let allFixtures: [Fixture] = [.german, .frenchNoCover, .minimalMetadata, .corrupted, .drm]

    func testGridShowsEveryBookInThreeColumns() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: allFixtures, opened: [], inProgress: [], highlighted: [],
                mocksTranslation: true, now: nil,
                notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        XCTAssertEqual(
            library.shownTitles, ["Corrupted", "Die Verwandlung", "Encrypted", "Minimal", "Un matin en ville"])
        let covers = library.shownTitles.map { library.book($0).frame }
        for cover in covers {
            XCTAssertEqual(cover.width, 107, accuracy: 0.01)
            XCTAssertEqual(cover.height, 152, accuracy: 0.01)
        }
        XCTAssertEqual(covers[0].minX, 20)
        XCTAssertEqual(covers[2].maxX, app.frame.width - 20)
        XCTAssertEqual(covers[1].minX - covers[0].maxX, covers[2].minX - covers[1].maxX, accuracy: 0.5)
        XCTAssertEqual(covers[0].minY, covers[2].minY)
        XCTAssertEqual(covers[3].minX, covers[0].minX)
        XCTAssertGreaterThan(covers[3].minY, covers[0].maxY)
        XCTAssertEqual(library.backButton.label, "Back to Home")
        XCTAssertEqual(library.moreButton.label, "More")
        XCTAssertEqual(library.searchField.frame.height, 40)
        attachScreenshot("Library-A")
    }

    func testSearchFiltersByTitleAndAuthor() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: allFixtures, opened: [], inProgress: [], highlighted: [],
                mocksTranslation: true, now: nil,
                notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        library.search("kafka")
        library.book("Minimal").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Die Verwandlung", "Encrypted"])

        library.search("MATIN")
        library.book("Die Verwandlung").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Un matin en ville"])

        library.search("Tolstoy")
        library.book("Un matin en ville").waitUntilGone()
        XCTAssertEqual(library.shownTitles, [])

        library.search("")
        library.book("Minimal").waitUntilExists()
        XCTAssertEqual(
            library.shownTitles, ["Corrupted", "Die Verwandlung", "Encrypted", "Minimal", "Un matin en ville"])
    }

    func testEachSortOrder() throws {
        let earlier = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .minimalMetadata, .corrupted], opened: [], inProgress: [],
                highlighted: [],
                mocksTranslation: true,
                now: try Date("2026-03-01T10:00:00Z", strategy: .iso8601), notificationPermission: nil))
        HomeScreen(app: earlier).waitUntilShown()
        earlier.terminate()
        let app = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [.frenchNoCover], opened: [.minimalMetadata, .german], inProgress: [],
                highlighted: [],
                mocksTranslation: true, now: try Date("2026-03-02T10:00:00Z", strategy: .iso8601),
                notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        XCTAssertEqual(library.shownTitles, ["Minimal", "Die Verwandlung", "Un matin en ville", "Corrupted"])

        library.sort(by: "recentlyAdded")
        XCTAssertEqual(library.shownTitles, ["Un matin en ville", "Corrupted", "Die Verwandlung", "Minimal"])

        library.sort(by: "title")
        XCTAssertEqual(library.shownTitles, ["Corrupted", "Die Verwandlung", "Minimal", "Un matin en ville"])

        library.sort(by: "author")
        XCTAssertEqual(library.shownTitles, ["Die Verwandlung", "Un matin en ville", "Corrupted", "Minimal"])

        library.sort(by: "recentlyOpened")
        XCTAssertEqual(library.shownTitles, ["Minimal", "Die Verwandlung", "Un matin en ville", "Corrupted"])
    }

    func testSortPersistsAcrossRelaunch() {
        let first = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata], opened: [.frenchNoCover],
                inProgress: [], highlighted: [],
                mocksTranslation: true, now: nil, notificationPermission: nil))
        let library = HomeScreen(app: first).waitUntilShown().openLibrary()
        XCTAssertEqual(library.shownTitles, ["Un matin en ville", "Die Verwandlung", "Minimal"])
        library.sort(by: "title")
        XCTAssertEqual(library.shownTitles, ["Die Verwandlung", "Minimal", "Un matin en ville"])
        first.terminate()

        let relaunched = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], mocksTranslation: true,
                now: nil,
                notificationPermission: nil))
        let reopened = HomeScreen(app: relaunched).waitUntilShown().openLibrary()

        XCTAssertEqual(reopened.shownTitles, ["Die Verwandlung", "Minimal", "Un matin en ville"])
        XCTAssertEqual(reopened.openMenu().root.label, "Sort by Title")
    }

    func testMenuShowsActionsAndSortSubmenu() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: allFixtures, opened: [], inProgress: [], highlighted: [],
                mocksTranslation: true, now: nil,
                notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        let menu = library.openMenu()
        XCTAssertEqual(library.moreButton.label, "Close menu")
        XCTAssertTrue(library.moreButton.isSelected)
        XCTAssertEqual(menu.selectBooks.label, "Select Books")
        XCTAssertEqual(menu.newCollection.label, "New Collection")
        XCTAssertEqual(menu.root.label, "Sort by Recent")
        attachScreenshot("Library-Empty")

        let sortMenu = menu.openSort()
        XCTAssertEqual(sortMenu.root.label, "Sort by")
        for (key, title) in [
            ("recentlyOpened", "Recently opened"), ("recentlyAdded", "Recently added"), ("title", "Title"),
            ("author", "Author"),
        ] {
            XCTAssertEqual(sortMenu.option(key).label, title)
            XCTAssertEqual(sortMenu.option(key).isSelected, key == "recentlyOpened")
        }
        attachScreenshot("Library-Sort")

        sortMenu.goBack().root.waitUntil(\.label, equals: "Sort by Recent")
        library.root.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        menu.root.waitUntilGone()
        library.moreButton.waitUntil(\.label, equals: "More")
    }
}
