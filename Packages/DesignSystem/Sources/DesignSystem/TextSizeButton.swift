import SwiftUI

public struct TextSizeButton: View {
    public enum Direction: Sendable {
        case smaller
        case larger
    }

    private static let smallerSample = TextStyle.readingBody.scaled(to: 13)
    private static let largerSample = TextStyle.readingBody.scaled(to: 22)

    let direction: Direction
    let label: Text
    let action: () -> Void

    public init(_ direction: Direction, label: Text, action: @escaping () -> Void) {
        self.direction = direction
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(verbatim: "A")
                .font(direction == .smaller ? Self.smallerSample.font : Self.largerSample.font)
                .foregroundStyle(.ink)
                .frame(width: .controlH, height: .controlH)
                .background {
                    Circle().fill(.surfaceCard).strokeBorder(.controlBorder, lineWidth: .hairlineW)
                }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
