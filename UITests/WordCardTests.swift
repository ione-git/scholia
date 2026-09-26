import XCTest

final class WordCardTests: UITestCase {
    private let ungezieferRequest = "Ungeziefer · 112 · de → en"

    func testBubbleOpensCardWithDetailsContextAndMeanings() throws {
        let reader = openGermanBook(onWordTap: "bubble", translation: .immediate)
        try reader.tapUngeziefer()
        reader.bubbleTranslation.waitUntil(\.label, equals: "vermin")

        let card = reader.openCard(from: reader.bubble)

        XCTAssertEqual(card.word.label, "Ungeziefer")
        XCTAssertEqual(card.details.label, "[ˈʊnɡəˌtsiːfɐ] · das Ungeziefer · noun")
        XCTAssertEqual(card.translation.label, "vermin")
        XCTAssertEqual(card.meaningInContext.label, "a monstrous, repulsive creature")
        XCTAssertEqual(
            card.meaningLabels,
            ["1, vermin, pests — collective", "2, a noxious insect", "3, riffraff, scum — figurative"])
        XCTAssertEqual(reader.translationRequests.label, ungezieferRequest)
    }

    func testClosingCardReturnsToBubbleWithTint() throws {
        let reader = openGermanBook(onWordTap: "bubble", translation: .immediate)
        try reader.tapUngeziefer()
        reader.bubbleTranslation.waitUntil(\.label, equals: "vermin")
        let card = reader.openCard(from: reader.bubble)

        card.close()

        reader.bubbleWord.waitUntil(\.label, equals: "Ungeziefer")
        reader.bubbleTranslation.waitUntil(\.label, equals: "vermin")
        reader.paintedWordTints.waitUntil(\.label, equals: "1")
        XCTAssertFalse(reader.backButton.exists)
        XCTAssertEqual(reader.translationRequests.label, ungezieferRequest)
    }

    func testCardModeOpensCardAtOnceAndClosingClearsWord() throws {
        let reader = openGermanBook(onWordTap: "card", translation: .immediate)

        try reader.tapUngeziefer()

        let card = WordCardScreen(app: reader.app).waitUntilShown()
        XCTAssertEqual(card.word.label, "Ungeziefer")
        card.translation.waitUntil(\.label, equals: "vermin")
        card.close()
        reader.paintedWordTints.waitUntil(\.label, equals: "0")
        XCTAssertFalse(reader.bubble.exists)
        XCTAssertFalse(reader.pill.exists)
        XCTAssertFalse(reader.backButton.exists)
    }

    func testCardShowsLoadingWhileTranslating() throws {
        let reader = openGermanBook(onWordTap: "card", translation: .held)

        try reader.tapUngeziefer()

        let card = WordCardScreen(app: reader.app).waitUntilShown()
        XCTAssertEqual(card.word.label, "Ungeziefer")
        XCTAssertEqual(card.loading.waitUntilExists().label, "Translating Ungeziefer")
        reader.translationRequests.waitUntil(\.label, equals: ungezieferRequest)
        XCTAssertTrue(card.pronounceButton.exists)
        XCTAssertFalse(card.translation.exists)
        XCTAssertFalse(card.meanings.exists)
    }

    func testBookInTargetLanguageNeedsNoTranslation() throws {
        let app = launch(germanBook(translation: .immediate))
        let settings = HomeScreen(app: app).waitUntilShown().openSettings()
        settings.chooseTranslationLanguage("de")
        let reader = openGermanBook(from: settings, onWordTap: "card")

        try reader.tapUngeziefer()

        let card = WordCardScreen(app: reader.app).waitUntilShown()
        XCTAssertEqual(card.failure.waitUntilExists().label, "No translation needed")
        XCTAssertTrue(card.pronounceButton.exists)
        XCTAssertFalse(card.loading.exists)
        XCTAssertEqual(reader.translationRequests.label, "")
    }

    func testPronounceSpeaksWordInBookLanguage() throws {
        let reader = openGermanBook(onWordTap: "card", translation: .immediate)
        try reader.tapUngeziefer()
        let card = WordCardScreen(app: reader.app).waitUntilShown()

        XCTAssertEqual(card.pronounceButton.waitUntilExists().label, "Pronounce")
        card.pronounce()

        card.pronunciations.waitUntil(\.label, equals: "Ungeziefer · de")
    }

    func testOpenCardPassesAccessibilityAudit() throws {
        let card = try openTranslatedCard(appearance: .light)

        try card.app.auditAccessibilityOutsideTrackedIssues()
    }

    func testReaderCardSnapshotLight() throws {
        assertSnapshot(of: try openTranslatedCard(appearance: .light), named: "Reader-Card")
    }

    func testReaderCardSnapshotDark() throws {
        assertSnapshot(of: try openTranslatedCard(appearance: .dark), named: "Reader-Card")
    }

    private func openTranslatedCard(appearance: XCUIDevice.Appearance) throws -> WordCardScreen {
        let app = launch(germanBook(translation: .immediate), appearance: appearance)
        let reader = openGermanBook(from: HomeScreen(app: app).waitUntilShown().openSettings(), onWordTap: "card")
        try reader.tapUngeziefer()
        let card = WordCardScreen(app: app).waitUntilShown()
        card.translation.waitUntil(\.label, equals: "vermin")
        reader.paintedWordTints.waitUntil(\.label, equals: "1")
        return card
    }

    private func openGermanBook(onWordTap style: String, translation: TranslationMock) -> ReaderScreen {
        let app = launch(germanBook(translation: translation))
        return openGermanBook(from: HomeScreen(app: app).waitUntilShown().openSettings(), onWordTap: style)
    }

    private func openGermanBook(from settings: SettingsScreen, onWordTap style: String) -> ReaderScreen {
        settings.chooseOnWordTap(style)
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
