import XCTest

final class HighlightContainmentTests: UITestCase {
    private let text = "fand er sich in seinem Bett zu einem ungeheueren"
    private let expandedText = "fand er sich in seinem Bett zu einem ungeheueren Ungeziefer"

    func testExpandingAndRepeatingHighlightKeepsOneEntryAcrossRelaunch() throws {
        let app = launch(configuration(.german))
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 1, x: 220, toLine: 2, x: 270)
        reader.storedHighlights.waitUntil(\.stringValue, equals: "\(text) · yellow")

        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 1, x: 220, toLine: 2, x: 305)

        reader.storedHighlights.waitUntil(\.stringValue, equals: "\(expandedText) · yellow")
        reader.paintedLive.waitUntil(\.label, equals: "0")
        XCTAssertEqual(reader.storedHighlights.label, "1")
        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 1, x: 220, toLine: 2, x: 270)
        reader.paintedLive.waitUntil(\.label, equals: "0")
        XCTAssertEqual(reader.storedHighlights.stringValue, "\(expandedText) · yellow")
        XCTAssertEqual(reader.storedHighlights.label, "1")
        app.terminate()

        let reopened = HomeScreen(app: launch(stored)).waitUntilShown().openHeroBook()
        reopened.paintedHighlights.waitUntil(\.label, equals: "1")
        XCTAssertEqual(reopened.storedHighlights.stringValue, "\(expandedText) · yellow")
    }

    func testOpeningBookRemovesOnlyCoveredHighlightsAndPersistsCleanup() {
        let app = launch(configuration(.germanContainedHighlights, highlighted: true))
        let home = HomeScreen(app: app).waitUntilShown()
        home.storedHighlights.waitUntil(\.label, equals: "7")

        let reader = home.openHeroBook()

        reader.storedHighlights.waitUntil(\.label, equals: "4")
        reader.paintedHighlights.waitUntil(\.label, equals: "4")
        reader.showChrome()
        let index = reader.openMenu().open("highlights")
        XCTAssertEqual(
            Set(index.highlights.map(\.identifier)),
            Set([
                "readerIndex.highlight.0:77-147", "readerIndex.highlight.0:90-147",
                "readerIndex.highlight.0:140-159", "readerIndex.highlight.0:565-583",
            ]))
        app.terminate()

        let relaunchedHome = HomeScreen(app: launch(stored)).waitUntilShown()
        XCTAssertEqual(relaunchedHome.storedHighlights.label, "4")
        let reopened = relaunchedHome.openHeroBook()
        reopened.paintedHighlights.waitUntil(\.label, equals: "4")
        XCTAssertEqual(reopened.storedHighlights.label, "4")
    }

    private func configuration(_ fixture: Fixture, highlighted: Bool = false) -> LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [fixture], opened: [], inProgress: [],
            highlighted: highlighted ? [fixture] : [], translation: .immediate, now: nil, notificationPermission: nil)
    }

    private var stored: LaunchConfiguration {
        LaunchConfiguration(
            resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
            now: nil, notificationPermission: nil)
    }
}
