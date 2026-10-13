import XCTest

final class LibraryTests: UITestCase {
    private let allFixtures: [Fixture] = [.german, .frenchNoCover, .minimalMetadata, .corrupted, .drm]

    func testSearchFiltersByTitleAndAuthor() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: allFixtures, opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        library.search("kafka")
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Encrypted"])

        library.search("MATIN")
        library.waitUntil(\.shownTitles, equals: ["Un matin en ville"])

        library.search("Tolstoy")
        library.waitUntil(\.shownTitles, equals: [])

        library.search("")
        library.waitUntil(
            \.shownTitles, equals: ["Corrupted", "Die Verwandlung", "Encrypted", "Minimal", "Un matin en ville"])
    }

    func testEachSortOrder() throws {
        let earlier = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .minimalMetadata, .corrupted], opened: [], inProgress: [],
                highlighted: [],
                translation: .immediate,
                now: try Date("2026-03-01T10:00:00Z", strategy: .iso8601), notificationPermission: nil))
        HomeScreen(app: earlier).waitUntilShown()
        earlier.terminate()
        let app = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [.frenchNoCover], opened: [.minimalMetadata, .german], inProgress: [],
                highlighted: [],
                translation: .immediate, now: try Date("2026-03-02T10:00:00Z", strategy: .iso8601),
                notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        library.waitUntil(\.shownTitles, equals: ["Minimal", "Die Verwandlung", "Un matin en ville", "Corrupted"])

        library.sort(by: "recentlyAdded")
        library.waitUntil(\.shownTitles, equals: ["Un matin en ville", "Corrupted", "Die Verwandlung", "Minimal"])

        library.sort(by: "title")
        library.waitUntil(\.shownTitles, equals: ["Corrupted", "Die Verwandlung", "Minimal", "Un matin en ville"])

        library.sort(by: "author")
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Un matin en ville", "Corrupted", "Minimal"])

        library.sort(by: "recentlyOpened")
        library.waitUntil(\.shownTitles, equals: ["Minimal", "Die Verwandlung", "Un matin en ville", "Corrupted"])
    }

    func testSortPersistsAcrossRelaunch() throws {
        let now = try Date("2026-03-14T09:30:00Z", strategy: .iso8601)
        let first = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover, .minimalMetadata], opened: [.frenchNoCover],
                inProgress: [], highlighted: [],
                translation: .immediate, now: now, notificationPermission: nil))
        let library = HomeScreen(app: first).waitUntilShown().openLibrary()
        library.waitUntil(\.shownTitles, equals: ["Un matin en ville", "Die Verwandlung", "Minimal"])
        library.sort(by: "title")
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Minimal", "Un matin en ville"])
        first.terminate()

        let relaunched = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: now,
                notificationPermission: nil))
        let reopened = HomeScreen(app: relaunched).waitUntilShown().openLibrary()

        reopened.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Minimal", "Un matin en ville"])
        reopened.openMenu().openSort().option("title").waitUntil(\.isSelected, equals: true)
    }

    func testNativeSortMenuDismissesOutsideAndReopens() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: allFixtures, opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        XCTAssertEqual(library.moreButton.waitUntilExists().label, "More")

        let sort = library.openMenu().openSort()
        sort.option("recentlyOpened").waitUntil(\.isSelected, equals: true)
        sort.closeByTappingOutside()

        library.openMenu().selectBooks.waitUntil(\.isHittable, equals: true)
    }

    func testLibraryASnapshotLight() throws {
        assertSnapshot(of: try openLibraryWithCollections(appearance: .light), named: "Library-A")
    }

    func testLibraryASnapshotDark() throws {
        assertSnapshot(of: try openLibraryWithCollections(appearance: .dark), named: "Library-A")
    }

    private func openLibraryWithCollections(appearance: XCUIDevice.Appearance) throws -> LibraryScreen {
        var configuration = try seeded(allFixtures)
        configuration.collections = [
            FixtureCollection(name: "Classics", books: [.german, .frenchNoCover]),
            FixtureCollection(name: "German", books: [.german]),
        ]
        let library = HomeScreen(app: launch(configuration, appearance: appearance)).waitUntilShown().openLibrary()
        library.allChip.waitUntil(\.isSelected, equals: true)
        return library
    }

    private func openLibrary(appearance: XCUIDevice.Appearance) throws -> LibraryScreen {
        let app = launch(try seeded(allFixtures), appearance: appearance)
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        library.book("Un matin en ville").waitUntilExists()
        return library
    }

    private func seeded(_ fixtures: [Fixture]) throws -> LaunchConfiguration {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = fixtures
        configuration.now = try Date("2026-03-14T09:30:00Z", strategy: .iso8601)
        return configuration
    }
}
