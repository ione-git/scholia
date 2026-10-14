import XCTest

final class IndexHighlightTests: UITestCase {
    func testRepeatingSavedIndexHighlightWhileHoldingExtendsOneEntryLight() throws {
        try repeatWhileHolding(appearance: .light, backwards: false)
    }

    func testRepeatingSavedIndexHighlightWhileHoldingExtendsOneEntryDark() throws {
        try repeatWhileHolding(appearance: .dark, backwards: true)
    }

    private func repeatWhileHolding(appearance: XCUIDevice.Appearance, backwards: Bool) throws {
        let reader = indexReader(appearance: appearance)
        let first = reader.paragraph(startingWith: "Archive on").waitUntilExists()
        let last = reader.paragraph(startingWith: "on railway journeys").waitUntilExists()
        let start = try reader.point(in: first, onLine: 0, x: 110)
        let end = try reader.point(in: last, onLine: 0, x: 120)
        (backwards ? end : start).press(
            forDuration: 1, thenDragTo: backwards ? start : end, withVelocity: .default,
            thenHoldForDuration: 3)
        reader.paintedLive.waitUntil(\.label, equals: "0")
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        XCTAssertEqual(reader.storedHighlights.label, "1")
        XCTAssertEqual(
            reader.storedHighlights.stringValue,
            "river routes\n        on garden paths\n        family of\n        on mountain passes\n        on coastal weather\n        on railway journeys · yellow"
        )
    }

    func testIndexHighlightSnapshotLight() {
        assertSnapshot(of: indexReader(appearance: .light), named: "Reader-IndexHighlight")
    }

    func testIndexHighlightSnapshotDark() {
        assertSnapshot(of: indexReader(appearance: .dark), named: "Reader-IndexHighlight")
    }

    private func indexReader(appearance: XCUIDevice.Appearance) -> ReaderScreen {
        let configuration = LaunchConfiguration(
            resetsState: true, fixtures: [.indexHighlights], opened: [], inProgress: [],
            highlighted: [.indexHighlights], translation: .immediate, now: nil, notificationPermission: nil)
        let reader = HomeScreen(app: launch(configuration, appearance: appearance)).waitUntilShown().openHeroBook()
        reader.paintedHighlights.waitUntil(\.label, equals: "1")
        return reader
    }
}
