import SwiftUI

public struct StackedTitle: View {
    private static let spacing: CGFloat = 2

    let title: Text
    let subtitle: Text?
    let titleIdentifier: String
    let subtitleIdentifier: String

    public init(title: Text, subtitle: Text?, titleIdentifier: String, subtitleIdentifier: String) {
        self.title = title
        self.subtitle = subtitle
        self.titleIdentifier = titleIdentifier
        self.subtitleIdentifier = subtitleIdentifier
    }

    public var body: some View {
        VStack(spacing: Self.spacing) {
            title
                .textStyle(TextStyle.footnote.weighted(TextStyle.title3.weight))
                .foregroundStyle(.ink)
                .lineLimit(1)
                .accessibilityIdentifier(titleIdentifier)
            if let subtitle {
                subtitle
                    .textStyle(.caption)
                    .foregroundStyle(.inkMuted)
                    .lineLimit(1)
                    .accessibilityIdentifier(subtitleIdentifier)
            }
        }
    }
}
