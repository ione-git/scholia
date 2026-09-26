import XCTest

final class SelectionTests: UITestCase {
    private let firstPage = "1 of 54"
    private let secondPage = "2 of 54"

    func testLongPressShowsMenuThatStaysAfterLift() throws {
        let reader = openGermanBook(launch(germanBook))

        let menu = try reader.selectWord(onLine: 2, x: 20)

        menu.root.waitUntil(\.isHittable, equals: true)
        XCTAssertEqual(menu.highlightItem.label, "Highlight")
        XCTAssertEqual(menu.translateItem.label, "Translate")
        XCTAssertEqual(menu.copyItem.label, "Copy")
        XCTAssertTrue(menu.root.isHittable)
        XCTAssertFalse(reader.app.menuItems.firstMatch.exists)
        XCTAssertFalse(reader.bubble.exists)
    }

    func testHighlightPersistsAfterReopenAndRelaunch() throws {
        let app = launch(germanBook)
        let reader = openGermanBook(app)

        try reader.selectWord(onLine: 2, x: 20).highlight()

        reader.storedHighlights.waitUntil(\.stringValue, equals: "seinem · yellow")
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        let reopened = reader.backToHome().openHeroBook()
        reopened.paintedHighlights.waitUntil(\.label, equals: "1")
        app.terminate()

        let relaunched = HomeScreen(app: launch(storedGermanBook)).waitUntilShown().openHeroBook()
        relaunched.paintedHighlights.waitUntil(\.label, equals: "1")
        XCTAssertEqual(relaunched.storedHighlights.stringValue, "seinem · yellow")
    }

    func testTranslateOpensBubbleForSelection() throws {
        let reader = openGermanBook(launch(germanBook))

        try reader.selectWord(onLine: 2, x: 20).translate()

        reader.bubbleWord.waitUntil(\.label, equals: "seinem")
        reader.bubbleTranslation.waitUntil(\.label, equals: "vermin")
        reader.translationRequests.waitUntil(\.label, equals: "seinem · 79 · de → en")
        reader.paintedWordTints.waitUntil(\.label, equals: "1")
        XCTAssertEqual(reader.storedHighlights.label, "0")
    }

    func testCopyPutsSelectionOnPasteboard() throws {
        let reader = openGermanBook(launch(germanBook))

        try reader.selectWord(onLine: 2, x: 20).copy()

        reader.pasteboard.waitUntil(\.label, equals: "seinem")
        XCTAssertEqual(reader.storedHighlights.label, "0")
        XCTAssertFalse(reader.bubble.exists)
    }

    func testTapOutsideClearsSelectionWithoutChromeOrBubble() throws {
        let reader = openGermanBook(launch(germanBook))
        let menu = try reader.selectWord(onLine: 2, x: 20)

        try reader.tapWord(onLine: 6, x: 3)

        menu.root.waitUntilGone()
        reader.showChrome()
        XCTAssertFalse(reader.bubble.exists)
        XCTAssertEqual(reader.storedHighlights.label, "0")
    }

    func testPageTurnClearsSelection() throws {
        let reader = openGermanBook(launch(germanBook))
        reader.pageCounter.waitUntil(\.label, equals: firstPage)
        let menu = try reader.selectWord(onLine: 2, x: 20)

        reader.turnForward(expecting: secondPage)

        menu.root.waitUntilGone()
        reader.turnBackward(expecting: firstPage)
        reader.showChrome()
        XCTAssertFalse(menu.root.exists)
    }

    func testReaderSelectSnapshotLight() throws {
        assertSnapshot(of: try selectWord(appearance: .light), named: "Reader-Select")
    }

    func testReaderSelectSnapshotDark() throws {
        assertSnapshot(of: try selectWord(appearance: .dark), named: "Reader-Select")
    }

    func testReaderHighlightSnapshotLight() throws {
        assertSnapshot(of: try reopenHighlighted(appearance: .light), named: "Reader-Highlight")
    }

    func testReaderHighlightSnapshotDark() throws {
        assertSnapshot(of: try reopenHighlighted(appearance: .dark), named: "Reader-Highlight")
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

    private func openGermanBook(_ app: XCUIApplication) -> ReaderScreen {
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.germanParagraph.waitUntilExists()
        return reader
    }

    private func selectWord(appearance: XCUIDevice.Appearance) throws -> SelectionMenuScreen {
        let reader = openGermanBook(launch(germanBook, appearance: appearance))
        reader.pageCounter.waitUntil(\.label, equals: firstPage)
        let menu = try reader.selectWord(onLine: 2, x: 20)
        menu.root.waitUntil(\.isHittable, equals: true)
        return menu
    }

    private func reopenHighlighted(appearance: XCUIDevice.Appearance) throws -> ReaderScreen {
        let reader = openGermanBook(launch(germanBook, appearance: appearance))
        try reader.selectWord(onLine: 2, x: 20).highlight()
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        let reopened = reader.backToHome().openHeroBook()
        reopened.pageCounter.waitUntil(\.label, equals: firstPage)
        reopened.paintedHighlights.waitUntil(\.label, equals: "1")
        return reopened
    }
}
