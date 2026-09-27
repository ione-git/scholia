import SwiftUI

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
    private static let wordLineLimit = 2

    let word: Text
    let phase: Phase
    let wordLocale: Locale
    let translationLocale: Locale
    let details: TranslationDetails?
    let identifier: String

    public init(
        word: Text, phase: Phase, wordLocale: Locale, translationLocale: Locale, details: TranslationDetails?,
        identifier: String
    ) {
        self.word = word
        self.phase = phase
        self.wordLocale = wordLocale
        self.translationLocale = translationLocale
        self.details = details
        self.identifier = identifier
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: .radiusXl)
        VStack(alignment: .leading, spacing: TranslationLoadingBlock.rowSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: .space2) {
                word
                    .textStyle(TextStyle.footnote.weighted(TextStyle.title3.weight))
                    .foregroundStyle(.ink)
                    .lineLimit(Self.wordLineLimit)
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
                TranslationLoadingBlock(lineHeight: TextStyle.translation.lineHeight)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(label)
                    .accessibilityIdentifier("\(identifier).loading")
            case .translated(let translation, _, let grammar):
                translation
                    .textStyle(.translation)
                    .foregroundStyle(.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.locale, translationLocale)
                    .accessibilityOpensDetails(details)
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
        .glassEffect(.regular.tint(.surfaceGlassStrong).interactive(opensDetails), in: shape)
        .gesture(TapGesture().onEnded { details?.action() }, isEnabled: opensDetails)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }

    private var opensDetails: Bool {
        guard details != nil, case .translated = phase else {
            return false
        }
        return true
    }
}
