import Foundation

protocol TranslationProvider {
    var needsLanguagePacks: Bool { get }
    func targetLanguages() async -> [String]
    func translate(_ request: TranslationRequest) async throws -> WordTranslation
}

nonisolated struct TranslationRequest: Hashable, Sendable {
    var word: String
    var sentence: String
    var offsetInSentence: Int
    var source: String
    var target: String
}

nonisolated struct WordTranslation: Hashable, Sendable {
    var translation: String
    var ipa: String
    var lemma: String?
    var partOfSpeech: PartOfSpeech?
    var meaningInContext: String
    var meanings: [WordMeaning]
}

nonisolated struct WordMeaning: Hashable, Sendable {
    var text: String
    var note: String?
}

nonisolated enum PartOfSpeech: String, Hashable, Sendable {
    case noun
    case verb
    case adjective
    case adverb
    case pronoun
    case determiner
    case particle
    case preposition
    case number
    case conjunction
    case interjection
}
