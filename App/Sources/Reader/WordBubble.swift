import DesignSystem
import SwiftUI

struct WordBubble: View {
    let lookup: WordLookup
    let language: String
    let translationLanguage: String
    let open: () -> Void

    var body: some View {
        TranslationBubble(
            word: Text(verbatim: lookup.word.text, spokenIn: Locale(identifier: language)),
            phase: phase,
            wordLocale: Locale(identifier: language),
            translationLocale: Locale(identifier: translationLanguage),
            details: TranslationDetails(hint: .opensDetails, action: open),
            identifier: "reader.bubble"
        )
    }

    private var phase: TranslationBubble.Phase {
        switch lookup.phase {
        case .loading:
            .loading(label: .translating(lookup.word.text))
        case .translated(let translation):
            .translated(
                translation: Text(verbatim: translation.translation), ipa: Text(verbatim: translation.ipa),
                grammar: translation.grammar.map { Text(verbatim: $0) })
        case .failed:
            .failed(message: .translationUnavailable)
        case .notNeeded:
            .failed(message: .noTranslationNeeded)
        }
    }
}
