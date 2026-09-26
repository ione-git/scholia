#if DEBUG
    import SwiftUI

    struct SafeAreaDiagnostics: View {
        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.safeArea")
        }
    }
#endif
