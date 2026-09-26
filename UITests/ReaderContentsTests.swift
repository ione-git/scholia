import XCTest

final class ReaderContentsTests: UITestCase {
    private let bookPages = 54
    private let germanChapters = ["Erster Teil", "Zweiter Teil", "Dritter Teil"]
    private let germanStartPages = ["Page 1", "Page 19", "Page 37"]
    private let arabicBookPages = 9
    private let arabicChapters = ["الفصل الأول", "الفصل الثاني", "الفصل الثالث"]
    private let arabicStartPages = ["Page 1", "Page 4", "Page 7"]
    private let frenchBookPages = 10
    private let frenchSecondChapterPage = 5

    func testContentsListsFixtureChaptersWithStartPages() {
        let contents = openContents(.german).waitUntilStartPagesShown()

        XCTAssertEqual(contents.chapters.map(\.label), germanChapters)
        XCTAssertEqual(contents.chapters.map(\.stringValue), germanStartPages)
    }

    func testContentsListsRightToLeftChaptersWithStartPages() {
        let contents = openContents(.arabic).waitUntilStartPagesShown()

        XCTAssertEqual(contents.chapters.map(\.label), arabicChapters)
        XCTAssertEqual(contents.chapters.map(\.stringValue), arabicStartPages)
    }

    func testCurrentChapterIsMarked() {
        let contents = openContents(.german)

        contents.chapter(at: 0).waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(contents.chapter(at: 1).isSelected)
        XCTAssertFalse(contents.chapter(at: 2).isSelected)
    }

    func testTappingChapterJumpsToItsStart() {
        let contents = openContents(.german).waitUntilStartPagesShown()

        let reader = contents.jump(toChapterAt: 1)

        reader.pageCounter.waitUntil(\.label, equals: "19 of \(bookPages)")
        reader.subtitle.waitUntil(\.label, equals: "Franz Kafka · Zweiter Teil")
        let reopened = reader.openMenu().open("contents")
        reopened.chapter(at: 1).waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(reopened.chapter(at: 0).isSelected)
    }

    func testTappingChapterInRightToLeftBookJumpsToItsStart() {
        let contents = openContents(.arabic).waitUntilStartPagesShown()

        let reader = contents.jump(toChapterAt: 2)

        reader.pageCounter.waitUntil(\.label, equals: "7 of \(arabicBookPages)")
        reader.subtitle.waitUntil(\.label, equals: "Scholia · \u{2068}\(arabicChapters[2])\u{2069}")
    }

    func testTappingChapterThatSharesAFileJumpsToIt() {
        let contents = openContents(.frenchNoCover).waitUntilStartPagesShown()
        XCTAssertEqual(contents.chapter(at: 1).stringValue, "")

        let reader = contents.jump(toChapterAt: 1)

        reader.pageCounter.waitUntil(\.label, equals: "\(frenchSecondChapterPage) of \(frenchBookPages)")
        reader.subtitle.waitUntil(\.label, equals: "Scholia · Deuxième chapitre")
        reader.openMenu().open("contents").chapter(at: 1).waitUntil(\.isSelected, equals: true)
    }

    func testTabsShowHighlightAndBookmarkCounts() {
        let reader = openBook(.german)
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)

        let index = reader.openMenu().open("contents")

        XCTAssertEqual(index.tab("highlights").label, "Highlights, 0")
        XCTAssertEqual(index.tab("bookmarks").label, "Bookmarks, 1")
    }

    private func openContents(_ fixture: Fixture) -> ReaderIndexScreen {
        openBook(fixture).openMenu().open("contents")
    }

    private func openBook(_ fixture: Fixture) -> ReaderScreen {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [fixture], opened: [], mocksTranslation: true, now: nil))
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.showChrome()
        return reader
    }
}
