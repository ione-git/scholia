import DesignSystem
import SwiftUI

struct WordCardSheet: View {
    let lookup: WordLookup
    let language: String
    let translationLanguage: String
    let canPronounce: Bool

    @Environment(Pronouncer.self) private var pronouncer

    var body: some View {
        WordCard(
            word: Text(verbatim: lookup.word.text),
            phase: phase,
            contextTitle: Text(
                "In this context", comment: "Word card: label above the translation of the word in its sentence"),
            meaningsTitle: Text(
                "All meanings", comment: "Word card: label above the numbered dictionary meanings of the word"),
            wordLocale: Locale(identifier: language),
            translationLocale: Locale(identifier: translationLanguage),
            pronounce: canPronounce ? pronounce : nil,
            identifier: "wordCard"
        )
    }

    private var pronounce: WordCard.Pronounce {
        WordCard.Pronounce(
            label: Text(
                "Pronounce", comment: "Word card: VoiceOver label of the button that speaks the word aloud")
        ) {
            pronouncer.speak(lookup.word.text, language: language)
        }
    }

    private var phase: WordCard.Phase {
        switch lookup.phase {
        case .loading:
            .loading(label: .translating(lookup.word.text))
        case .translated(let translation):
            .translated(
                details: Text(verbatim: translation.details),
                translation: Text(verbatim: translation.translation),
                meaningInContext: Text(verbatim: translation.meaningInContext),
                meanings: translation.meanings.map(Text.init(meaning:)))
        case .failed:
            .failed(message: .translationUnavailable)
        case .notNeeded:
            .failed(message: .noTranslationNeeded)
        }
    }
}

extension Text {
    fileprivate init(meaning: WordMeaning) {
        guard let note = meaning.note else {
            self.init(verbatim: meaning.text)
            return
        }
        let noteText = Text(
            "— \(note)", comment: "Word card: usage note after a dictionary meaning, e.g. “— figurative”"
        )
        .foregroundStyle(Color.inkMuted)
        self.init("\(Text(verbatim: meaning.text)) \(noteText)")
    }
}
