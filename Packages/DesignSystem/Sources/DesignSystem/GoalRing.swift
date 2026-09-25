import SwiftUI

public struct GoalRing: View {
    private static let size: CGFloat = 32
    private static let radius: CGFloat = 12
    private static let lineWidth: CGFloat = 4
    private static let start = Angle.degrees(-90)

    let value: Double

    public init(value: Double) {
        self.value = value
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(.track, lineWidth: Self.lineWidth)
            Circle()
                .trim(from: 0, to: value)
                .stroke(.accent, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
                .rotationEffect(Self.start)
        }
        .frame(width: 2 * Self.radius, height: 2 * Self.radius)
        .frame(width: Self.size, height: Self.size)
        .accessibilityElement()
        .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
    }
}
