import XCTest

final class ReaderChromeTests: UITestCase {
    private let bookPages = 54
    private let arabicBookPages = 9
    private let arabicChapterPages = 3
    private let frenchBookPages = 10
    private let menuEntries = ["Contents", "Highlights", "Bookmarks", "Themes & Settings"]

    func testChromeIsHiddenOnOpenAndMarginTapTogglesIt() {
        let reader = openGermanBook()
        XCTAssertEqual(reader.runningHead.label, "Die Verwandlung")
        for element in [reader.backButton, reader.bookmarkButton, reader.menuButton, reader.title] {
            XCTAssertFalse(element.exists, element.description)
        }

        reader.showChrome()

        XCTAssertEqual(reader.backButton.frame, CGRect(x: 16, y: 62, width: 44, height: 44))
        XCTAssertEqual(reader.bookmarkButton.waitUntilExists().label, "Bookmark this page")
        XCTAssertEqual(
            reader.bookmarkButton.frame, CGRect(x: reader.app.frame.width - 60, y: 62, width: 44, height: 44))
        XCTAssertEqual(reader.menuButton.waitUntilExists().label, "Menu")
        XCTAssertEqual(reader.menuButton.frame.size, CGSize(width: 48, height: 48))
        XCTAssertEqual(reader.menuButton.frame.maxX, reader.app.frame.width - 20)
        XCTAssertEqual(reader.menuButton.frame.maxY, reader.app.frame.height - 24)
        XCTAssertEqual(reader.menuButton.frame.midY, reader.pageCounter.frame.midY, accuracy: 0.5)
        XCTAssertEqual(reader.title.label, "Die Verwandlung")
        reader.subtitle.waitUntil(\.label, equals: "Franz Kafka · Erster Teil")
        reader.runningHead.waitUntilGone()

        reader.hideChrome()

        for element in [reader.bookmarkButton, reader.menuButton, reader.title, reader.subtitle] {
            element.waitUntilGone()
        }
        XCTAssertEqual(reader.runningHead.waitUntilExists().label, "Die Verwandlung")
    }

