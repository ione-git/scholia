#if DEBUG
    import SwiftData
    import SwiftUI

    struct ReadingDiagnostics: View {
        @Query(sort: \ReadingSession.start) private var sessions: [ReadingSession]

        var body: some View {
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("debug.readingSessions")
                .accessibilityLabel(Text(verbatim: summary))
        }

        private var summary: String {
            let format = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
            return sessions.map { session in
                "\(session.start.formatted(format)) – \(session.end.formatted(format)) · \(session.pages) pages"
            }
            .joined(separator: "\n")
        }
    }
#endif
