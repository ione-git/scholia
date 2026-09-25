#if DEBUG
    import SwiftUI

    struct LaunchDiagnostics: View {
        let configuration: LaunchConfiguration

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.launchConfiguration")
                .accessibilityLabel(Text(verbatim: received.summary))
                .accessibilityValue(Text(verbatim: TimeZone.current.identifier))
        }

        private var received: LaunchConfiguration {
            var received = configuration
            received.fixtures = configuration.fixtures.filter { $0.url != nil }
            return received
        }
    }
#endif
