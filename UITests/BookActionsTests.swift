import XCTest

final class BookActionsTests: UITestCase {
    func testLongPressShowsBookActions() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover], opened: [], inProgress: [],
                mocksTranslation: true, now: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        let menu = library.openBookMenu("Die Verwandlung")
        XCTAssertEqual(menu.addToCollectionButton.label, "Add to Collection")
        XCTAssertEqual(menu.finishedButton.label, "Mark as Finished")
        XCTAssertEqual(menu.infoButton.label, "Book Info")
        XCTAssertEqual(menu.removeButton.label, "Remove from Library")
        XCTAssertLessThan(menu.addToCollectionButton.frame.minY, menu.finishedButton.frame.minY)
        XCTAssertLessThan(menu.finishedButton.frame.minY, menu.infoButton.frame.minY)
        XCTAssertLessThan(menu.infoButton.frame.minY, menu.removeButton.frame.minY)
        attachScreenshot("Library-Menu")
    }

    func testMarkAsFinishedTogglesBadgeAndMenuItem() {
        let first = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover], opened: [], inProgress: [],
                mocksTranslation: true, now: nil))
        let library = HomeScreen(app: first).waitUntilShown().openLibrary()
        XCTAssertEqual(library.book("Die Verwandlung").stringValue, "")

        library.openBookMenu("Die Verwandlung").toggleFinished()
        library.book("Die Verwandlung").waitUntil(\.stringValue, equals: "Finished")
        XCTAssertEqual(library.book("Un matin en ville").stringValue, "")
        attachScreenshot("Library-Finished")
        first.terminate()

        let app = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], mocksTranslation: true, now: nil))
        let reopened = HomeScreen(app: app).waitUntilShown().openLibrary()
        reopened.book("Die Verwandlung").waitUntil(\.stringValue, equals: "Finished")
        let menu = reopened.openBookMenu("Die Verwandlung")
        XCTAssertEqual(menu.finishedButton.label, "Mark as Unread")
        menu.toggleFinished()
        reopened.book("Die Verwandlung").waitUntil(\.stringValue, equals: "")
        XCTAssertEqual(reopened.openBookMenu("Die Verwandlung").finishedButton.label, "Mark as Finished")
    }

    func testAddToCollectionFromMenu() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover], opened: [], inProgress: [],
                mocksTranslation: true, now: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        library.openMenu().openNewCollection().type("Classics").create(returningTo: library)
        library.collectionChip("Classics").waitUntil(\.label, equals: "Classics, 0")

        let sheet = library.openBookMenu("Die Verwandlung").addToCollection()
        XCTAssertEqual(sheet.bookTitle.label, "Die Verwandlung")
        XCTAssertEqual(sheet.bookAuthor.label, "Franz Kafka")
        XCTAssertEqual(sheet.collections, ["Classics"])
        XCTAssertFalse(sheet.collection("Classics").isSelected)
        sheet.toggle("Classics")
        attachScreenshot("Library-AddTo")
        sheet.done(returningTo: library)
        library.collectionChip("Classics").waitUntil(\.label, equals: "Classics, 1")

        library.show(library.collectionChip("Classics"))
        library.book("Un matin en ville").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Die Verwandlung"])

        let again = library.openBookMenu("Die Verwandlung").addToCollection()
        again.collection("Classics").waitUntil(\.isSelected, equals: true)
        again.toggle("Classics").cancel(returningTo: library)
        XCTAssertEqual(library.collectionChip("Classics").label, "Classics, 1")

        library.openBookMenu("Die Verwandlung").addToCollection().toggle("Classics").done(returningTo: library)
        library.book("Die Verwandlung").waitUntilGone()
        XCTAssertEqual(library.collectionChip("Classics").label, "Classics, 0")
        XCTAssertEqual(library.shownTitles, [])
    }

    func testBookInfoShowsBookDetails() throws {
        let added = try Date("2026-09-12T12:00:00Z", strategy: .iso8601)
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], mocksTranslation: true, now: added))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        let info = library.openBookMenu("Die Verwandlung").openInfo()
        XCTAssertEqual(info.cover.label, "Die Verwandlung")
        info.fileInfo.waitUntil(
            \.label,
            equals:
                "\(try Fixture.german.fileInfo) · added \(added.formatted(.dateTime.day().month(.abbreviated).year()))")
        XCTAssertEqual(info.titleField.stringValue, "Die Verwandlung")
        XCTAssertEqual(info.authorField.stringValue, "Franz Kafka")
        XCTAssertEqual(info.languageButton.label, "Language, German")
        XCTAssertEqual(info.collectionsButton.label, "Collections, None")
        XCTAssertEqual(info.progress.label, "Progress, Not started")
        XCTAssertEqual(info.highlights.label, "Highlights, 0")
        XCTAssertEqual(info.resetProgressButton.label, "Reset reading progress")
        XCTAssertFalse(info.resetProgressButton.isEnabled)
        XCTAssertLessThan(info.cover.frame.maxY, info.titleField.frame.minY)
        XCTAssertLessThan(info.authorField.frame.maxY, info.languageButton.frame.minY)
        XCTAssertLessThan(info.collectionsButton.frame.maxY, info.progress.frame.minY)
        XCTAssertLessThan(info.highlights.frame.maxY, info.resetProgressButton.frame.minY)
        attachScreenshot("Library-Info")
    }

    func testBookInfoResetsReadingProgress() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [.german], mocksTranslation: true,
                now: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        let info = library.openBookMenu("Die Verwandlung").openInfo()
        XCTAssertEqual(info.progress.label, "Progress, In progress")
        XCTAssertTrue(info.resetProgressButton.isEnabled)
        info.resetProgress()
        info.progress.waitUntil(\.label, equals: "Progress, Not started")
        info.resetProgressButton.waitUntil(\.isEnabled, equals: false)
        info.cancel()

        let cancelled = library.openBookMenu("Die Verwandlung").openInfo()
        XCTAssertEqual(cancelled.progress.label, "Progress, In progress")
        XCTAssertTrue(cancelled.resetProgressButton.isEnabled)
        cancelled.resetProgress().done()

        let saved = library.openBookMenu("Die Verwandlung").openInfo()
        XCTAssertEqual(saved.progress.label, "Progress, Not started")
        XCTAssertFalse(saved.resetProgressButton.isEnabled)
    }

    func testBookInfoSavesEdits() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover], opened: [], inProgress: [],
                mocksTranslation: true, now: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        library.openMenu().openNewCollection().type("Classics").create(returningTo: library)

        let info = library.openBookMenu("Die Verwandlung").openInfo()
        try info.replaceTitle(with: "Metamorphosis").replaceAuthor(with: "F. Kafka")
        info.cover.waitUntil(\.label, equals: "Metamorphosis")
        info.chooseLanguage().choose("fr", returningTo: info)
        info.languageButton.waitUntil(\.label, equals: "Language, French")
        info.chooseCollections().toggle("Classics").done(returningTo: info)
        info.collectionsButton.waitUntil(\.label, equals: "Collections, Classics")
        info.done()

        library.book("Metamorphosis").waitUntilExists()
        XCTAssertFalse(library.book("Die Verwandlung").exists)
        XCTAssertEqual(library.collectionChip("Classics").label, "Classics, 1")
        library.storedLibrary.waitUntil(
            \.label,
            equals: """
                Metamorphosis · F. Kafka · fr · german.epub
                Un matin en ville · Scholia · fr · french-no-cover.epub
                """)

        let reopened = library.openBookMenu("Metamorphosis").openInfo()
        XCTAssertEqual(reopened.titleField.stringValue, "Metamorphosis")
        XCTAssertEqual(reopened.authorField.stringValue, "F. Kafka")
        XCTAssertEqual(reopened.languageButton.label, "Language, French")
        XCTAssertEqual(reopened.collectionsButton.label, "Collections, Classics")
    }

    func testBookInfoCancelDiscardsEdits() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german], opened: [], inProgress: [], mocksTranslation: true, now: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        let info = library.openBookMenu("Die Verwandlung").openInfo()
        try info.replaceTitle(with: " ")
        info.doneButton.waitUntil(\.isEnabled, equals: false)
        try info.replaceTitle(with: "Metamorphosis")
        info.doneButton.waitUntil(\.isEnabled, equals: true)
        info.chooseLanguage().choose("en", returningTo: info)
        info.languageButton.waitUntil(\.label, equals: "Language, English")
        info.cancel()

        XCTAssertEqual(library.shownTitles, ["Die Verwandlung"])
        library.storedLibrary.waitUntil(\.label, equals: "Die Verwandlung · Franz Kafka · de · german.epub")
        let reopened = library.openBookMenu("Die Verwandlung").openInfo()
        XCTAssertEqual(reopened.titleField.stringValue, "Die Verwandlung")
        XCTAssertEqual(reopened.languageButton.label, "Language, German")
    }

    func testRemoveAsksThenDeletesBookAndFile() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover], opened: [], inProgress: [],
                mocksTranslation: true, now: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        library.storedLibrary.waitUntil(\.stringValue, equals: "french-no-cover.epub\ngerman.epub")

        let dialog = library.openBookMenu("Die Verwandlung").remove()
        XCTAssertEqual(
            dialog.texts,
            ["Remove “Die Verwandlung” from your library?", "The book file will be deleted from this iPhone."])
        attachScreenshot("Library-Remove")
        dialog.cancel(returningTo: library)
        XCTAssertEqual(library.shownTitles, ["Die Verwandlung", "Un matin en ville"])
        XCTAssertEqual(library.storedLibrary.stringValue, "french-no-cover.epub\ngerman.epub")

        library.openBookMenu("Die Verwandlung").remove().remove()
        library.book("Die Verwandlung").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Un matin en ville"])
        library.storedLibrary.waitUntil(\.label, equals: "Un matin en ville · Scholia · fr · french-no-cover.epub")
        XCTAssertEqual(library.storedLibrary.stringValue, "french-no-cover.epub")
        library.goBack().libraryButton.waitUntil(\.label, equals: "Library, All 1")
    }
}
