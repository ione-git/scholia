import XCTest

final class TranslationTests: UITestCase {
    private let mockTranslation = "vermin"
    private let mockLanguages = [
        "ar", "de", "en", "es", "fr", "hi", "id", "it", "ja", "ko", "nl", "pl", "pt", "ru", "th", "tr", "uk", "vi",
        "zh-Hans", "zh-Hant",
    ]

    func testTappedWordShowsMockTranslation() throws {
        let reader = openReader()

        try reader.tapWord(onLine: 0, x: 3)

        reader.word.waitUntil(\.label, equals: "Als")
        reader.translation.waitUntil(\.label, equals: mockTranslation)
        reader.translationRequests.waitUntil(\.label, equals: "Als · 0 · de → en")
    }

    func testRetappedWordIsTranslatedOnce() throws {
        let reader = openReader()
        try reader.tapWord(onLine: 0, x: 3)
        reader.word.waitUntil(\.label, equals: "Als")
        try reader.tapWord(onLine: 4, x: 3)
        reader.word.waitUntil(\.label, equals: "panzerartig")

        try reader.tapWord(onLine: 0, x: 3)
        reader.word.waitUntil(\.label, equals: "Als")
        try reader.tapWord(onLine: 2, x: 20)
        reader.word.waitUntil(\.label, equals: "seinem")
        reader.translationRequests.waitUntil(
            \.label, equals: "Als · 0 · de → en\npanzerartig · 18 · de → en\nseinem · 79 · de → en")

        try reader.tapWord(onLine: 3, x: 255)

        reader.word.waitUntil(\.label, equals: "seinem")
        reader.translation.waitUntil(\.label, equals: mockTranslation)
        reader.translationRequests.waitUntil(
            \.label,
            equals: "Als · 0 · de → en\npanzerartig · 18 · de → en\nseinem · 79 · de → en\nseinem · 11 · de → en")
    }

    func testRepeatedWordIsRequestedAtItsPlaceInSentence() throws {
        let reader = openReader()
        try reader.tapWord(onLine: 3, x: 216)
        reader.word.waitUntil(\.label, equals: "auf")
        reader.translationRequests.waitUntil(\.label, equals: "auf · 7 · de → en")

        try reader.tapWord(onLine: 7, x: 170)

        reader.word.waitUntil(\.label, equals: "auf")
        reader.translation.waitUntil(\.label, equals: mockTranslation)
        reader.translationRequests.waitUntil(\.label, equals: "auf · 7 · de → en\nauf · 161 · de → en")
    }

    func testTranslateToListsProviderLanguages() {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))
        let settings = HomeScreen(app: app).waitUntilShown().openSettings()

        settings.openTranslationLanguages()

        XCTAssertEqual(
            Set(settings.translationLanguages.allElementsBoundByIndex.map(\.identifier)),
            Set(mockLanguages.map { "settings.translateTo.\($0)" }))
    }

    func testTranslateToPersistsAndTargetsTranslations() throws {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))
        var settings = HomeScreen(app: app).waitUntilShown().openSettings()
        settings.chooseTranslationLanguage("fr")
        settings.translateTo.waitUntil(\.label, equals: "Translate to, French")
        app.terminate()

        let relaunched = launch(
            LaunchConfiguration(
                resetsState: false, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))
        settings = HomeScreen(app: relaunched).waitUntilShown().openSettings()
        XCTAssertEqual(settings.translateTo.waitUntilExists().label, "Translate to, French")
        let reader = settings.goBack().openReaderPrototype()

        try reader.tapWord(onLine: 0, x: 3)

        reader.translation.waitUntil(\.label, equals: mockTranslation)
        reader.translationRequests.waitUntil(\.label, equals: "Als · 0 · de → fr")
    }

    private func openReader() -> ReaderScreen {
        let app = launch(
            LaunchConfiguration(
                resetsState: true, fixtures: [], opened: [], inProgress: [], highlighted: [], translation: .immediate,
                now: nil,
                notificationPermission: nil))
        return HomeScreen(app: app).waitUntilShown().openReaderPrototype()
    }
}
