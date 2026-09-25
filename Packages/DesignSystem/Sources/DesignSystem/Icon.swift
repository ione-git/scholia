import SwiftUI

public enum Icon: Sendable {
    case back
    case add
    case bookmark
    case more
    case chevron
    case check

    static let grid: CGFloat = 24

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch self {
        case .back:
            path.addLines([CGPoint(x: 15, y: 6), CGPoint(x: 9, y: 12), CGPoint(x: 15, y: 18)])
        case .add:
            path.addLines([CGPoint(x: 12, y: 5), CGPoint(x: 12, y: 19)])
            path.addLines([CGPoint(x: 5, y: 12), CGPoint(x: 19, y: 12)])
        case .bookmark:
            path.addLines([
                CGPoint(x: 6, y: 4), CGPoint(x: 18, y: 4), CGPoint(x: 18, y: 21), CGPoint(x: 12, y: 17),
                CGPoint(x: 6, y: 21),
            ])
            path.closeSubpath()
        case .more:
            for x in [5, 12, 19] {
                path.addEllipse(in: CGRect(x: x - 2, y: 10, width: 4, height: 4))
            }
        case .chevron:
            path.addLines([CGPoint(x: 9, y: 6), CGPoint(x: 15, y: 12), CGPoint(x: 9, y: 18)])
        case .check:
            path.addLines([CGPoint(x: 5, y: 12), CGPoint(x: 10, y: 17), CGPoint(x: 19, y: 7)])
        }
        let scale = min(rect.width, rect.height) / Self.grid
        return path.applying(
            CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: scale, y: scale))
    }

    var isFilled: Bool { self == .more }
}

struct IconView: View {
    let icon: Icon
    let size: CGFloat
    let stroke: CGFloat

    var body: some View {
        Group {
            if icon.isFilled {
                IconShape(icon: icon).fill()
            } else {
                IconShape(icon: icon)
                    .stroke(style: StrokeStyle(lineWidth: stroke * size / Icon.grid, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct IconShape: Shape {
    let icon: Icon

    func path(in rect: CGRect) -> Path { icon.path(in: rect) }
}
