import SwiftUI

private let chipHeight: CGFloat = 36

public struct Chip: View {
    private static let padding: CGFloat = 14
    private static let countSpacing: CGFloat = 6
    private static let selectedCountOpacity = 0.6

    let title: Text
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    public init(_ title: Text, count: Int, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Self.countSpacing) {
                title.foregroundStyle(isSelected ? Color.onInk : Color.ink)
                Text(count, format: .number)
                    .foregroundStyle(isSelected ? Color.onInk.opacity(Self.selectedCountOpacity) : Color.inkMuted)
            }
            .textStyle(.subhead)
            .lineLimit(1)
            .padding(.horizontal, Self.padding)
            .frame(height: chipHeight)
            .background {
                if isSelected {
                    Capsule().fill(.ink)
                } else {
                    Capsule().fill(.surfaceCard).strokeBorder(.controlBorder, lineWidth: .hairlineW)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public struct NewCollectionChip: View {
    private static let iconSize: CGFloat = 16
    private static let iconStroke: CGFloat = 2.2
    private static let borderWidth: CGFloat = 1
    private static let dash: [CGFloat] = [3, 3]

    let label: Text
    let action: () -> Void

    public init(label: Text, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            IconView(icon: .add, size: Self.iconSize, stroke: Self.iconStroke)
                .foregroundStyle(.inkMuted)
                .frame(width: chipHeight, height: chipHeight)
                .overlay {
                    Circle().strokeBorder(.inkFaint, style: StrokeStyle(lineWidth: Self.borderWidth, dash: Self.dash))
                }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
