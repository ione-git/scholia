import DesignSystem
import SwiftUI

struct WordPill: View {
    let lookup: WordLookup
    let translationLanguage: String
    let open: () -> Void

    var body: some View {
        TranslationPill(
            phase: phase,
            translationLocale: Locale(identifier: translationLanguage),
            details: TranslationDetails(hint: .opensDetails, action: open),
            identifier: "reader.pill"
        )
    }

    private var phase: TranslationPill.Phase {
        switch lookup.phase {
        case .loading:
            .loading(label: .translating(lookup.word.text))
        case .translated(let translation):
            .translated(
                translation: Text(verbatim: translation.translation),
                label: Text(
                    "\(lookup.word.text): \(translation.translation)",
                    comment: "VoiceOver label of the translation pill: the tapped word, then its translation"))
        case .failed:
            .failed(message: .translationUnavailable)
        case .notNeeded:
            .failed(message: .noTranslationNeeded)
        }
    }
}
