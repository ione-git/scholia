import SwiftUI

public struct TranslationPill: View {
    public enum Phase {
        case loading(label: Text)
        case translated(translation: Text, label: Text)
        case failed(message: Text)
    }

    private static let minWidth: CGFloat = 150
    private static let minHeight: CGFloat = 40
    private static let hitInset = (CGFloat.controlH - minHeight) / 2
    private static let barWidth: CGFloat = 78
    private static let barHeight: CGFloat = 12
    private static let loadingSpacing: CGFloat = 10
    private static let chevronSpacing: CGFloat = 6
    private static let chevronSize: CGFloat = 14
    private static let chevronStroke: CGFloat = 2.4
    private static let translationStyle = TextStyle.title3.weighted(TextStyle.callout.weight)

    let phase: Phase
    let translationLocale: Locale
    let details: TranslationDetails
    let identifier: String

    public init(phase: Phase, translationLocale: Locale, details: TranslationDetails, identifier: String) {
        self.phase = phase
        self.translationLocale = translationLocale
        self.details = details
        self.identifier = identifier
    }

    public var body: some View {
        switch phase {
        case .loading(let label):
            capsule(isInteractive: false) {
                TranslationLoading { time in
                    HStack(spacing: Self.loadingSpacing) {
                        TranslationLoadingBar(width: Self.barWidth, height: Self.barHeight, time: time)
                        TranslationLoadingDots(time: time)
                    }
                }
                .padding(.horizontal, .space4)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityIdentifier("\(identifier).loading")
        case .translated(let translation, let label):
            Button(action: details.action) {
                capsule(isInteractive: true) {
                    HStack(spacing: Self.chevronSpacing) {
                        translation
                            .textStyle(Self.translationStyle)
                            .foregroundStyle(.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .environment(\.locale, translationLocale)
                        IconView(icon: .chevronDown, size: Self.chevronSize, stroke: Self.chevronStroke)
                            .foregroundStyle(.inkFaint)
                    }
                    .padding(.leading, .space4)
                    .padding(.trailing, .space3)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
            .accessibilityHint(details.hint)
            .accessibilityIdentifier(identifier)
        case .failed(let message):
            capsule(isInteractive: false) {
                message
                    .textStyle(.footnote)
                    .foregroundStyle(.inkMuted)
                    .lineLimit(1)
                    .padding(.horizontal, .space4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("\(identifier).failure")
        }
    }

    private func capsule(isInteractive: Bool, @ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(minWidth: Self.minWidth, minHeight: Self.minHeight)
            .contentShape(Capsule().inset(by: -Self.hitInset))
            .glassEffect(.regular.tint(.surfaceGlassStrong).interactive(isInteractive), in: .capsule)
    }
}
