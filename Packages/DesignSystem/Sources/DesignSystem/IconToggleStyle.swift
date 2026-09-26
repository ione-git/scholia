import SwiftUI

public struct IconToggleStyle: ToggleStyle {
    private static let width: CGFloat = 44
    private static let height: CGFloat = 40
    private static let iconSize: CGFloat = 20
    private static let iconStroke: CGFloat = 2

    let icon: Icon

    public init(_ icon: Icon) {
        self.icon = icon
    }

    public func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: .radiusMd)
        return Button {
            configuration.isOn.toggle()
        } label: {
            IconView(icon: icon, size: Self.iconSize, stroke: Self.iconStroke)
                .foregroundStyle(configuration.isOn ? Color.onInk : Color.ink)
                .frame(width: Self.width, height: Self.height)
                .background(configuration.isOn ? Color.ink : Color.controlFill, in: shape)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

extension ToggleStyle where Self == IconToggleStyle {
    public static func icon(_ icon: Icon) -> IconToggleStyle { IconToggleStyle(icon) }
}
