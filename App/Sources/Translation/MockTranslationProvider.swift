import Observation

@Observable
final class MockTranslationProvider: TranslationProvider {
    static let translation = WordTranslation(
        translation: "vermin", ipa: "[ˈʊnɡəˌtsiːfɐ]", lemma: "das Ungeziefer", partOfSpeech: .noun,
        meaningInContext: "a monstrous, repulsive creature",
        meanings: [
            WordMeaning(text: "vermin, pests", note: "collective"),
            WordMeaning(text: "a noxious insect", note: nil),
            WordMeaning(text: "riffraff, scum", note: "figurative"),
        ])

    private static let hold: Duration = .seconds(365 * 24 * 60 * 60)

    let needsLanguagePacks = false
    let isHeld: Bool
    private(set) var requests: [TranslationRequest] = []

    init(isHeld: Bool) {
        self.isHeld = isHeld
    }

    func targetLanguages() async -> [String] {
        TargetLanguage.identifiers
    }

    func translate(_ request: TranslationRequest) async throws -> WordTranslation {
        requests.append(request)
        if isHeld {
            try await Task.sleep(for: Self.hold)
        }
        return Self.translation
    }
}
