import XCTest

final class CollectionsTests: UITestCase {
    func testChipRowIsHiddenUntilACollectionIsCreated() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        library.book("Die Verwandlung").waitUntilExists()
        XCTAssertFalse(library.collectionRow.exists)
        XCTAssertFalse(library.allChip.exists)
        XCTAssertFalse(library.newCollectionChip.exists)

        library.openMenu().openNewCollection().type("Philosophy").create(returningTo: library)

        library.waitUntil(\.collectionChips, equals: ["Philosophy"])
        XCTAssertTrue(library.allChip.isSelected)
        XCTAssertFalse(library.collectionChip("Philosophy").isSelected)
        XCTAssertEqual(library.newCollectionChip.label, "New collection")
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Un matin en ville"])
    }

    func testNewCollectionChipCreatesCollectionsInCreationOrder() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil,
                notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        library.openMenu().openNewCollection().type("Science Fiction").create(returningTo: library)

        let alert = library.newCollection()
        XCTAssertFalse(alert.createButton.isEnabled)
        alert.type("science fiction ")
        alert.nameField.waitUntil(\.stringValue, equals: "science fiction ")
        XCTAssertFalse(alert.createButton.isEnabled)
        alert.type("Biographies")
        alert.createButton.waitUntil(\.isEnabled, equals: true)
        alert.create(returningTo: library)

        library.waitUntil(\.collectionChips, equals: ["Science Fiction", "Biographies"])

        library.newCollection().type("Fiction").cancel(returningTo: library)
        XCTAssertEqual(library.collectionChips, ["Science Fiction", "Biographies"])
    }

    func testChosenCollectionsAreSavedWithBook() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.minimalMetadata], opened: [], inProgress: [], highlighted: [],
                translation: .immediate,
                now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)
        addBook.collectionButton.waitUntil(\.label, equals: "Collection, None")

        let sheet = addBook.chooseCollections()
        sheet.newCollection().type("Classics").create(returningTo: sheet)
        sheet.collection("Classics").waitUntil(\.isSelected, equals: true)
        sheet.newCollection().type("German").create(returningTo: sheet)
        sheet.collection("German").waitUntil(\.isSelected, equals: true)
        sheet.newCollection().type("Poetry").create(returningTo: sheet)
        sheet.toggle("Poetry")
        sheet.waitUntil(\.collections, equals: ["Classics", "German", "Poetry"])
        sheet.done()
        addBook.collectionButton.waitUntil(\.label, equals: "Collection, Classics, German")

        let library = addBook.add().openLibrary()
        library.show(library.collectionChip("Classics"))
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung"])
        library.show(library.collectionChip("Poetry"))
        library.waitUntil(\.shownTitles, equals: [])
    }

    func testCancelKeepsPreviousCollectionChoice() throws {
        let collections = ["Classics", "German", "Poetry"].map { FixtureCollection(name: $0, books: []) }
        let home = HomeScreen(app: launch(seeded([], collections: collections))).waitUntilShown()
        let addBook = try home.openFromOtherApp(.german)
        addBook.chooseCollections().toggle("Classics").toggle("German").done()
        addBook.collectionButton.waitUntil(\.label, equals: "Collection, Classics, German")

        let reopened = addBook.chooseCollections()
        reopened.collection("Classics").waitUntil(\.isSelected, equals: true)
        XCTAssertTrue(reopened.collection("German").isSelected)
        XCTAssertFalse(reopened.collection("Poetry").isSelected)
        reopened.toggle("German").toggle("Poetry").cancel()

        XCTAssertEqual(addBook.collectionButton.label, "Collection, Classics, German")
    }

    func testChipFiltersGridByCollection() {
        let collections = [
            FixtureCollection(name: "Classics", books: [.german, .frenchNoCover]),
            FixtureCollection(name: "German", books: [.german]),
        ]
        let app = launch(seeded([.german, .frenchNoCover, .minimalMetadata], collections: collections))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Minimal", "Un matin en ville"])

        library.show(library.collectionChip("Classics"))
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Un matin en ville"])
        XCTAssertFalse(library.allChip.isSelected)

        library.search("matin")
        library.waitUntil(\.shownTitles, equals: ["Un matin en ville"])
        library.search("")
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Un matin en ville"])

        library.show(library.collectionChip("German"))
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung"])
        XCTAssertFalse(library.collectionChip("Classics").isSelected)

        library.show(library.allChip)
        library.waitUntil(\.shownTitles, equals: ["Die Verwandlung", "Minimal", "Un matin en ville"])
        XCTAssertFalse(library.collectionChip("German").isSelected)
    }

    func testLibraryAddToSnapshotLight() throws {
        assertSnapshot(of: try openAddToCollection(appearance: .light), named: "Library-AddTo")
    }

    func testLibraryAddToSnapshotDark() throws {
        assertSnapshot(of: try openAddToCollection(appearance: .dark), named: "Library-AddTo")
    }

    private func openAddToCollection(appearance: XCUIDevice.Appearance) throws -> AddToCollectionScreen {
        var configuration = seeded(
            [.german, .frenchNoCover, .minimalMetadata, .corrupted, .drm],
            collections: [
                FixtureCollection(name: "Classics", books: [.german, .frenchNoCover]),
                FixtureCollection(name: "German", books: [.german]),
                FixtureCollection(name: "Poetry", books: []),
            ])
        configuration.now = try Date("2026-03-14T09:30:00Z", strategy: .iso8601)
        let library = HomeScreen(app: launch(configuration, appearance: appearance)).waitUntilShown().openLibrary()
        let sheet = library.openBookMenu("Die Verwandlung").addToCollection()
        sheet.collection("German").waitUntil(\.isSelected, equals: true)
        return sheet
    }

    private func seeded(_ fixtures: [Fixture], collections: [FixtureCollection]) -> LaunchConfiguration {
        var configuration = LaunchConfiguration.withoutBooks
        configuration.fixtures = fixtures
        configuration.collections = collections
        return configuration
    }
}