    func testSubtitleFollowsChapterAndChromeStaysAcrossPageTurns() {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [.arabic], opened: [], mocksTranslation: true, now: nil))
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.showChrome()
        reader.subtitle.waitUntil(\.label, equals: "Scholia · \(isolated("الفصل الأول"))")

        for page in 2...arabicChapterPages + 1 {
            reader.turnForwardRightToLeft(expecting: "\(page) of \(arabicBookPages)")
        }

        reader.subtitle.waitUntil(\.label, equals: "Scholia · \(isolated("الفصل الثاني"))")
        XCTAssertTrue(reader.backButton.isHittable)
        XCTAssertEqual(reader.title.label, "صباح في المدينة")
    }

    func testBookWithoutAuthorShowsChapterOnly() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.minimalMetadata], opened: [], mocksTranslation: true, now: nil))
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()

        reader.showChrome()

        XCTAssertEqual(reader.title.label, "Minimal")
        reader.subtitle.waitUntil(\.label, equals: "Chapter One")
    }

    func testSubtitleFollowsChaptersThatShareOneFile() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.frenchNoCover], opened: [], mocksTranslation: true, now: nil))
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.showChrome()
        reader.subtitle.waitUntil(\.label, equals: "Scholia · Premier chapitre")

        for page in 2...frenchBookPages {
            reader.turnForward(expecting: "\(page) of \(frenchBookPages)")
        }

        reader.subtitle.waitUntil(\.label, equals: "Scholia · Deuxième chapitre")
    }

    func testMenuShowsFourEntriesWithoutSearch() {
        let reader = openGermanBook()
        reader.showChrome()

        let menu = reader.openMenu()

        XCTAssertEqual(menu.entries.map(\.label), menuEntries)
        reader.menuButton.waitUntil(\.isSelected, equals: true)
    }

    func testMenuEntriesOpenTheirTabAndDoneReturnsWithChrome() {
        let reader = openGermanBook()
        reader.showChrome()

        for tab in ["contents", "highlights", "bookmarks"] {
            let index = reader.openMenu().open(tab)

            index.tab(tab).waitUntil(\.isSelected, equals: true)
            for other in ["contents", "highlights", "bookmarks"] where other != tab {
                XCTAssertFalse(index.tab(other).isSelected, other)
            }
            XCTAssertEqual(index.title.label, "Die Verwandlung")
            XCTAssertEqual(index.subtitle.label, "Franz Kafka")

            index.done()
            reader.backButton.waitUntil(\.isHittable, equals: true)
            XCTAssertFalse(reader.menuButton.isSelected)
        }
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(bookPages)")
    }

    func testThemesAndSettingsOpensSheet() {
        let reader = openGermanBook()
        reader.showChrome()

        let settings = reader.openMenu().openSettings()

        XCTAssertTrue(settings.root.exists)
        XCTAssertFalse(ReaderMenuScreen(app: reader.app).root.exists)
    }

    func testOpenMenuBlocksPageAndTapOutsideClosesItKeepingChrome() {
        let reader = openGermanBook()
        reader.showChrome()
        let menu = reader.openMenu()

        reader.app.swipeLeft()

        XCTAssertEqual(reader.pageCounter.label, "1 of \(bookPages)")
        XCTAssertTrue(menu.root.exists)

        menu.closeByTappingOutside()

        reader.menuButton.waitUntil(\.isSelected, equals: false)
        XCTAssertTrue(reader.backButton.isHittable)
        XCTAssertEqual(reader.pageCounter.label, "1 of \(bookPages)")
    }

    func testBookmarkMarksOnlyItsPage() {
        let reader = openGermanBook()
        reader.showChrome()

        reader.toggleBookmark()

        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        XCTAssertEqual(reader.bookmarkButton.label, "Bookmarked. Remove bookmark")
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.bookmarkButton.waitUntil(\.isEnabled, equals: true)
        XCTAssertFalse(reader.bookmarkButton.isSelected)
        XCTAssertEqual(reader.bookmarkButton.label, "Bookmark this page")
        reader.turnBackward(expecting: "1 of \(bookPages)")
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
    }

    func testBookmarkPersistsAcrossReopenAndRelaunchAndSoDoesItsRemoval() {
        var app = launchWithGermanBook()
        var reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.showChrome()
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)

        reader = reader.backToHome().openHeroBook()
        reader.pageCounter.waitUntil(\.label, equals: "2 of \(bookPages)")
        reader.showChrome()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        app.terminate()

        app = relaunch()
        reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.pageCounter.waitUntil(\.label, equals: "2 of \(bookPages)")
        reader.showChrome()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
        reader.toggleBookmark()
        reader.bookmarkButton.waitUntil(\.isSelected, equals: false)
        app.terminate()

        app = relaunch()
        reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.pageCounter.waitUntil(\.label, equals: "2 of \(bookPages)")
        reader.showChrome()
        reader.bookmarkButton.waitUntil(\.isEnabled, equals: true)
        XCTAssertFalse(reader.bookmarkButton.isSelected)
        XCTAssertEqual(reader.bookmarkButton.label, "Bookmark this page")
    }

    func testChromeAndMenuScreenshotsInPaperAndNight() throws {
        let original = XCUIDevice.shared.appearance
        addTeardownBlock { @MainActor in
            XCUIDevice.shared.appearance = original
        }
        let tokens = try TokenValues.load()
        for appearance in [XCUIDevice.Appearance.light, .dark] {
            XCUIDevice.shared.appearance = appearance
            let dark = appearance == .dark
            let suffix = dark ? "-Dark" : ""
            let reader = openGermanBook()
            reader.showChrome()
            reader.toggleBookmark()
            reader.bookmarkButton.waitUntil(\.isSelected, equals: true)
            let pixels = try ScreenPixels(XCUIScreen.main.screenshot(), pointWidth: reader.app.frame.width)
            let page = pixels.color(at: CGPoint(x: 8, y: reader.app.frame.midY))
            let expected = try tokens.color("surface-paper", dark: dark)
            XCTAssertLessThanOrEqual(page.distance(to: expected), 3, "\(page) vs \(expected)")
            attachScreenshot("Reader-Chrome\(suffix)")

            reader.openMenu()
            reader.menuButton.waitUntil(\.isSelected, equals: true)
            attachScreenshot("Reader-Menu\(suffix)")
            reader.app.terminate()
        }
    }

    private func openGermanBook() -> ReaderScreen {
        HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()
    }

    private func launchWithGermanBook() -> XCUIApplication {
        launch(
            LaunchConfiguration(resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: nil))
    }

    private func isolated(_ rightToLeft: String) -> String {
        "\u{2068}\(rightToLeft)\u{2069}"
    }

    private func relaunch() -> XCUIApplication {
        launch(LaunchConfiguration(resetsState: false, fixtures: [], opened: [], mocksTranslation: true, now: nil))
    }
}
