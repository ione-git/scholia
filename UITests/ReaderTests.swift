import XCTest

final class ReaderTests: UITestCase {
    private let bookPages = 54
    private let firstChapterPages = 18

    func testOpensHeroBookOnFirstPage() {
        let home = HomeScreen(app: launchWithGermanBook()).waitUntilShown()

        let reader = home.openHeroBook()

        reader.pageCounter.waitUntil(\.label, equals: "1 of \(bookPages)")
        XCTAssertEqual(reader.root.label, "Die Verwandlung")
        reader.paragraph(startingWith: "Als Gregor Samsa").waitUntilExists()
        XCTAssertFalse(reader.backButton.exists)
        attachScreenshot("Reader")
    }

    func testSwipesTurnPagesAcrossChaptersWithBookWideCounter() {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()

        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnBackward(expecting: "1 of \(bookPages)")
        for page in 2...firstChapterPages + 1 {
            reader.turnForward(expecting: "\(page) of \(bookPages)")
        }
        reader.turnBackward(expecting: "\(firstChapterPages) of \(bookPages)")
    }

    func testCounterIsCurrentAsSoonAsSwipeEnds() {
        let app = launchWithGermanBook()
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.pageCounter.waitUntil(\.label, equals: "1 of \(bookPages)")

        for page in 2...4 {
            app.swipeLeft()
            XCTAssertEqual(reader.pageCounter.label, "\(page) of \(bookPages)")
        }
        app.swipeRight()
        XCTAssertEqual(reader.pageCounter.label, "3 of \(bookPages)")
    }

    func testReopensAtSamePageAfterCloseAndRelaunch() {
        let app = launchWithGermanBook()
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.turnForward(expecting: "2 of \(bookPages)")
        reader.turnForward(expecting: "3 of \(bookPages)")

        let home = reader.backToHome()
        home.heroProgress.waitUntil(\.stringValue, equals: percent(3))

        let reopened = home.openHeroBook()
        reopened.pageCounter.waitUntil(\.label, equals: "3 of \(bookPages)")
        reopened.turnForward(expecting: "4 of \(bookPages)")
        app.terminate()

        let relaunched = launch(
            LaunchConfiguration(resetsState: false, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let relaunchedHome = HomeScreen(app: relaunched).waitUntilShown()
        relaunchedHome.heroProgress.waitUntil(\.stringValue, equals: percent(4))
        relaunchedHome.openHeroBook().pageCounter.waitUntil(\.label, equals: "4 of \(bookPages)")
    }

    func testReopensInLaterChapterAtSamePage() {
        let app = launchWithGermanBook()
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        for page in 2...firstChapterPages + 2 {
            reader.turnForward(expecting: "\(page) of \(bookPages)")
        }

        let reopened = reader.backToHome().openHeroBook()

        reopened.pageCounter.waitUntil(\.label, equals: "\(firstChapterPages + 2) of \(bookPages)")
    }

    func testOpensFromLibraryAndBackReturnsToLibrary() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .frenchNoCover], opened: [.german], mocksTranslation: true,
                now: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        let reader = library.openBook("Un matin en ville").waitUntilOpened()
        XCTAssertEqual(reader.root.label, "Un matin en ville")
        reader.paragraph(startingWith: "Le matin, la ville").waitUntilExists()

        let back = reader.backToLibrary()
        XCTAssertEqual(back.shownTitles, ["Un matin en ville", "Die Verwandlung"])
        back.goBack().heroTitle.waitUntil(\.label, equals: "Un matin en ville")
    }

    func testTapOnPageMarginTogglesBackButton() {
        let reader = HomeScreen(app: launchWithGermanBook()).waitUntilShown().openHeroBook()

        reader.showChrome()
        XCTAssertEqual(reader.backButton.label, "Back")
        XCTAssertEqual(reader.backButton.frame, CGRect(x: 16, y: 62, width: 44, height: 44))
        attachScreenshot("Reader-Chrome")
        reader.hideChrome()
    }

    func testUnreadableBookShowsFailureWithBackButton() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [.german, .corrupted], opened: [], mocksTranslation: true, now: nil))
        let library = HomeScreen(app: app).waitUntilShown().openLibrary()

        let reader = library.openBook("Corrupted")

        XCTAssertEqual(reader.failure.waitUntilExists().label, "This book can’t be opened.")
        XCTAssertFalse(reader.pageCounter.exists)
        reader.backToLibrary()
    }

    private func launchWithGermanBook() -> XCUIApplication {
        launch(
            LaunchConfiguration(resetsState: true, fixtures: [.german], opened: [], mocksTranslation: true, now: nil))
    }

    private func percent(_ page: Int) -> String {
        (Double(page) / Double(bookPages)).formatted(.percent.precision(.fractionLength(0)))
    }
}
