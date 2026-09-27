import SwiftUI

public struct WordCard: View {
    public enum Phase {
        case loading(label: Text)
        case translated(details: Text, translation: Text, meaningInContext: Text, meanings: [Text])
        case failed(message: Text)
    }

    public struct Pronounce {
        let label: Text
        let action: () -> Void

        public init(label: Text, action: @escaping () -> Void) {
            self.label = label
            self.action = action
        }
    }

    private static let detailsSpacing: CGFloat = 6
    private static let contextVerticalPadding: CGFloat = 14
    private static let contextTitleSpacing: CGFloat = 6
    private static let loadingBarWidth: CGFloat = 132
    private static let loadingBarHeight: CGFloat = 14
    private static let loadingSpacing: CGFloat = 10
    private static let meaningSpacing: CGFloat = 10
    private static let numberWidth: CGFloat = 14
    private static let headwordStyle = TextStyle.headline.unclipped()
    private static let translationSize: CGFloat = 22
    private static let translationStyle = TextStyle.translation.scaled(to: translationSize)
        .weighted(TextStyle.title3.weight)
    private static let meaningInContextStyle = TextStyle.subhead.weighted(TextStyle.body.weight)
    private static let meaningStyle = TextStyle.callout.weighted(TextStyle.body.weight)

    let word: Text
    let phase: Phase
    let contextTitle: Text
    let meaningsTitle: Text
    let wordLocale: Locale
    let translationLocale: Locale
    let pronounce: Pronounce?
    let identifier: String

    public init(
        word: Text, phase: Phase, contextTitle: Text, meaningsTitle: Text, wordLocale: Locale,
        translationLocale: Locale, pronounce: Pronounce?, identifier: String
    ) {
        self.word = word
        self.phase = phase
        self.contextTitle = contextTitle
        self.meaningsTitle = meaningsTitle
        self.wordLocale = wordLocale
        self.translationLocale = translationLocale
        self.pronounce = pronounce
        self.identifier = identifier
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space4) {
            header
            context
            if case .translated(_, _, _, let meanings) = phase, !meanings.isEmpty {
                meaningList(meanings)
            }
        }
        .padding(.horizontal, .space5)
        .padding(.bottom, .space5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: .space3) {
            VStack(alignment: .leading, spacing: Self.detailsSpacing) {
                word
                    .textStyle(Self.headwordStyle)
                    .foregroundStyle(.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("\(identifier).word")
                if case .translated(let details, _, _, _) = phase {
                    details
                        .textStyle(.footnote)
                        .foregroundStyle(.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("\(identifier).details")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.locale, wordLocale)
            .environment(\.layoutDirection, wordLocale.textDirection)
            if let pronounce {
                PronounceButton(pronounce: pronounce)
                    .accessibilityIdentifier("\(identifier).pronounce")
            }
        }
    }

    private var context: some View {
        VStack(alignment: .leading, spacing: 0) {
            contextTitle
                .textStyle(.labelCaps)
                .foregroundStyle(.accent)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, Self.contextTitleSpacing)
            switch phase {
            case .loading(let label):
                TranslationLoading { time in
                    HStack(spacing: Self.loadingSpacing) {
                        TranslationLoadingBar(width: Self.loadingBarWidth, height: Self.loadingBarHeight, time: time)
                        TranslationLoadingDots(time: time)
                    }
                    .frame(height: Self.translationStyle.lineHeight)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityIdentifier("\(identifier).loading")
            case .translated(_, let translation, let meaningInContext, _):
                VStack(alignment: .leading, spacing: .space1) {
                    translation
                        .textStyle(Self.translationStyle)
                        .foregroundStyle(.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("\(identifier).translation")
                    meaningInContext
                        .textStyle(Self.meaningInContextStyle)
                        .foregroundStyle(.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("\(identifier).meaningInContext")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.locale, translationLocale)
                .environment(\.layoutDirection, translationLocale.textDirection)
            case .failed(let message):
                message
                    .textStyle(Self.meaningInContextStyle)
                    .foregroundStyle(.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(identifier).failure")
            }
        }
        .padding(.vertical, Self.contextVerticalPadding)
        .padding(.horizontal, .space4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.surface, in: RoundedRectangle(cornerRadius: .radiusLg))
    }

    private func meaningList(_ meanings: [Text]) -> some View {
        VStack(alignment: .leading, spacing: Self.meaningSpacing) {
            meaningsTitle
                .textStyle(.labelCaps)
                .foregroundStyle(.inkMuted)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Self.meaningSpacing) {
                ForEach(meanings.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: Self.meaningSpacing) {
                        Text(index + 1, format: .number)
                            .foregroundStyle(.inkMuted)
                            .frame(width: Self.numberWidth, alignment: .leading)
                        meanings[index]
                            .foregroundStyle(.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .environment(\.locale, translationLocale)
                            .environment(\.layoutDirection, translationLocale.textDirection)
                    }
                    .textStyle(Self.meaningStyle)
                    .accessibilityElement(children: .combine)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("\(identifier).meanings")
        }
    }
}

private struct PronounceButton: View {
    private static let iconStroke: CGFloat = 2

    @ScaledMetric private var size: CGFloat = 40
    @ScaledMetric private var iconSize: CGFloat = 18

    let pronounce: WordCard.Pronounce

    var body: some View {
        Button(action: pronounce.action) {
            IconView(icon: .speaker, size: iconSize, stroke: Self.iconStroke)
                .foregroundStyle(.ink)
                .frame(width: size, height: size)
                .background(.surfaceCard, in: .circle)
                .overlay { Circle().strokeBorder(.controlBorder, lineWidth: .hairlineW) }
                .contentShape(Circle().inset(by: -max(0, (.controlH - size) / 2)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pronounce.label)
    }
}

extension Locale {
    fileprivate var textDirection: LayoutDirection {
        language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }
}
