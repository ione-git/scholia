import XCTest

final class DragHighlightTests: UITestCase {
    private let firstPage = "1 of 54"
    private let edgeHoldDuration: TimeInterval = 3
    private let draggedText = "fand er sich in seinem Bett zu einem ungeheueren"
    private let draggedToEdgeText = "seinem Bett zu einem ungeheueren Ungeziefer"
    private let arabicParagraph = "في الصباح تستيقظ المدينة"
    private let draggedArabicText = "المدينة ببطء. يفتح الخبازون"

    func testDragPaintsHighlightInLastUsedColourWithoutMenu() throws {
        let reader = openGermanBook(launch(germanBook))
        reader.pageCounter.waitUntil(\.label, equals: firstPage)

        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 1, x: 220, toLine: 2, x: 270)

        reader.storedHighlights.waitUntil(\.stringValue, equals: "\(draggedText) · yellow")
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        reader.paintedLive.waitUntil(\.label, equals: "0")
        XCTAssertFalse(SelectionMenuScreen(app: reader.app).root.exists)
        XCTAssertFalse(reader.app.menuItems.firstMatch.exists)
        XCTAssertFalse(reader.bubble.exists)
        XCTAssertEqual(reader.pageCounter.label, firstPage)
    }

    func testDragBackwardsHighlightsSameText() throws {
        let reader = openGermanBook(launch(germanBook))

        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 2, x: 270, toLine: 1, x: 220)

        reader.storedHighlights.waitUntil(\.stringValue, equals: "\(draggedText) · yellow")
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        reader.paintedLive.waitUntil(\.label, equals: "0")
    }

    func testDragToPageEdgeDoesNotTurnPage() throws {
        let reader = openGermanBook(launch(germanBook))
        reader.pageCounter.waitUntil(\.label, equals: firstPage)
        let edge = reader.app.frame.maxX - reader.germanParagraph.frame.minX - 1

        try reader.dragHighlightAndHold(
            in: reader.germanParagraph, fromLine: 2, x: 20, toLine: 2, x: edge, for: edgeHoldDuration)

        reader.storedHighlights.waitUntil(\.stringValue, equals: "\(draggedToEdgeText) · yellow")
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        reader.paintedLive.waitUntil(\.label, equals: "0")
        XCTAssertEqual(reader.pageCounter.label, firstPage)
    }

    func testDragOverSameTextTwiceKeepsOneHighlightAndNoPaint() throws {
        let reader = openGermanBook(launch(germanBook))
        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 1, x: 220, toLine: 2, x: 270)
        reader.paintedHighlights.waitUntil(\.label, equals: "1")

        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 1, x: 220, toLine: 2, x: 270)

        reader.paintedLive.waitUntil(\.label, equals: "0")
        XCTAssertEqual(reader.storedHighlights.label, "1")
        XCTAssertEqual(reader.paintedHighlights.label, "1")
    }

    func testDragHighlightsRightToLeftText() throws {
        let reader = HomeScreen(app: launch(arabicBook)).waitUntilShown().openHeroBook()
        let paragraph = reader.paragraph(startingWith: arabicParagraph).waitUntilExists()

        try reader.dragHighlight(in: paragraph, fromLine: 0, x: 200, toLine: 0, x: 100)

        reader.storedHighlights.waitUntil(\.stringValue, equals: "\(draggedArabicText) · yellow")
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        reader.paintedLive.waitUntil(\.label, equals: "0")
    }

    func testReaderDragHighlightedSnapshotLight() throws {
        assertSnapshot(of: try dragHighlighted(appearance: .light), named: "Reader-DragHighlighted")
    }

    func testReaderDragHighlightedSnapshotDark() throws {
        assertSnapshot(of: try dragHighlighted(appearance: .dark), named: "Reader-DragHighlighted")
    }

    private var germanBook: LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
            translation: .immediate, now: nil, notificationPermission: nil)
    }

    private var arabicBook: LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [.arabic], opened: [], inProgress: [], highlighted: [],
            translation: .immediate, now: nil, notificationPermission: nil)
    }

    private func openGermanBook(_ app: XCUIApplication) -> ReaderScreen {
        let reader = HomeScreen(app: app).waitUntilShown().openHeroBook()
        reader.germanParagraph.waitUntilExists()
        return reader
    }

    private func dragHighlighted(appearance: XCUIDevice.Appearance) throws -> ReaderScreen {
        let reader = openGermanBook(launch(germanBook, appearance: appearance))
        reader.pageCounter.waitUntil(\.label, equals: firstPage)
        try reader.dragHighlight(in: reader.germanParagraph, fromLine: 1, x: 220, toLine: 2, x: 270)
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        reader.paintedLive.waitUntil(\.label, equals: "0")
        return reader
    }
}
