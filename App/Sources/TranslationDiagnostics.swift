#if DEBUG
    import SwiftUI

    struct TranslationDiagnostics: View {
        let provider: any TranslationProvider

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.translationRequests")
                .accessibilityLabel(Text(verbatim: requests))
        }

        private var requests: String {
            let requests = (provider as? MockTranslationProvider)?.requests ?? []
            return requests.map { "\($0.word) · \($0.offsetInSentence) · \($0.source) → \($0.target)" }
                .joined(separator: "\n")
        }
    }
#endif
