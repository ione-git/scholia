import XCTest

final class SelectBooksTests: UITestCase {
    private let fixtures: [Fixture] = [.german, .frenchNoCover, .minimalMetadata]

    func testSelectModeCountsSelectedBooks() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: fixtures, opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil, notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        let selection = library.selectBooks()
        XCTAssertEqual(selection.title.label, "Select Books")
        XCTAssertFalse(library.backButton.exists)
        XCTAssertFalse(library.moreButton.exists)
        XCTAssertTrue(library.searchField.exists)
        for button in [selection.collectionButton, selection.finishedButton, selection.removeButton] {
            XCTAssertFalse(button.isEnabled)
        }
        XCTAssertEqual(selection.collectionButton.label, "Collection")
        XCTAssertEqual(selection.finishedButton.label, "Finished")
        XCTAssertEqual(selection.removeButton.label, "Remove")

        selection.toggle("Die Verwandlung").toggle("Minimal")
        XCTAssertEqual(selection.title.label, "2 Selected")
        XCTAssertFalse(selection.book("Un matin en ville").isSelected)
        for button in [selection.collectionButton, selection.finishedButton, selection.removeButton] {
            XCTAssertTrue(button.isEnabled)
        }
        attachScreenshot("Library-Select")

        selection.toggle("Die Verwandlung")
        XCTAssertEqual(selection.title.label, "1 Selected")
        selection.cancel().backButton.waitUntil(\.isHittable, equals: true)
        XCTAssertEqual(library.shownTitles, ["Die Verwandlung", "Minimal", "Un matin en ville"])

        let again = library.selectBooks()
        XCTAssertEqual(again.title.label, "Select Books")
        XCTAssertFalse(again.book("Minimal").isSelected)
        again.toggle("Minimal").done().moreButton.waitUntil(\.isHittable, equals: true)
    }

    func testSelectedBooksAreMarkedFinishedAndUnread() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: fixtures, opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil, notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        library.selectBooks().toggle("Die Verwandlung").toggle("Minimal").toggleFinished()
        library.book("Die Verwandlung").waitUntil(\.stringValue, equals: "Finished")
        XCTAssertEqual(library.book("Minimal").stringValue, "Finished")
        XCTAssertEqual(library.book("Un matin en ville").stringValue, "")

        let mixed = library.selectBooks().toggle("Die Verwandlung").toggle("Un matin en ville")
        XCTAssertEqual(mixed.finishedButton.label, "Finished")
        mixed.cancel()

        let finished = library.selectBooks().toggle("Die Verwandlung").toggle("Minimal")
        XCTAssertEqual(finished.finishedButton.label, "Unread")
        finished.toggleFinished()
        library.book("Die Verwandlung").waitUntil(\.stringValue, equals: "")
        XCTAssertEqual(library.book("Minimal").stringValue, "")
    }

    func testSelectedBooksAreAddedToCollection() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: fixtures, opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil, notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        library.openMenu().openNewCollection().type("Classics").create(returningTo: library)

        let selection = library.selectBooks().toggle("Un matin en ville").toggle("Die Verwandlung")
        let sheet = selection.addToCollection()
        XCTAssertEqual(sheet.bookTitle.label, "Die Verwandlung, Un matin en ville")
        XCTAssertEqual(sheet.bookAuthor.label, "2 books")
        sheet.cancel(returningTo: selection)
        XCTAssertEqual(selection.title.label, "2 Selected")

        selection.addToCollection().toggle("Classics").done(returningTo: library)
        library.collectionChip("Classics").waitUntil(\.label, equals: "Classics, 2")
        library.show(library.collectionChip("Classics"))
        library.book("Minimal").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Die Verwandlung", "Un matin en ville"])

        library.show(library.allChip)
        let mixed = library.selectBooks().toggle("Die Verwandlung").toggle("Minimal").addToCollection()
        XCTAssertFalse(mixed.collection("Classics").isSelected)
        mixed.toggle("Classics").done(returningTo: library)
        library.collectionChip("Classics").waitUntil(\.label, equals: "Classics, 3")

        let shared = library.selectBooks().toggle("Die Verwandlung").toggle("Minimal").addToCollection()
        shared.collection("Classics").waitUntil(\.isSelected, equals: true)
        shared.toggle("Classics").done(returningTo: library)
        library.collectionChip("Classics").waitUntil(\.label, equals: "Classics, 1")
        library.show(library.collectionChip("Classics"))
        XCTAssertEqual(library.shownTitles, ["Un matin en ville"])
    }

    func testSelectedBooksAreRemoved() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: fixtures, opened: [], inProgress: [], highlighted: [],
                translation: .immediate, now: nil, notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        let selection = library.selectBooks().toggle("Die Verwandlung").toggle("Un matin en ville")
        let dialog = selection.remove()
        XCTAssertEqual(
            dialog.texts, ["Remove 2 books from your library?", "The book files will be deleted from this iPhone."])
        dialog.cancel(returningTo: selection)
        XCTAssertEqual(selection.title.label, "2 Selected")

        selection.remove().remove()
        library.book("Die Verwandlung").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Minimal"])
        library.storedLibrary.waitUntil(\.label, equals: "Minimal · no author · en · minimal-metadata.epub")
        XCTAssertEqual(library.storedLibrary.stringValue, "minimal-metadata.epub")
    }

    func testSelectedBooksAreRemovedWithTheirHighlights() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: fixtures, opened: [], inProgress: [], highlighted: fixtures,
                translation: .immediate, now: nil, notificationPermission: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()
        library.storedHighlights.waitUntil(\.label, equals: "21")

        let selection = library.selectBooks().toggle("Die Verwandlung").toggle("Minimal")
        let dialog = selection.remove()
        XCTAssertEqual(
            dialog.texts,
            [
                "Remove 2 books from your library?",
                "The book files and their 14 highlights will be deleted from this iPhone.",
            ])
        dialog.cancel(returningTo: selection)
        XCTAssertEqual(library.storedHighlights.label, "21")

        selection.remove().remove()
        library.book("Die Verwandlung").waitUntilGone()
        XCTAssertEqual(library.shownTitles, ["Un matin en ville"])
        library.storedLibrary.waitUntil(\.label, equals: "Un matin en ville · Scholia · fr · french-no-cover.epub")
        library.storedHighlights.waitUntil(\.label, equals: "7")
    }
}
