import XCTest

final class ReaderHighlightsTests: UITestCase {
    private let bookPages = 54
    private let secondPage = "2 of 54"
    private let secondPageParagraph = "Gregors Blick"
    private let seededFirstRow = "0:77-147"
    private let seededRowValues = [
        "Yellow, Erster Teil, Page 1",
        "Green, Erster Teil, Page 1",
        "Yellow, Erster Teil, Page 1",
        "Blue, Zweiter Teil, Page 20",
        "Pink, Zweiter Teil, Page 20",
        "Purple, Dritter Teil, Page 37",
        "Green, Dritter Teil, Page 37",
    ]
    private let sharedFileRow = "1:267-310"
    private let sharedFileRowValue = "Yellow, Deuxième chapitre, Page 3"

    func testListShowsCreatedHighlightsInBookOrder() throws {
        let reader = openBook(launch(configuration(with: .german)))
        try reader.selectWord(onLine: 6, x: 20).highlight()
        reader.storedHighlights.waitUntil(\.label, equals: "1")
        try reader.selectWord(onLine: 2, x: 20).highlight()
        reader.storedHighlights.waitUntil(\.label, equals: "2")

        let index = openHighlights(reader)

        XCTAssertEqual(index.tab("highlights").label, "Highlights, 2")
        XCTAssertEqual(index.highlights.map(\.label), ["seinem", "braunen"])
    }

    func testRowsShowChapterAndPage() {
        let index = openSeededHighlights(launch(configuration(with: .german, highlighted: true)))

        XCTAssertEqual(index.highlights.map(\.stringValue), seededRowValues)
    }

    func testTappingHighlightJumpsToItsPlace() throws {
        let index = try highlightOnSecondPageThenJumpToThirdChapter(launch(configuration(with: .german)))
            .openMenu().open("highlights")
        index.highlights[0].waitUntil(\.stringValue, equals: "Yellow, Erster Teil, Page 2")

        let jumped = index.jump(toHighlight: index.highlights[0])

        jumped.pageCounter.waitUntil(\.label, equals: secondPage)
        jumped.subtitle.waitUntil(\.label, equals: "Franz Kafka · Erster Teil")
    }

    func testJumpedPlaceIsKeptAfterReopen() throws {
        let index = try highlightOnSecondPageThenJumpToThirdChapter(launch(configuration(with: .german)))
            .openMenu().open("highlights")
        let jumped = index.jump(toHighlight: index.highlights[0])
        jumped.pageCounter.waitUntil(\.label, equals: secondPage)

        let reopened = jumped.backToHome().openHeroBook()

        reopened.pageCounter.waitUntil(\.label, equals: secondPage)
    }

    func testBookInfoCountsCreatedHighlights() throws {
        let reader = openBook(launch(configuration(with: .german)))
        try reader.selectWord(onLine: 2, x: 20).highlight()
        reader.storedHighlights.waitUntil(\.label, equals: "1")

        let info = reader.backToHome().openLibrary().openBookMenu("Die Verwandlung").openInfo()

        XCTAssertEqual(info.highlights.label, "Highlights, 1")
    }

    func testChapterOfHighlightInUnshownSharedFileIsKnown() {
        let app = launch(configuration(with: .frenchSections, highlighted: true))
        let reader = openBook(app)
        openHighlights(reader).highlight(sharedFileRow).waitUntil(\.stringValue, equals: sharedFileRowValue)
        let home = ReaderIndexScreen(app: app).done().backToHome()

        let reopened = openHighlights(home.openHeroBook())

        reopened.highlight(sharedFileRow).waitUntil(\.stringValue, equals: sharedFileRowValue)
    }

    func testReaderHighlightsSnapshotLight() {
        assertSnapshot(of: openSeededHighlights(launch(seededGerman, appearance: .light)), named: "Reader-Highlights")
    }

    func testReaderHighlightsSnapshotDark() {
        assertSnapshot(of: openSeededHighlights(launch(seededGerman, appearance: .dark)), named: "Reader-Highlights")
    }

    private var seededGerman: LaunchConfiguration {
        configuration(with: .german, highlighted: true)
    }

    private func configuration(with fixture: Fixture, highlighted: Bool = false) -> LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [fixture], opened: [], inProgress: [],
            highlighted: highlighted ? [fixture] : [],
            translation: .immediate, now: nil, notificationPermission: nil)
    }

    private func openBook(_ app: XCUIApplication) -> ReaderScreen {
        HomeScreen(app: app).waitUntilShown().openHeroBook().waitUntilOpened()
    }

    private func openHighlights(_ reader: ReaderScreen) -> ReaderIndexScreen {
        reader.showChrome()
        return reader.openMenu().open("highlights")
    }

    private func openSeededHighlights(_ app: XCUIApplication) -> ReaderIndexScreen {
        let index = openHighlights(openBook(app))
        index.highlight(seededFirstRow).waitUntil(\.stringValue, equals: seededRowValues[0])
        return index
    }

    private func highlightOnSecondPageThenJumpToThirdChapter(_ app: XCUIApplication) throws -> ReaderScreen {
        let reader = openBook(app)
        reader.germanParagraph.waitUntilExists()
        reader.turnForward(expecting: secondPage)
        try reader.selectWord(onLine: 1, x: 20, in: reader.paragraph(startingWith: secondPageParagraph)).highlight()
        reader.storedHighlights.waitUntil(\.label, equals: "1")
        reader.showChrome()
        let jumped = reader.openMenu().open("contents").jump(to: "Dritter Teil")
        jumped.pageCounter.waitUntil(\.label, equals: "37 of \(bookPages)")
        return jumped
    }
}
