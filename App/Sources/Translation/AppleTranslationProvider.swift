import Foundation
import NaturalLanguage
import Translation

struct AppleTranslationProvider: TranslationProvider {
    private nonisolated static let partsOfSpeech: [NLTag: PartOfSpeech] = [
        .noun: .noun, .verb: .verb, .adjective: .adjective, .adverb: .adverb, .pronoun: .pronoun,
        .determiner: .determiner, .particle: .particle, .preposition: .preposition, .number: .number,
        .conjunction: .conjunction, .interjection: .interjection,
    ]

    let needsLanguagePacks = true

    func targetLanguages() async -> [String] {
        var scriptsByLanguage: [String: Set<String>] = [:]
        for language in await Self.supportedLanguages() {
            let maximal = Locale.Language(identifier: language.maximalIdentifier)
            guard let code = maximal.languageCode?.identifier, let script = maximal.script?.identifier else {
                continue
            }
            scriptsByLanguage[code, default: []].insert(script)
        }
        return scriptsByLanguage.flatMap { code, scripts in
            scripts.count == 1 ? [code] : scripts.map { "\(code)-\($0)" }
        }
    }

    func translate(_ request: TranslationRequest) async throws -> WordTranslation {
        async let translation = Self.translate(
            request.word, from: Locale.Language(identifier: request.source),
            to: Locale.Language(identifier: request.target))
        async let grammar = Self.grammar(of: request)
        let dictionary = MockTranslationProvider.translation
        let (lemma, partOfSpeech) = await grammar
        return WordTranslation(
            translation: try await translation, ipa: dictionary.ipa, lemma: lemma,
            partOfSpeech: partOfSpeech, meaningInContext: dictionary.meaningInContext,
            meanings: dictionary.meanings)
    }

    @concurrent
    private nonisolated static func supportedLanguages() async -> [Locale.Language] {
        await LanguageAvailability().supportedLanguages
    }

    @concurrent
    private nonisolated static func translate(
        _ word: String, from source: Locale.Language, to target: Locale.Language
    ) async throws -> String {
        try await TranslationSession(installedSource: source, target: target).translate(word).targetText
    }

    @concurrent
    private nonisolated static func grammar(of request: TranslationRequest) async -> (
        lemma: String?, partOfSpeech: PartOfSpeech?
    ) {
        let sentence = request.sentence
        guard
            let word = Range(
                NSRange(location: request.offsetInSentence, length: request.word.utf16.count), in: sentence)
        else {
            return (nil, nil)
        }
        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        tagger.string = sentence
        tagger.setLanguage(NLLanguage(rawValue: request.source), range: sentence.startIndex..<sentence.endIndex)
        var grammar: (lemma: String?, partOfSpeech: PartOfSpeech?) = (nil, nil)
        tagger.enumerateTags(
            in: word, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]
        ) { lexicalClass, range in
            let lemma = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma).0
            grammar = (lemma?.rawValue, lexicalClass.flatMap { Self.partsOfSpeech[$0] })
            return true
        }
        return grammar
    }
}
