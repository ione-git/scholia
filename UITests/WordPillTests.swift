import XCTest

final class WordPillTests: UITestCase {
    private let firstPage = "1 of 54"

    func testMinimalShowsLoadingPillWithoutBubble() throws {
        let reader = openGermanBook(translation: .held)

        try reader.tapWord(onLine: 0, x: 3)

        XCTAssertEqual(reader.pillLoading.waitUntilExists().label, "Translating Als")
        reader.translationRequests.waitUntil(\.label, equals: "Als · 0 · de → en")
        XCTAssertFalse(reader.pill.exists)
        XCTAssertFalse(reader.bubble.exists)
    }

    func testPillShowsWordAndTranslation() throws {
        let reader = openGermanBook(translation: .immediate)

        try reader.tapUngeziefer()

        reader.pill.waitUntil(\.label, equals: "Ungeziefer: vermin")
        XCTAssertFalse(reader.pillLoading.exists)
        XCTAssertFalse(reader.bubble.exists)
    }

    func testPillOpensCardAndClosingReturnsToPill() throws {
        let reader = openGermanBook(translation: .immediate)
        try reader.tapUngeziefer()
        reader.pill.waitUntil(\.label, equals: "Ungeziefer: vermin")

        let card = reader.openCard(from: reader.pill)

        XCTAssertEqual(card.word.label, "Ungeziefer")
        card.translation.waitUntil(\.label, equals: "vermin")
        card.close()
        reader.pill.waitUntil(\.label, equals: "Ungeziefer: vermin")
        reader.paintedWordTints.waitUntil(\.label, equals: "1")
        XCTAssertFalse(reader.backButton.exists)
    }

    func testPageTurnClosesPillAndClearsTint() throws {
        let reader = openGermanBook(translation: .immediate)
        reader.pageCounter.waitUntil(\.label, equals: firstPage)
        try reader.tapUngeziefer()
        reader.pill.waitUntil(\.label, equals: "Ungeziefer: vermin")
        reader.paintedWordTints.waitUntil(\.label, equals: "1")

        reader.turnForward(expecting: "2 of 54")

        reader.pill.waitUntilGone()
        reader.paintedWordTints.waitUntil(\.label, equals: "0")
    }

    func testTranslatedPillPassesAccessibilityAudit() throws {
        let reader = try openTranslatedPill(appearance: .light)

        try reader.app.auditAccessibilityOutsideTrackedIssues()
    }

    func testBubblePillSnapshotLight() throws {
        assertSnapshot(of: try openTranslatedPill(appearance: .light), named: "Bubble-Pill")
    }

    func testBubblePillSnapshotDark() throws {
        assertSnapshot(of: try openTranslatedPill(appearance: .dark), named: "Bubble-Pill")
    }

    private func openTranslatedPill(appearance: XCUIDevice.Appearance) throws -> ReaderScreen {
        let reader = openGermanBook(launch(germanBook(translation: .immediate), appearance: appearance))
        try reader.tapUngeziefer()
        reader.pill.waitUntil(\.label, equals: "Ungeziefer: vermin")
        reader.paintedWordTints.waitUntil(\.label, equals: "1")
        return reader
    }

    private func openGermanBook(translation: TranslationMock) -> ReaderScreen {
        openGermanBook(launch(germanBook(translation: translation)))
    }

    private func openGermanBook(_ app: XCUIApplication) -> ReaderScreen {
        let settings = HomeScreen(app: app).waitUntilShown().openSettings()
        settings.chooseOnWordTap("minimal")
        let reader = settings.goBack().openHeroBook()
        reader.germanParagraph.waitUntilExists()
        return reader
    }

    private func germanBook(translation: TranslationMock) -> LaunchConfiguration {
        LaunchConfiguration(
            resetsState: true, fixtures: [.german], opened: [], inProgress: [], highlighted: [],
            translation: translation, now: nil, notificationPermission: nil)
    }
}
