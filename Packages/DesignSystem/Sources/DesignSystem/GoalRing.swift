import SwiftUI

public struct GoalRing: View {
    public enum Size: Sendable {
        case header
        case popover

        public var width: CGFloat { metrics.width }

        var metrics: Metrics {
            switch self {
            case .header: Metrics(width: 32, radius: 12, lineWidth: 4)
            case .popover: Metrics(width: 56, radius: 23, lineWidth: 6)
            }
        }
    }

    struct Metrics {
        let width: CGFloat
        let radius: CGFloat
        let lineWidth: CGFloat
    }

    private static let start = Angle.degrees(-90)
    private static let doneRadius: CGFloat = 14
    private static let checkSize: CGFloat = 20
    private static let checkLineWidth: CGFloat = 2.8

    let value: Double
    let size: Size
    let isActive: Bool
    let center: Text?

    public init(value: Double, size: Size, isActive: Bool, center: Text?) {
        self.value = value
        self.size = size
        self.isActive = isActive
        self.center = center
    }

    public var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .fill(.accentTint)
            }
            if size == .header, value >= 1 {
                Circle()
                    .fill(.accent)
                    .frame(width: 2 * Self.doneRadius, height: 2 * Self.doneRadius)
                IconView(icon: .check, size: Self.checkSize, stroke: Self.checkLineWidth * Icon.grid / Self.checkSize)
                    .foregroundStyle(.onAccent)
            } else {
                ring
            }
            center?
                .textStyle(.title3)
                .foregroundStyle(.ink)
        }
        .frame(width: size.width, height: size.width)
        .accessibilityElement()
        .accessibilityValue(Text(min(value, 1), format: .percent.precision(.fractionLength(0))))
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(.track, lineWidth: size.metrics.lineWidth)
            Circle()
                .trim(from: 0, to: min(value, 1))
                .stroke(.accent, style: StrokeStyle(lineWidth: size.metrics.lineWidth, lineCap: .round))
                .rotationEffect(Self.start)
        }
        .frame(width: 2 * size.metrics.radius, height: 2 * size.metrics.radius)
    }
}
