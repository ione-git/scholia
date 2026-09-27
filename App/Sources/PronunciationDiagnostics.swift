#if DEBUG
    import SwiftUI

    struct PronunciationDiagnostics: View {
        let pronouncer: Pronouncer

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.pronunciations")
                .accessibilityLabel(Text(verbatim: pronouncer.requests.joined(separator: "\n")))
        }
    }
#endif
