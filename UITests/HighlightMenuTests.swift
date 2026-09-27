import XCTest

final class HighlightMenuTests: UITestCase {
    private let firstPage = "1 of 54"
    private let secondPage = "2 of 54"
    private let colorNames = ["Yellow", "Green", "Blue", "Pink", "Purple"]

    func testTapOnHighlightShowsColorMenuWithoutBubbleOrChrome() throws {
        let reader = try openHighlightedBook(launch(germanBook))

        let menu = try reader.tapHighlight(onLine: 2, x: 20)

        menu.root.waitUntil(\.isHittable, equals: true)
        XCTAssertEqual(HighlightMenuScreen.colors.map { menu.swatch($0).label }, colorNames)
        XCTAssertEqual(
            HighlightMenuScreen.colors.map { menu.swatch($0).isSelected }, [true, false, false, false, false])
        XCTAssertEqual(menu.deleteButton.label, "Remove highlight")
        reader.paintedHighlightRings.waitUntil(\.label, equals: "1")
        XCTAssertFalse(reader.bubble.exists)
        XCTAssertFalse(reader.backButton.exists)
        XCTAssertEqual(reader.translationRequests.label, "")
    }

    func testColorChangeClosesMenuAndPersistsAfterReopenAndRelaunch() throws {
        let app = launch(germanBook)
        let reader = try openHighlightedBook(app)

        try reader.tapHighlight(onLine: 2, x: 20).choose("green")

        reader.storedHighlights.waitUntil(\.stringValue, equals: "seinem · green")
        reader.paintedHighlightRings.waitUntil(\.label, equals: "0")
        let reopened = reader.backToHome().openHeroBook()
        reopened.paintedHighlights.waitUntil(\.label, equals: "1")
        app.terminate()

        let relaunched = HomeScreen(app: launch(storedGermanBook)).waitUntilShown().openHeroBook()
        relaunched.paintedHighlights.waitUntil(\.label, equals: "1")
        XCTAssertEqual(relaunched.storedHighlights.stringValue, "seinem · green")
        let menu = try relaunched.tapHighlight(onLine: 2, x: 20)
        menu.swatch("green").waitUntil(\.isSelected, equals: true)
        XCTAssertFalse(menu.swatch("yellow").isSelected)
    }

    func testNewHighlightUsesLastPickedColor() throws {
        let reader = try openHighlightedBook(launch(germanBook))
        try reader.tapHighlight(onLine: 2, x: 20).choose("blue")
        reader.storedHighlights.waitUntil(\.stringValue, equals: "seinem · blue")

        try reader.selectWord(onLine: 7, x: 170).highlight()

        reader.storedHighlights.waitUntil(\.stringValue, equals: "auf · blue\nseinem · blue")
        reader.paintedHighlights.waitUntil(\.label, equals: "2")
    }

    func testDeleteRemovesHighlightAndFreesTheWord() throws {
        let reader = try openHighlightedBook(launch(germanBook))

        try reader.tapHighlight(onLine: 2, x: 20).delete()

        reader.storedHighlights.waitUntil(\.label, equals: "0")
        reader.paintedHighlights.waitUntil(\.label, equals: "0")
        reader.paintedHighlightRings.waitUntil(\.label, equals: "0")
        let reopened = reader.backToHome().openHeroBook()
        reopened.germanParagraph.waitUntilExists()
        XCTAssertEqual(reopened.storedHighlights.label, "0")
        try reopened.tapWord(onLine: 2, x: 20)
        reopened.bubbleWord.waitUntil(\.label, equals: "seinem")
        XCTAssertEqual(reopened.paintedHighlights.label, "0")
    }

