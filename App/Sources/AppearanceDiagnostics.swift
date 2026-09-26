#if DEBUG
    import SwiftUI

    struct AppearanceDiagnostics: View {
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.colorScheme")
                .accessibilityLabel(Text(verbatim: colorScheme == .dark ? "dark" : "light"))
        }
    }
#endif
