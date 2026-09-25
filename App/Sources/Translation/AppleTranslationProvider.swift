import Foundation
import NaturalLanguage
import Translation

struct AppleTranslationProvider: TranslationProvider {
    private static let partsOfSpeech: [NLTag: PartOfSpeech] = [
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
        let translation = try await Self.translate(
            request.word, from: Locale.Language(identifier: request.source),
            to: Locale.Language(identifier: request.target))
        let grammar = grammar(of: request)
        let dictionary = MockTranslationProvider.translation
        return WordTranslation(
            translation: translation, ipa: dictionary.ipa, lemma: grammar.lemma,
            partOfSpeech: grammar.partOfSpeech, meaningInContext: dictionary.meaningInContext,
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

    private func grammar(of request: TranslationRequest) -> (lemma: String?, partOfSpeech: PartOfSpeech?) {
        let sentence = request.sentence
        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        tagger.string = sentence
        tagger.setLanguage(NLLanguage(rawValue: request.source), range: sentence.startIndex..<sentence.endIndex)
        var grammar: (lemma: String?, partOfSpeech: PartOfSpeech?) = (nil, nil)
        tagger.enumerateTags(
            in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { lexicalClass, range in
            guard sentence[range] == request.word else {
                return true
            }
            let lemma = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma).0
            grammar = (lemma?.rawValue, lexicalClass.flatMap { Self.partsOfSpeech[$0] })
            return false
        }
        return grammar
    }
}
