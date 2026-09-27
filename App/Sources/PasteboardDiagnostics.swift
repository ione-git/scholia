#if DEBUG
    import SwiftUI
    import UIKit

    struct PasteboardDiagnostics: View {
        @State private var copied = ""

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.pasteboard")
                .accessibilityLabel(Text(verbatim: copied))
                .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
                    copied = UIPasteboard.general.string ?? ""
                }
        }
    }
#endif
