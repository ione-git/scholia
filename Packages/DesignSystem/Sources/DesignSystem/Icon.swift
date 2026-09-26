import SwiftUI

public enum Icon: Sendable {
    case back
    case add
    case bookmark
    case more
    case chevron
    case check
    case settings
    case search
    case select
    case newCollection
    case sort
    case collection
    case info
    case trash

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
        case .settings:
            path.addEllipse(in: CGRect(x: 9, y: 9, width: 6, height: 6))
            path.move(to: CGPoint(x: 19.4, y: 15))
            path.addArc(to: CGPoint(x: 19.7, y: 16.8), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 19.8, y: 16.9))
            path.addArc(to: CGPoint(x: 17, y: 19.7), radius: 2, isLarge: true, isSweep: true)
            path.addLine(to: CGPoint(x: 16.9, y: 19.6))
            path.addArc(to: CGPoint(x: 15.1, y: 19.3), radius: 1.7, isLarge: false, isSweep: false)
            path.addArc(to: CGPoint(x: 14.1, y: 20.8), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 14.1, y: 21))
            path.addArc(to: CGPoint(x: 10.1, y: 21), radius: 2, isLarge: true, isSweep: true)
            path.addLine(to: CGPoint(x: 10.1, y: 20.9))
            path.addArc(to: CGPoint(x: 9, y: 19.4), radius: 1.7, isLarge: false, isSweep: false)
            path.addArc(to: CGPoint(x: 7.2, y: 19.7), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 7.1, y: 19.8))
            path.addArc(to: CGPoint(x: 4.3, y: 17), radius: 2, isLarge: true, isSweep: true)
            path.addLine(to: CGPoint(x: 4.4, y: 16.9))
            path.addArc(to: CGPoint(x: 4.7, y: 15.1), radius: 1.7, isLarge: false, isSweep: false)
            path.addArc(to: CGPoint(x: 3.2, y: 14.1), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 3, y: 14.1))
            path.addArc(to: CGPoint(x: 3, y: 10.1), radius: 2, isLarge: true, isSweep: true)
            path.addLine(to: CGPoint(x: 3.1, y: 10.1))
            path.addArc(to: CGPoint(x: 4.6, y: 9), radius: 1.7, isLarge: false, isSweep: false)
            path.addArc(to: CGPoint(x: 4.3, y: 7.2), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 4.2, y: 7.1))
            path.addArc(to: CGPoint(x: 7, y: 4.3), radius: 2, isLarge: true, isSweep: true)
            path.addLine(to: CGPoint(x: 7.1, y: 4.4))
            path.addArc(to: CGPoint(x: 8.9, y: 4.7), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 9, y: 4.7))
            path.addArc(to: CGPoint(x: 10, y: 3.2), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 10, y: 3))
            path.addArc(to: CGPoint(x: 14, y: 3), radius: 2, isLarge: true, isSweep: true)
            path.addLine(to: CGPoint(x: 14, y: 3.1))
            path.addArc(to: CGPoint(x: 15, y: 4.6), radius: 1.7, isLarge: false, isSweep: false)
            path.addArc(to: CGPoint(x: 16.8, y: 4.3), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 16.9, y: 4.2))
            path.addArc(to: CGPoint(x: 19.7, y: 7), radius: 2, isLarge: true, isSweep: true)
            path.addLine(to: CGPoint(x: 19.6, y: 7.1))
            path.addArc(to: CGPoint(x: 19.3, y: 8.9), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 19.3, y: 9))
            path.addArc(to: CGPoint(x: 20.8, y: 10), radius: 1.7, isLarge: false, isSweep: false)
            path.addLine(to: CGPoint(x: 21, y: 10))
            path.addArc(to: CGPoint(x: 21, y: 14), radius: 2, isLarge: true, isSweep: true)
            path.addLine(to: CGPoint(x: 20.9, y: 14))
            path.addArc(to: CGPoint(x: 19.4, y: 15), radius: 1.7, isLarge: false, isSweep: false)
            path.closeSubpath()
        case .search:
            path.addEllipse(in: CGRect(x: 4, y: 4, width: 14, height: 14))
            path.addLines([CGPoint(x: 20, y: 20), CGPoint(x: 16.5, y: 16.5)])
        case .select:
            path.addEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))
            path.addLines([CGPoint(x: 8, y: 12), CGPoint(x: 11, y: 15), CGPoint(x: 16, y: 9)])
        case .newCollection:
            path.addPath(Icon.collection.path(in: CGRect(x: 0, y: 0, width: Self.grid, height: Self.grid)))
            path.addLines([CGPoint(x: 12, y: 10), CGPoint(x: 12, y: 16)])
            path.addLines([CGPoint(x: 9, y: 13), CGPoint(x: 15, y: 13)])
        case .collection:
            path.move(to: CGPoint(x: 3, y: 7))
            path.addArc(to: CGPoint(x: 5, y: 5), radius: 2, isLarge: false, isSweep: true)
            path.addLine(to: CGPoint(x: 9, y: 5))
            path.addLine(to: CGPoint(x: 11, y: 7))
            path.addLine(to: CGPoint(x: 19, y: 7))
            path.addArc(to: CGPoint(x: 21, y: 9), radius: 2, isLarge: false, isSweep: true)
            path.addLine(to: CGPoint(x: 21, y: 18))
            path.addArc(to: CGPoint(x: 19, y: 20), radius: 2, isLarge: false, isSweep: true)
            path.addLine(to: CGPoint(x: 5, y: 20))
            path.addArc(to: CGPoint(x: 3, y: 18), radius: 2, isLarge: false, isSweep: true)
            path.closeSubpath()
        case .info:
            path.addEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))
            path.addLines([CGPoint(x: 12, y: 11), CGPoint(x: 12, y: 16)])
            path.addLines([CGPoint(x: 12, y: 8), CGPoint(x: 12.01, y: 8)])
        case .trash:
            path.addLines([CGPoint(x: 4, y: 7), CGPoint(x: 20, y: 7)])
            path.addLines([CGPoint(x: 10, y: 11), CGPoint(x: 10, y: 17)])
            path.addLines([CGPoint(x: 14, y: 11), CGPoint(x: 14, y: 17)])
            path.addLines([CGPoint(x: 6, y: 7), CGPoint(x: 7, y: 20), CGPoint(x: 17, y: 20), CGPoint(x: 18, y: 7)])
            path.addLines([CGPoint(x: 9, y: 7), CGPoint(x: 9, y: 4), CGPoint(x: 15, y: 4), CGPoint(x: 15, y: 7)])
        case .sort:
            path.addLines([CGPoint(x: 7, y: 4), CGPoint(x: 7, y: 20)])
            path.addLines([CGPoint(x: 4, y: 17), CGPoint(x: 7, y: 20), CGPoint(x: 10, y: 17)])
            path.addLines([CGPoint(x: 17, y: 20), CGPoint(x: 17, y: 4)])
            path.addLines([CGPoint(x: 14, y: 7), CGPoint(x: 17, y: 4), CGPoint(x: 20, y: 7)])
        }
        let scale = min(rect.width, rect.height) / Self.grid
        return path.applying(
            CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: scale, y: scale))
    }

    var isFilled: Bool { self == .more }
}