    func testTapOutsideClosesMenuWithoutBubbleOrChrome() throws {
        let reader = try openHighlightedBook(launch(germanBook))
        let menu = try reader.tapHighlight(onLine: 2, x: 20)

        try reader.tapWord(onLine: 7, x: 170)

        menu.root.waitUntilGone()
        reader.paintedHighlightRings.waitUntil(\.label, equals: "0")
        XCTAssertFalse(reader.bubble.exists)
        XCTAssertFalse(reader.backButton.exists)
        XCTAssertEqual(reader.translationRequests.label, "")
        XCTAssertEqual(reader.storedHighlights.stringValue, "seinem · yellow")
    }

    func testPageTurnClosesMenu() throws {
        let reader = try openHighlightedBook(launch(germanBook))
        reader.pageCounter.waitUntil(\.label, equals: firstPage)
        let menu = try reader.tapHighlight(onLine: 2, x: 20)

        reader.turnForward(expecting: secondPage)

        menu.root.waitUntilGone()
        reader.turnBackward(expecting: firstPage)
        XCTAssertFalse(menu.root.exists)
        XCTAssertFalse(reader.bubble.exists)
        XCTAssertFalse(reader.backButton.exists)
    }

    func testOnlyOneOfBubbleSelectionMenuAndColorMenuIsShown() throws {
        let reader = try openHighlightedBook(launch(germanBook))
        try reader.tapWord(onLine: 7, x: 170)
        reader.bubbleWord.waitUntil(\.label, equals: "auf")
        reader.paintedWordTints.waitUntil(\.label, equals: "1")

        let menu = try reader.tapHighlight(onLine: 2, x: 20)

        reader.bubble.waitUntilGone()
        reader.paintedWordTints.waitUntil(\.label, equals: "0")
        XCTAssertTrue(menu.root.exists)

        let selectionMenu = try reader.selectWord(onLine: 7, x: 170)

        menu.root.waitUntilGone()
        XCTAssertTrue(selectionMenu.root.exists)
        XCTAssertFalse(reader.bubble.exists)
    }

    func testReaderHighlightedSnapshotLight() throws {
        assertSnapshot(of: try openColorMenu(appearance: .light), named: "Reader-Highlighted")
    }

    func testReaderHighlightedSnapshotDark() throws {
        assertSnapshot(of: try openColorMenu(appearance: .dark), named: "Reader-Highlighted")
    }

    func testReaderHighlightedGreenSnapshotLight() throws {
        assertSnapshot(of: try recolorGreen(appearance: .light), named: "Reader-Highlighted-Green")
    }

    func testReaderHighlightedGreenSnapshotDark() throws {
        assertSnapshot(of: try recolorGreen(appearance: .dark), named: "Reader-Highlighted-Green")
    }

    private var germanBook: LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
            translation: .immediate, now: nil, notificationPermission: nil)
    }

    private var storedGermanBook: LaunchConfiguration {
        LaunchConfiguration(
            resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
            now: nil, notificationPermission: nil)
    }

    private func openHighlightedBook(_ app: XCUIApplication) throws -> ReaderScreen {
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.pageCounter.waitUntil(\.label, equals: firstPage)
        try reader.selectWord(onLine: 2, x: 20).highlight()
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        return reader
    }

    private func openColorMenu(appearance: XCUIDevice.Appearance) throws -> HighlightMenuScreen {
        let reader = try openHighlightedBook(launch(germanBook, appearance: appearance))
        let menu = try reader.tapHighlight(onLine: 2, x: 20)
        menu.root.waitUntil(\.isHittable, equals: true)
        reader.paintedHighlightRings.waitUntil(\.label, equals: "1")
        return menu
    }

    private func recolorGreen(appearance: XCUIDevice.Appearance) throws -> ReaderScreen {
        let reader = try openHighlightedBook(launch(germanBook, appearance: appearance))
        try reader.tapHighlight(onLine: 2, x: 20).choose("green")
        reader.storedHighlights.waitUntil(\.stringValue, equals: "seinem · green")
        reader.paintedHighlightRings.waitUntil(\.label, equals: "0")
        return reader
    }
}
