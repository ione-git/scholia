import SwiftUI

public struct CoverPlaceholder: View {
    private static let size = BookCover.Size.hero
    private static let iconSize: CGFloat = 32
    private static let iconStroke: CGFloat = 1.8
    private static let borderWidth: CGFloat = 1.5
    private static let dash: [CGFloat] = [4.5, 4.5]

    let label: Text
    let action: () -> Void

    public init(label: Text, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.size.metrics.radius)
        Button(action: action) {
            IconView(icon: .add, size: Self.iconSize, stroke: Self.iconStroke)
                .foregroundStyle(.inkFaint)
                .frame(width: Self.size.width, height: Self.size.height)
                .overlay {
                    shape.strokeBorder(.inkFaint, style: StrokeStyle(lineWidth: Self.borderWidth, dash: Self.dash))
                }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
