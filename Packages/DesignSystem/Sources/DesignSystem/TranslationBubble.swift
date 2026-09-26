import SwiftUI

private let rowSpacing: CGFloat = 6

public struct TranslationBubble: View {
    public enum Phase {
        case loading(label: Text)
        case translated(translation: Text, ipa: Text, grammar: Text?)
        case failed(message: Text)
    }

    private static let width: CGFloat = 236
    private static let horizontalPadding: CGFloat = 14
    private static let chevronSize: CGFloat = 16
    private static let chevronStroke: CGFloat = 2.2

    let word: Text
    let phase: Phase
    let wordLocale: Locale
    let translationLocale: Locale
    let identifier: String

    public init(word: Text, phase: Phase, wordLocale: Locale, translationLocale: Locale, identifier: String) {
        self.word = word
        self.phase = phase
        self.wordLocale = wordLocale
        self.translationLocale = translationLocale
        self.identifier = identifier
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: .radiusXl)
        VStack(alignment: .leading, spacing: rowSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: .space2) {
                word
                    .textStyle(TextStyle.footnote.weighted(TextStyle.title3.weight))
                    .foregroundStyle(.ink)
                    .accessibilityIdentifier("\(identifier).word")
                Spacer(minLength: 0)
                if case .translated(_, let ipa, _) = phase {
                    ipa
                        .textStyle(.caption)
                        .foregroundStyle(.inkMuted)
                        .accessibilityIdentifier("\(identifier).ipa")
                }
            }
            .environment(\.locale, wordLocale)
            switch phase {
            case .loading(let label):
                TranslationLoading()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(label)
                    .accessibilityIdentifier("\(identifier).loading")
            case .translated(let translation, _, let grammar):
                translation
                    .textStyle(.translation)
                    .foregroundStyle(.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.locale, translationLocale)
                    .accessibilityIdentifier("\(identifier).translation")
                HStack(spacing: .space2) {
                    grammar?
                        .textStyle(.caption)
                        .foregroundStyle(.inkMuted)
                        .environment(\.locale, wordLocale)
                        .accessibilityIdentifier("\(identifier).grammar")
                    Spacer(minLength: 0)
                    IconView(icon: .chevronDown, size: Self.chevronSize, stroke: Self.chevronStroke)
                        .foregroundStyle(.inkFaint)
                }
            case .failed(let message):
                message
                    .textStyle(.footnote)
                    .foregroundStyle(.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(identifier).failure")
            }
        }
        .padding(.vertical, .space3)
        .padding(.horizontal, Self.horizontalPadding)
        .frame(width: Self.width, alignment: .leading)
        .contentShape(shape)
        .glassEffect(.regular.tint(.surfaceGlassStrong), in: shape)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}

private struct TranslationLoading: View {
    private static let barWidth: CGFloat = 132
    private static let barHeight: CGFloat = 14
    private static let dotSize: CGFloat = 5
    private static let dotSpacing: CGFloat = 3
    private static let dotOpacities: [Double] = [1, 0.5, 0.25]
    private static let dotStep: TimeInterval = 0.3
    private static let shimmerPeriod: TimeInterval = 1.2
    private static let shimmerLowest = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            VStack(alignment: .leading, spacing: rowSpacing) {
                Capsule()
                    .fill(.track)
                    .opacity(shimmer(at: time))
                    .frame(width: Self.barWidth, height: Self.barHeight)
                    .frame(height: TextStyle.translation.lineHeight)
                HStack(spacing: Self.dotSpacing) {
                    Spacer(minLength: 0)
                    ForEach(Self.dotOpacities.indices, id: \.self) { index in
                        Circle()
                            .fill(.accent)
                            .opacity(dotOpacity(index, at: time))
                            .frame(width: Self.dotSize, height: Self.dotSize)
                    }
                }
                .frame(height: TextStyle.caption.lineHeight)
            }
        }
    }

    private func shimmer(at time: TimeInterval) -> Double {
        let wave = (cos(time / Self.shimmerPeriod * 2 * .pi) + 1) / 2
        return Self.shimmerLowest + (1 - Self.shimmerLowest) * wave
    }

    private func dotOpacity(_ index: Int, at time: TimeInterval) -> Double {
        let count = Self.dotOpacities.count
        let step = Int(time / Self.dotStep) % count
        return Self.dotOpacities[(index - step + count) % count]
    }
}

public struct TranslationBubblePlacement: Layout {
    private static let gap: CGFloat = 10

    let anchor: CGRect
    let topLimit: CGFloat

    public init(anchor: CGRect, topLimit: CGFloat) {
        self.anchor = anchor
        self.topLimit = topLimit
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let x = min(max(anchor.midX - size.width / 2, .space4), bounds.width - .space4 - size.width)
            let above = anchor.minY - Self.gap - size.height
            let y = above >= topLimit ? above : anchor.maxY + Self.gap
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), anchor: .topLeading,
                proposal: ProposedViewSize(size))
        }
    }
}
