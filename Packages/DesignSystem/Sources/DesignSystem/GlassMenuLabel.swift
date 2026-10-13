import SwiftUI

public struct GlassMenuLabel: View {
    private static let iconSize: CGFloat = 20
    private static let iconStroke: CGFloat = 2

    let icon: Icon
    let label: Text
    let size: GlassButton.Size

    public init(_ icon: Icon, label: Text, size: GlassButton.Size) {
        self.icon = icon
        self.label = label
        self.size = size
    }

    public var body: some View {
        IconView(icon: icon, size: Self.iconSize, stroke: Self.iconStroke)
            .foregroundStyle(.ink)
            .frame(width: size.diameter, height: size.diameter)
            .glassEffect(.regular.interactive(), in: .circle)
            .contentShape(.circle)
            .accessibilityLabel(label)
    }
}
