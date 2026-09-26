import DesignSystem
import ReaderEngine
import SwiftUI

struct WordBubble: View {
    private enum Outcome {
        case translated(WordTranslation)
        case failed
    }

    let word: ReaderWord
    let language: String

    @Environment(TranslationService.self) private var translationService
    @Environment(Settings.self) private var settings
    @State private var outcome: Outcome?

    var body: some View {
        TranslationBubble(
            word: Text(verbatim: word.text),
            phase: phase,
            wordLocale: Locale(identifier: language),
            translationLocale: Locale(identifier: settings.translationLanguage),
            identifier: "reader.bubble"
        )
        .task { await translate() }
    }

    private var request: TranslationRequest {
        TranslationRequest(
            word: word.text, sentence: word.sentence, offsetInSentence: word.offsetInSentence, source: language,
            target: settings.translationLanguage)
    }

    private var isSameLanguage: Bool {
        language == settings.translationLanguage
    }

    private var phase: TranslationBubble.Phase {
        if isSameLanguage {
            return .failed(message: Text("No translation needed"))
        }
        switch outcome ?? translationService.cached(request).map(Outcome.translated) {
        case .translated(let translation):
            return .translated(
                translation: Text(verbatim: translation.translation), ipa: Text(verbatim: translation.ipa),
                grammar: grammar(of: translation))
        case .failed:
            return .failed(message: Text("Translation unavailable"))
        case nil:
            return .loading(label: Text("Translating \(word.text)"))
        }
    }

    private func grammar(of translation: WordTranslation) -> Text? {
        let partOfSpeech = translation.partOfSpeech.map { String(localized: $0.name) }
        switch (translation.lemma, partOfSpeech) {
        case (let lemma?, let partOfSpeech?):
            return Text(verbatim: String(localized: "\(lemma) · \(partOfSpeech)"))
        case (let lemma?, nil):
            return Text(verbatim: lemma)
        case (nil, let partOfSpeech?):
            return Text(verbatim: partOfSpeech)
        case (nil, nil):
            return nil
        }
    }

    private func translate() async {
        guard !isSameLanguage, translationService.cached(request) == nil else {
            return
        }
        do {
            outcome = .translated(try await translationService.translate(request))
        } catch {
            outcome = .failed
        }
    }
}

extension PartOfSpeech {
    fileprivate var name: LocalizedStringResource {
        switch self {
        case .noun: "noun"
        case .verb: "verb"
        case .adjective: "adjective"
        case .adverb: "adverb"
        case .pronoun: "pronoun"
        case .determiner: "determiner"
        case .particle: "particle"
        case .preposition: "preposition"
        case .number: "number"
        case .conjunction: "conjunction"
        case .interjection: "interjection"
        }
    }
}
