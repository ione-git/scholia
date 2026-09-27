import SwiftUI

public struct ThemeSwatch: View {
    private static let diameter: CGFloat = 48
    private static let ringGap: CGFloat = 2
    private static let ringWidth: CGFloat = 2
    private static let sample = TextStyle.readingBody.scaled(to: 18)

    let theme: ReaderTheme
    let title: Text
    let label: Text
    let isSelected: Bool
    let action: () -> Void

    public init(_ theme: ReaderTheme, title: Text, label: Text, isSelected: Bool, action: @escaping () -> Void) {
        self.theme = theme
        self.title = title
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: .space2) {
                Text(verbatim: "Aa")
                    .font(Self.sample.font)
                    .foregroundStyle(theme.text)
                    .frame(width: Self.diameter, height: Self.diameter)
                    .background(theme.page, in: .circle)
                    .overlay { ring }
                title
                    .textStyle(isSelected ? TextStyle.caption.weighted(TextStyle.title3.weight) : .caption)
                    .foregroundStyle(isSelected ? Color.ink : Color.inkMuted)
                    .lineLimit(1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var ring: some View {
        if isSelected {
            Circle()
                .strokeBorder(.accent, lineWidth: Self.ringWidth)
                .background { Circle().strokeBorder(.surfaceCard, lineWidth: Self.ringGap).padding(Self.ringWidth) }
                .padding(-(Self.ringGap + Self.ringWidth))
        } else {
            Circle().strokeBorder(.controlBorder, lineWidth: .hairlineW)
        }
    }
}