extension Icon {
    private static let menuImageSize: CGFloat = 20
    private static let menuImageStroke: CGFloat = 2

    public var menuImage: Image {
        let rect = CGRect(x: 0, y: 0, width: Self.menuImageSize, height: Self.menuImageSize)
        let image = UIGraphicsImageRenderer(bounds: rect).image { renderer in
            let context = renderer.cgContext
            context.addPath(path(in: rect).cgPath)
            if isFilled {
                context.fillPath()
            } else {
                context.setLineWidth(Self.menuImageStroke * Self.menuImageSize / Self.grid)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.strokePath()
            }
        }
        return Image(uiImage: image.withRenderingMode(.alwaysTemplate))
    }
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

extension Path {
    fileprivate mutating func addArc(to end: CGPoint, radius: CGFloat, isLarge: Bool, isSweep: Bool) {
        guard let start = currentPoint else { return }
        let half = CGPoint(x: (start.x - end.x) / 2, y: (start.y - end.y) / 2)
        let squared = half.x * half.x + half.y * half.y
        let sign: CGFloat = isLarge == isSweep ? -1 : 1
        let factor = sign * (max(radius * radius - squared, 0) / squared).squareRoot()
        let center = CGPoint(x: factor * half.y + (start.x + end.x) / 2, y: -factor * half.x + (start.y + end.y) / 2)
        addArc(
            center: center, radius: radius, startAngle: .radians(atan2(start.y - center.y, start.x - center.x)),
            endAngle: .radians(atan2(end.y - center.y, end.x - center.x)), clockwise: !isSweep)
    }
}
