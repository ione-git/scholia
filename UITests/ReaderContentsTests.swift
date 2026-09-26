import XCTest

final class ReaderContentsTests: UITestCase {
    private let bookPages = 54
    private let chapters = [("Erster Teil", 1), ("Zweiter Teil", 19), ("Dritter Teil", 37)]
    private let frenchBookPages = 10
    private let frenchChapters = [("Premier chapitre", 1), ("Deuxième chapitre", 5)]
    private let rowHeight: CGFloat = 56

    func testListsChaptersInOrderWithStartPagesAndMarksCurrent() {
        let reader = openGermanBook()
        reader.showChrome()

        let contents = reader.openMenu().open("contents")

        contents.tab("contents").waitUntil(\.isSelected, equals: true)
        XCTAssertEqual(contents.chapters.map(\.label), chapters.map(\.0))
        for (index, (_, page)) in chapters.enumerated() {
            contents.chapter(at: index).waitUntil(\.stringValue, equals: "Page \(page)")
        }
        XCTAssertEqual(contents.chapter(at: 0).frame.height, rowHeight, accuracy: 0.5)
        XCTAssertTrue(contents.chapter(at: 0).isSelected)
        XCTAssertFalse(contents.chapter(at: 1).isSelected)
        XCTAssertFalse(contents.chapter(at: 2).isSelected)
    }

    func testJumpLandsOnChapterStartWithChromeAndIsKeptOnReopen() {
        let (title, page) = chapters[2]
        var reader = openGermanBook()
        reader.showChrome()
        var contents = reader.openMenu().open("contents")
        contents.chapter(at: 2).waitUntil(\.stringValue, equals: "Page \(page)")

        reader = contents.jump(to: 2)

        reader.pageCounter.waitUntil(\.label, equals: "\(page) of \(bookPages)")
        reader.subtitle.waitUntil(\.label, equals: "Franz Kafka · \(title)")
        reader.backButton.waitUntil(\.isHittable, equals: true)

        contents = reader.openMenu().open("contents")
        contents.chapter(at: 2).waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(contents.chapter(at: 0).isSelected)
        reader = contents.done()

        reader = reader.backToHome().openHeroBook()
        reader.pageCounter.waitUntil(\.label, equals: "\(page) of \(bookPages)")
    }

    func testChapterSharingAFileHasItsOwnStartPageAndJumpLandsThere() {
        let (title, page) = frenchChapters[1]
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.frenchNoCover], opened: [], mocksTranslation: true, now: nil))
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.showChrome()
        reader.subtitle.waitUntil(\.label, equals: "Scholia · \(frenchChapters[0].0)")
        var contents = reader.openMenu().open("contents")
        XCTAssertEqual(contents.chapters.map(\.label), frenchChapters.map(\.0))
        contents.chapter(at: 0).waitUntil(\.stringValue, equals: "Page \(frenchChapters[0].1)")
        contents.chapter(at: 1).waitUntil(\.stringValue, equals: "Page \(page)")

        contents.jump(to: 1)

        reader.pageCounter.waitUntil(\.label, equals: "\(page) of \(frenchBookPages)")
        reader.subtitle.waitUntil(\.label, equals: "Scholia · \(title)")
        contents = reader.openMenu().open("contents")
        contents.chapter(at: 1).waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(contents.chapter(at: 0).isSelected)
    }

    func testTabsCountHighlightsAndBookmarks() {
        let reader = openGermanBook()
        reader.showChrome()
        bookmarkThisAndNextPage(reader, next: "2 of \(bookPages)")

        let index = reader.openMenu().open("bookmarks")

        index.tab("bookmarks").waitUntil(\.isSelected, equals: true)
        XCTAssertEqual(index.tab("bookmarks").label, "Bookmarks, 2")
        XCTAssertEqual(index.tab("highlights").label, "Highlights, 0")
        XCTAssertEqual(index.tab("contents").label, "Contents")
    }

    func testContentsScreenshotsInPaperAndNight() {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        let page = chapters[1].1
        for appearance in [XCUIDevice.Appearance.light, .dark] {
            XCUIDevice.shared.appearance = appearance
            let suffix = appearance == .dark ? "-Dark" : ""
            let reader = openGermanBook()
            reader.showChrome()
            reader.openMenu().open("contents").jump(to: 1)
            reader.pageCounter.waitUntil(\.label, equals: "\(page) of \(bookPages)")
            bookmarkThisAndNextPage(reader, next: "\(page + 1) of \(bookPages)")

            let contents = reader.openMenu().open("contents")

            contents.chapter(at: 1).waitUntil(\.isSelected, equals: true)
            contents.chapter(at: 2).waitUntil(\.stringValue, equals: "Page \(chapters[2].1)")
            attachScreenshot("Reader-Contents-2\(suffix)")
            reader.app.terminate()
        }
    }

    private func bookmarkThisAndNextPage(_ reader: ReaderScreen, next: String) {
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        reader.turnForward(expecting: next)
        reader.bookmarkButton.waitUntil(\.isSelected, equals: false)
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
    }

    private func openGermanBook() -> ReaderScreen {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: nil))
        return HomeScreen(app: app).waitUntilShown().openHeroBook()
    }
}
