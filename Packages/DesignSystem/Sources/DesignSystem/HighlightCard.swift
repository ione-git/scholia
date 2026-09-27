import SwiftUI

public struct HighlightCard: View {
    private static let barWidth: CGFloat = 4

    let quote: Text
    let quoteDirection: LayoutDirection
    let color: Color
    let meta: Text?

    public init(quote: Text, quoteDirection: LayoutDirection, color: Color, meta: Text?) {
        self.quote = quote
        self.quoteDirection = quoteDirection
        self.color = color
        self.meta = meta
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: .radiusXl)
        VStack(alignment: .leading, spacing: .space2) {
            quote
                .textStyle(.readingQuote)
                .foregroundStyle(.ink)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.layoutDirection, quoteDirection)
            meta?
                .textStyle(.caption)
                .foregroundStyle(.inkMuted)
                .accessibilityHidden(true)
        }
        .padding(.leading, Self.barWidth + .space3)
        .background(alignment: .leading) {
            Capsule()
                .fill(color)
                .frame(width: Self.barWidth)
                .accessibilityHidden(true)
        }
        .padding(.space4)
        .background(.surfaceCard, in: shape)
        .shadow(.card, in: shape)
        .contentShape(shape)
    }
}
