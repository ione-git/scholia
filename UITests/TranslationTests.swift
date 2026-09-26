import XCTest

final class TranslationTests: UITestCase {
    private let mockTranslation = "vermin"
    private let mockLanguages = [
        "ar", "de", "en", "es", "fr", "hi", "id", "it", "ja", "ko", "nl", "pl", "pt", "ru", "th", "tr", "uk", "vi",
        "zh-Hans", "zh-Hant",
    ]

    func testTappedWordShowsMockTranslation() throws {
        let reader = openReader()

        try tapWord(onLine: 0, x: 3, in: reader)

        reader.word.waitUntil(\.label, equals: "Als")
        reader.translation.waitUntil(\.label, equals: mockTranslation)
        reader.translationRequests.waitUntil(\.label, equals: "Als · 0 · de → en")
    }

    func testRetappedWordIsTranslatedOnce() throws {
        let reader = openReader()
        try tapWord(onLine: 0, x: 3, in: reader)
        reader.word.waitUntil(\.label, equals: "Als")
        try tapWord(onLine: 4, x: 3, in: reader)
        reader.word.waitUntil(\.label, equals: "panzerartig")

        try tapWord(onLine: 0, x: 3, in: reader)
        reader.word.waitUntil(\.label, equals: "Als")
        try tapWord(onLine: 2, x: 20, in: reader)
        reader.word.waitUntil(\.label, equals: "seinem")
        reader.translationRequests.waitUntil(
            \.label, equals: "Als · 0 · de → en\npanzerartig · 18 · de → en\nseinem · 79 · de → en")

        try tapWord(onLine: 3, x: 255, in: reader)

        reader.word.waitUntil(\.label, equals: "seinem")
        reader.translation.waitUntil(\.label, equals: mockTranslation)
        reader.translationRequests.waitUntil(
            \.label,
            equals: "Als · 0 · de → en\npanzerartig · 18 · de → en\nseinem · 79 · de → en\nseinem · 11 · de → en")
    }

    func testRepeatedWordIsRequestedAtItsPlaceInSentence() throws {
        let reader = openReader()
        try tapWord(onLine: 3, x: 216, in: reader)
        reader.word.waitUntil(\.label, equals: "auf")
        reader.translationRequests.waitUntil(\.label, equals: "auf · 7 · de → en")

        try tapWord(onLine: 7, x: 170, in: reader)

        reader.word.waitUntil(\.label, equals: "auf")
        reader.translation.waitUntil(\.label, equals: mockTranslation)
        reader.translationRequests.waitUntil(\.label, equals: "auf · 7 · de → en\nauf · 161 · de → en")
    }

    func testTranslateToListsProviderLanguages() {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        let settings = HomeScreen(app: app).waitUntilShown().openSettings()

        settings.openTranslationLanguages()

        XCTAssertEqual(
            Set(settings.translationLanguages.allElementsBoundByIndex.map(\.identifier)),
            Set(mockLanguages.map { "settings.translateTo.\($0)" }))
    }

    func testTranslateToPersistsAndTargetsTranslations() throws {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        var settings = HomeScreen(app: app).waitUntilShown().openSettings()
        settings.chooseTranslationLanguage("fr")
        settings.translateTo.waitUntil(\.label, equals: "Translate to, French")
        app.terminate()

        let relaunched = launch(
            LaunchConfiguration(resetsState: false, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        settings = HomeScreen(app: relaunched).waitUntilShown().openSettings()
        XCTAssertEqual(settings.translateTo.waitUntilExists().label, "Translate to, French")
        let reader = settings.goBack().openReaderPrototype()

        try tapWord(onLine: 0, x: 3, in: reader)

        reader.translation.waitUntil(\.label, equals: mockTranslation)
        reader.translationRequests.waitUntil(\.label, equals: "Als · 0 · de → fr")
    }

    private func openReader() -> ReaderScreen {
        let app = launch(
            LaunchConfiguration(resetsState: true, fixtures: [], opened: [], mocksTranslation: true, now: nil))
        return HomeScreen(app: app).waitUntilShown().openReaderPrototype()
    }

    private func tapWord(onLine index: Int, x: CGFloat, in reader: ReaderScreen) throws {
        let line = try TokenValues.load().lineHeight("reading-body")
        reader.paragraph(startingWith: "Als Gregor Samsa").waitUntilExists()
            .coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: x, dy: line * CGFloat(index) + line / 2))
            .tap()
    }
}
