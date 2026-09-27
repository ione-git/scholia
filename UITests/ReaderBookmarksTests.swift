import XCTest

final class ReaderBookmarksTests: UITestCase {
    private let bookPages = 54
    private let secondPartStartPage = 19
    private let frenchBookPages = 10
    private let frenchSecondChapterPage = 5
    private let splitBookPages = 11
    private let splitSecondChapterPage = 5

    func testListShowsBookmarksInReadingOrder() {
        let reader = openBook(.german)
        reader.openMenu().open("contents").waitUntilStartPagesShown().jump(to: "Zweiter Teil")
        reader.pageCounter.waitUntil(\.label, equals: "\(secondPartStartPage) of \(bookPages)")
        reader.turnForward(expecting: "\(secondPartStartPage + 1) of \(bookPages)")
        bookmark(reader)
        reader.openMenu().open("contents").jump(to: "Erster Teil")
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(bookPages)")
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        bookmark(reader)

        let index = reader.openMenu().open("bookmarks")

        index.bookmark(page: secondPartStartPage + 1).waitUntilExists()
        XCTAssertEqual(
            index.bookmarks.map(\.label),
            ["Page 3 · Erster Teil", "Page \(secondPartStartPage + 1) · Zweiter Teil"])
        XCTAssertEqual(index.tab("bookmarks").label, "Bookmarks, 2")
    }

    func testRemovedBookmarkLeavesTheList() {
        let reader = openBook(.german)
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(bookPages)")
        bookmark(reader)
        reader.openMenu().open("bookmarks").bookmark(page: 1).waitUntilExists()
        ReaderIndexScreen(app: reader.app).done()

        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: false)
        let index = reader.openMenu().open("bookmarks")

        XCTAssertEqual(index.tab("bookmarks").label, "Bookmarks, 0")
        XCTAssertEqual(index.bookmarks.count, 0)
    }

    func testTappingBookmarkJumpsToItsPage() {
        let reader = openBook(.german)
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")
        bookmark(reader)
        reader.turnBackward(expecting: "2 of \(bookPages)")

        reader.openMenu().open("bookmarks").jump(toBookmarkOnPage: 3)

        reader.pageCounter.waitUntil(\.label, equals: "3 of \(bookPages)")
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        reader.subtitle.waitUntil(\.label, equals: "Franz Kafka · Erster Teil")
    }

    func testBookmarksSurviveRelaunch() {
        let page = frenchSecondChapterPage + 2
        var reader = openBook(.frenchNoCover)
        reader.openMenu().open("contents").waitUntilStartPagesShown().jump(to: "Deuxième chapitre")
        reader.pageCounter.waitUntil(\.label, equals: "\(frenchSecondChapterPage) of \(frenchBookPages)")
        reader.turnForward(expecting: "\(frenchSecondChapterPage + 1) of \(frenchBookPages)")
        reader.turnForward(expecting: "\(page) of \(frenchBookPages)")
        bookmark(reader)
        reader.app.terminate()

        reader = showChrome(in: relaunch())
        let index = reader.openMenu().open("bookmarks")

        index.bookmark(page: page).waitUntil(\.label, equals: "Page \(page) · Deuxième chapitre")
    }

    func testBookmarkInAFileNotShownSinceLaunchNamesItsOwnChapter() {
        var reader = openBook(.frenchSplit)
        reader.openMenu().open("contents").waitUntilStartPagesShown().jump(to: "Deuxième matin")
        reader.pageCounter.waitUntil(\.label, equals: "\(splitSecondChapterPage) of \(splitBookPages)")
        bookmark(reader)
        reader.openMenu().open("contents").jump(to: "Premier matin")
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(splitBookPages)")
        reader.app.terminate()

        reader = showChrome(in: relaunch())
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(splitBookPages)")
        let index = reader.openMenu().open("bookmarks")

        index.bookmark(page: splitSecondChapterPage).waitUntil(
            \.label, equals: "Page \(splitSecondChapterPage) · Deuxième matin")
    }

    func testReaderBookmarksSnapshotLight() {
        assertSnapshot(of: openBookmarksOnPages3And12(appearance: .light), named: "Reader-Bookmarks")
    }

    func testReaderBookmarksSnapshotDark() {
        assertSnapshot(of: openBookmarksOnPages3And12(appearance: .dark), named: "Reader-Bookmarks")
    }

    private func openBookmarksOnPages3And12(appearance: XCUIDevice.Appearance) -> ReaderIndexScreen {
        let reader = showChrome(in: launch(configuration(with: .german), appearance: appearance))
        for page in 2...12 {
            reader.turnForward(expecting: "\(page) of \(bookPages)")
            if page == 3 || page == 12 {
                bookmark(reader)
            }
        }
        let index = reader.openMenu().open("bookmarks")
        index.bookmark(page: 12).waitUntilExists()
        return index
    }

    private func bookmark(_ reader: ReaderScreen) {
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
    }

    private func openBook(_ fixture: Fixture) -> ReaderScreen {
        showChrome(in: launch(configuration(with: fixture)))
    }

    private func configuration(with fixture: Fixture) -> LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [fixture], opened: [], inProgress: [], highlighted: [],
            translation: .immediate, now: nil, notificationPermission: nil)
    }

    private func relaunch() -> XCUIApplication {
        launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil, notificationPermission: nil))
    }

    private func showChrome(in app: XCUIApplication) -> ReaderScreen {
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.showChrome()
        return reader
    }
}
