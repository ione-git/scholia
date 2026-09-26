import SwiftUI

struct TranslationLoading<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder let content: (TimeInterval) -> Content

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            content(reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate)
        }
    }
}

struct TranslationLoadingBar: View {
    private static let period: TimeInterval = 1.2
    private static let lowest = 0.5

    let width: CGFloat
    let height: CGFloat
    let time: TimeInterval

    var body: some View {
        Capsule()
            .fill(.track)
            .opacity(shimmer)
            .frame(width: width, height: height)
    }

    private var shimmer: Double {
        let wave = (cos(time / Self.period * 2 * .pi) + 1) / 2
        return Self.lowest + (1 - Self.lowest) * wave
    }
}

struct TranslationLoadingDots: View {
    private static let size: CGFloat = 5
    private static let spacing: CGFloat = 3
    private static let opacities: [Double] = [1, 0.5, 0.25]
    private static let step: TimeInterval = 0.3

    let time: TimeInterval

    var body: some View {
        HStack(spacing: Self.spacing) {
            ForEach(Self.opacities.indices, id: \.self) { index in
                Circle()
                    .fill(.accent)
                    .opacity(opacity(index))
                    .frame(width: Self.size, height: Self.size)
            }
        }
    }

    private func opacity(_ index: Int) -> Double {
        let count = Self.opacities.count
        let current = Int(time / Self.step) % count
        return Self.opacities[(index - current + count) % count]
    }
}

struct TranslationLoadingBlock: View {
    static let rowSpacing: CGFloat = 6
    private static let barWidth: CGFloat = 132
    private static let barHeight: CGFloat = 14

    let lineHeight: CGFloat

    var body: some View {
        TranslationLoading { time in
            VStack(alignment: .leading, spacing: Self.rowSpacing) {
                TranslationLoadingBar(width: Self.barWidth, height: Self.barHeight, time: time)
                    .frame(height: lineHeight)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    TranslationLoadingDots(time: time)
                }
                .frame(height: TextStyle.caption.lineHeight)
            }
        }
    }
}
