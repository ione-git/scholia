import SwiftUI

public struct SolidButtonStyle: PrimitiveButtonStyle {
    public enum Size: Sendable {
        case regular
        case compact
    }

    private static let height: CGFloat = 52
    private static let compactHeight: CGFloat = 48

    let size: Size

    public init(size: Size) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            Group {
                switch size {
                case .regular:
                    configuration.label
                        .textStyle(.title3)
                        .frame(maxWidth: .infinity, minHeight: Self.height)
                case .compact:
                    configuration.label
                        .textStyle(TextStyle.body.weighted(TextStyle.title3.weight))
                        .padding(.horizontal, .space6)
                        .frame(minHeight: Self.compactHeight)
                }
            }
            .foregroundStyle(.onInk)
            .background(.ink, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

extension PrimitiveButtonStyle where Self == SolidButtonStyle {
    public static var solid: SolidButtonStyle { SolidButtonStyle(size: .regular) }

    public static func solid(_ size: SolidButtonStyle.Size) -> SolidButtonStyle { SolidButtonStyle(size: size) }
}
