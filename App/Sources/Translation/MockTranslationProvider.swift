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

    let needsLanguagePacks = false
    private(set) var requests: [TranslationRequest] = []

    func targetLanguages() async -> [String] {
        TargetLanguage.identifiers
    }

    func translate(_ request: TranslationRequest) async -> WordTranslation {
        requests.append(request)
        return Self.translation
    }
}
