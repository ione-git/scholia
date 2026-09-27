import SwiftUI

public struct HighlightColorMenu<Swatches: View, Delete: View>: View {
    private static var minWidth: CGFloat { 276 }
    private static var height: CGFloat { 48 }
    private static var leadingInset: CGFloat { 14 }
    private static var trailingInset: CGFloat { .space3 }
    private static var separatorHeight: CGFloat { 24 }

    let swatches: Swatches
    let delete: Delete

    public init(@ViewBuilder swatches: () -> Swatches, @ViewBuilder delete: () -> Delete) {
        self.swatches = swatches()
        self.delete = delete()
    }

    public var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                swatches
            }
            .padding(.trailing, -HighlightSwatch.gap / 2)
            Spacer(minLength: HighlightSwatch.gap)
            Rectangle()
                .fill(.hairline)
                .frame(width: .hairlineW, height: Self.separatorHeight)
            Spacer(minLength: HighlightSwatch.gap)
            delete
        }
        .padding(.leading, Self.leadingInset - HighlightSwatch.gap / 2)
        .padding(.trailing, Self.trailingInset)
        .frame(minWidth: Self.minWidth)
        .frame(height: Self.height)
        .glassEffect(.regular.tint(.surfaceGlassStrong), in: .capsule)
        .accessibilityElement(children: .contain)
    }
}

public struct HighlightSwatch: View {
    static var gap: CGFloat { .space3 }
    private static var diameter: CGFloat { 26 }
    private static var ringWidth: CGFloat { 1.5 }
    private static var ringGap: CGFloat { 2 }

    let color: Color
    let label: Text
    let isSelected: Bool
    let action: () -> Void

    public init(color: Color, label: Text, isSelected: Bool, action: @escaping () -> Void) {
        self.color = color
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: Self.diameter, height: Self.diameter)
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(.ink, lineWidth: Self.ringWidth)
                            .frame(width: ringDiameter, height: ringDiameter)
                    }
                }
                .frame(width: Self.diameter + Self.gap)
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var ringDiameter: CGFloat {
        Self.diameter + 2 * (Self.ringGap + Self.ringWidth)
    }
}

public struct HighlightDeleteButton: View {
    private static var width: CGFloat { 36 }
    private static var iconSize: CGFloat { 18 }
    private static var iconStroke: CGFloat { 2 }

    let label: Text
    let action: () -> Void

    public init(label: Text, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(role: .destructive, action: action) {
            IconView(icon: .trash, size: Self.iconSize, stroke: Self.iconStroke)
                .foregroundStyle(.danger)
                .frame(width: Self.width)
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
