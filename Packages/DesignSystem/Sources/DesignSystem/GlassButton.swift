import SwiftUI

public struct GlassButton: View {
    public enum Size: Sendable {
        case regular
        case reader

        public var diameter: CGFloat {
            switch self {
            case .regular: .controlH
            case .reader: 48
            }
        }
    }

    private static let iconSize: CGFloat = 20
    private static let iconStroke: CGFloat = 2

    let icon: Icon
    let label: Text
    let size: Size
    let isActive: Bool
    let action: () -> Void

    public init(_ icon: Icon, label: Text, size: Size, isActive: Bool, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.size = size
        self.isActive = isActive
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            IconView(icon: icon, size: Self.iconSize, stroke: Self.iconStroke)
                .foregroundStyle(isActive ? Color.onInk : Color.ink)
                .frame(width: size.diameter, height: size.diameter)
                .background {
                    if isActive {
                        Circle().fill(.ink)
                    }
                }
                .glassEffect(isActive ? .identity : .regular.interactive(), in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
