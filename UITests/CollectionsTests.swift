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

        let alert = library.openMenu().openNewCollection()
        XCTAssertEqual(alert.root.label, "New Collection")
        alert.type("Philosophy").create(returningTo: library)

        library.collectionRow.waitUntilExists()
        XCTAssertEqual(library.collectionChips, ["Philosophy"])
        XCTAssertEqual(library.allChip.label, "All, 2")
        XCTAssertEqual(library.collectionChip("Philosophy").label, "Philosophy, 0")
        XCTAssertTrue(library.allChip.isSelected)
        XCTAssertFalse(library.collectionChip("Philosophy").isSelected)
        XCTAssertEqual(library.newCollectionChip.label, "New collection")
        XCTAssertEqual(library.shownTitles, ["Die Verwandlung", "Un matin en ville"])
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
        attachScreenshot("Library-NewCollection")
        alert.create(returningTo: library)

        library.collectionChip("Biographies").waitUntilExists()
        XCTAssertEqual(library.collectionChips, ["Science Fiction", "Biographies"])
        XCTAssertLessThan(library.allChip.frame.maxX, library.collectionChip("Science Fiction").frame.minX)
        XCTAssertLessThan(
            library.collectionChip("Biographies").frame.maxX, library.newCollectionChip.frame.minX)

        library.newCollection().type("Fiction").cancel(returningTo: library)
        XCTAssertEqual(library.collectionChips, ["Science Fiction", "Biographies"])
    }

    func testAddBookCollectionRowAddsBookToChosenCollections() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.minimalMetadata], opened: [], inProgress: [], highlighted: [],
                translation: .immediate,
                now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)
        addBook.collectionButton.waitUntil(\.label, equals: "Collection, None")

        let sheet = addBook.chooseCollections()
        XCTAssertEqual(sheet.bookTitle.label, "Die Verwandlung")
        XCTAssertEqual(sheet.bookAuthor.label, "Franz Kafka")
        XCTAssertEqual(sheet.collections, [])
        sheet.newCollection().type("Classics").create(returningTo: sheet)
        sheet.collection("Classics").waitUntil(\.isSelected, equals: true)
        sheet.newCollection().type("German").create(returningTo: sheet)
        sheet.collection("German").waitUntil(\.isSelected, equals: true)
        sheet.newCollection().type("Poetry").create(returningTo: sheet)
        sheet.toggle("Poetry")
        XCTAssertEqual(sheet.collections, ["Classics", "German", "Poetry"])
        attachScreenshot("Library-AddTo")
        sheet.done()
        addBook.collectionButton.waitUntil(\.label, equals: "Collection, Classics, German")

        let reopened = addBook.chooseCollections()
        reopened.collection("Classics").waitUntil(\.isSelected, equals: true)
        XCTAssertTrue(reopened.collection("German").isSelected)
        XCTAssertFalse(reopened.collection("Poetry").isSelected)
        reopened.toggle("German").toggle("Poetry").cancel()
        addBook.collectionButton.waitUntil(\.label, equals: "Collection, Classics, German")

        let library = addBook.add().openLibrary()
        XCTAssertEqual(library.collectionChips, ["Classics", "German", "Poetry"])
        XCTAssertEqual(library.allChip.label, "All, 2")
        XCTAssertEqual(library.collectionChip("Classics").label, "Classics, 1")
        XCTAssertEqual(library.collectionChip("German").label, "German, 1")
        XCTAssertEqual(library.collectionChip("Poetry").label, "Poetry, 0")
    }

    func testAddToCollectionSheetShowsAuthorWhenTitleIsEmpty() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))
        let addBook = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.german)
        addBook.authorField.waitUntil(\.stringValue, equals: "Franz Kafka")

        try addBook.replaceTitle(with: " ")
        addBook.addButton.waitUntil(\.isEnabled, equals: false)

        let sheet = addBook.chooseCollections()
        XCTAssertEqual(sheet.bookAuthor.label, "Franz Kafka")
    }

    func testChipFiltersGridByCollection() throws {
        let first = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.minimalMetadata], opened: [], inProgress: [], highlighted: [],
                translation: .immediate,
                now: nil,
                notificationPermission: nil))
        let german = try HomeScreen(app: first).waitUntilShown().openFromOtherApp(.german).chooseCollections()
        german.newCollection().type("Classics").create(returningTo: german)
        german.newCollection().type("German").create(returningTo: german)
        german.done().add()
        let app = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))
        let french = try HomeScreen(app: app).waitUntilShown().openFromOtherApp(.frenchNoCover).chooseCollections()
        french.collection("Classics").waitUntil(\.isSelected, equals: false)
        let home = french.toggle("Classics").done().add()

        let library = home.openLibrary()
        XCTAssertEqual(library.shownTitles, ["Un matin en ville", "Die Verwandlung", "Minimal"])
        XCTAssertEqual(library.allChip.label, "All, 3")
        XCTAssertEqual(library.collectionChip("Classics").label, "Classics, 2")
        XCTAssertEqual(library.collectionChip("German").label, "German, 1")
        attachScreenshot("Library-A")

        library.show(library.collectionChip("Classics"))
        library.book("Minimal").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Un matin en ville", "Die Verwandlung"])
        XCTAssertFalse(library.allChip.isSelected)

        library.search("matin")
        library.book("Die Verwandlung").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Un matin en ville"])
        library.search("")
        library.book("Die Verwandlung").waitUntilExists()

        library.show(library.collectionChip("German"))
        library.book("Un matin en ville").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Die Verwandlung"])
        XCTAssertFalse(library.collectionChip("Classics").isSelected)

        library.show(library.allChip)
        library.book("Minimal").waitUntilExists()
        XCTAssertEqual(library.shownTitles, ["Un matin en ville", "Die Verwandlung", "Minimal"])
        XCTAssertFalse(library.collectionChip("German").isSelected)
    }
}
