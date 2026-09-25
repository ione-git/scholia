import SwiftUI

public struct SolidButtonStyle: PrimitiveButtonStyle {
    private static let height: CGFloat = 52

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            configuration.label
                .textStyle(.title3)
                .foregroundStyle(.onInk)
                .frame(maxWidth: .infinity, minHeight: Self.height)
                .background(.ink, in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

extension PrimitiveButtonStyle where Self == SolidButtonStyle {
    public static var solid: SolidButtonStyle { SolidButtonStyle() }
}
