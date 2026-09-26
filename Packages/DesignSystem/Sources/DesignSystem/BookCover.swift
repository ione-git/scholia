import SwiftUI

public struct BookCover: View {
    public enum Size: CaseIterable, Sendable {
        case thumbnail
        case row
        case grid
        case library
        case hero
        case heroLarge

        public var width: CGFloat { metrics.width }
        public var height: CGFloat { metrics.height }

        var metrics: Metrics {
            switch self {
            case .thumbnail:
                Metrics(width: 40, height: 60, radius: .radiusXs, lettering: nil)
            case .row:
                Metrics(
                    width: 80, height: 120, radius: .radiusSm,
                    lettering: Lettering(vertical: 10, horizontal: 8, title: 12, author: 8))
            case .grid:
                Metrics(
                    width: 100, height: 150, radius: .radiusSm,
                    lettering: Lettering(vertical: 12, horizontal: 10, title: 14, author: 9))
            case .library:
                Metrics(
                    width: 107, height: 152, radius: .radiusSm,
                    lettering: Lettering(vertical: 12, horizontal: 10, title: 13, author: 8))
            case .hero:
                Metrics(
                    width: 160, height: 240, radius: Metrics.heroRadius,
                    lettering: Lettering(vertical: 20, horizontal: 16, title: 22, author: 10))
            case .heroLarge:
                Metrics(
                    width: 180, height: 270, radius: Metrics.heroRadius,
                    lettering: Lettering(vertical: 22, horizontal: 18, title: 24, author: 10))
            }
        }

        var isHero: Bool { self == .hero || self == .heroLarge }
    }

    struct Metrics {
        static let heroRadius: CGFloat = 8

        let width: CGFloat
        let height: CGFloat
        let radius: CGFloat
        let lettering: Lettering?
    }

    struct Lettering {
        let vertical: CGFloat
        let horizontal: CGFloat
        let title: CGFloat
        let author: CGFloat
    }

    private static let authorOpacity = 0.85

    let title: String
    let author: String?
    let color: Color
    let image: Image?
    let size: Size
    let isFinished: Bool
    let finishedValue: Text

    public init(
        title: String, author: String?, color: Color, image: Image?, size: Size, isFinished: Bool,
        finishedValue: Text
    ) {
        self.title = title
        self.author = author
        self.color = color
        self.image = image
        self.size = size
        self.isFinished = isFinished
        self.finishedValue = finishedValue
    }

    public var body: some View {
        let metrics = size.metrics
        let shape = RoundedRectangle(cornerRadius: metrics.radius)
        ZStack {
            color
            if let image {
                image.resizable().scaledToFill()
            } else if let lettering = metrics.lettering {
                generatedText(lettering)
            }
        }
        .frame(width: metrics.width, height: metrics.height)
        .clipShape(shape)
        .shadow(shadow, in: shape)
        .contentShape([.interaction, .accessibility, .contextMenuPreview], shape)
        .overlay(alignment: .topTrailing) {
            if isFinished {
                FinishedBadge()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(finishedValue, isEnabled: isFinished)
    }

    private func generatedText(_ lettering: Lettering) -> some View {
        let width = size.width - 2 * lettering.horizontal
        return VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .textStyle(TextStyle.coverTitle.scaled(to: lettering.title).fitting(title, in: width))
            Spacer(minLength: 0)
            if let author {
                Text(author)
                    .textStyle(
                        TextStyle.labelCaps.scaled(to: lettering.author).weighted(TextStyle.caption.weight)
                            .fitting(author, in: width)
                    )
                    .opacity(Self.authorOpacity)
            }
        }
        .foregroundStyle(ColorToken.surface.light)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical, lettering.vertical)
        .padding(.horizontal, lettering.horizontal)
    }

    private var shadow: ShadowToken {
        guard size.isHero, let glow = ShadowToken.coverHero.layers.first else { return .cover }
        let opacity = Double(glow.color.resolve(in: EnvironmentValues()).opacity)
        let tinted = ShadowToken.Layer(
            x: glow.x, y: glow.y, blur: glow.blur, spread: glow.spread, color: color.opacity(opacity),
            isInset: glow.isInset)
        return ShadowToken(
            name: ShadowToken.coverHero.name, layers: [tinted] + ShadowToken.coverHero.layers.dropFirst())
    }
}

extension BookCover {
    private static let generatedColors: [UInt32] = [
        0x2E3A4F, 0x35545E, 0x8A6D2F, 0x9A6B4E, 0x6B2F3A, 0x7A5A1E, 0x4A4A48, 0x2F5D50, 0x1F3B57,
    ]

    public static func generatedColor(for title: String) -> Color {
        let hash = title.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & Int.max }
        return Color(uiColor: UIColor(rgb: generatedColors[hash % generatedColors.count], opacity: 1))
    }
}

extension BookCover {
    public func selectable(isSelected: Bool) -> some View {
        modifier(CoverSelection(isSelected: isSelected, radius: size.metrics.radius))
    }
}

private struct CoverSelection: ViewModifier {
    private static let ringWidth: CGFloat = 2
    private static let ringOffset: CGFloat = 3
    private static let checkboxInset: CGFloat = 6

    let isSelected: Bool
    let radius: CGFloat

    func body(content: Content) -> some View {
        let outset = Self.ringOffset + Self.ringWidth
        content
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: radius + outset)
                        .strokeBorder(.accent, lineWidth: Self.ringWidth)
                        .padding(-outset)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                CoverCheckbox(isChecked: isSelected)
                    .padding(Self.checkboxInset)
            }
    }
}

private struct CoverCheckbox: View {
    private static let diameter: CGFloat = 24
    private static let ring: CGFloat = 2
    private static let border: CGFloat = 1.5
    private static let iconSize: CGFloat = 14
    private static let iconStroke: CGFloat = 3

    let isChecked: Bool

    var body: some View {
        Group {
            if isChecked {
                IconView(icon: .check, size: Self.iconSize, stroke: Self.iconStroke)
                    .foregroundStyle(.onAccent)
                    .frame(width: Self.diameter, height: Self.diameter)
                    .background(.accent, in: .circle)
                    .background(.onAccent, in: Circle().inset(by: -Self.ring))
            } else {
                Circle()
                    .fill(ColorToken.scrim.light)
                    .strokeBorder(ColorToken.glassBorder.light, lineWidth: Self.border)
                    .frame(width: Self.diameter, height: Self.diameter)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct FinishedBadge: View {
    private static let diameter: CGFloat = 26
    private static let ring: CGFloat = 2
    private static let offset: CGFloat = 6
    private static let iconSize: CGFloat = 14
    private static let iconStroke: CGFloat = 3

    var body: some View {
        IconView(icon: .check, size: Self.iconSize, stroke: Self.iconStroke)
            .foregroundStyle(.onInk)
            .frame(width: Self.diameter, height: Self.diameter)
            .background(.ink, in: .circle)
            .padding(Self.ring)
            .background(.surface, in: .circle)
            .offset(x: Self.offset + Self.ring, y: -Self.offset - Self.ring)
    }
}

public struct ProgressBar: View {
    private static let height: CGFloat = 3

    let value: Double

    public init(value: Double) {
        self.value = value
    }

    public var body: some View {
        Capsule()
            .fill(.track)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(.accent)
                        .frame(width: proxy.size.width * value)
                }
            }
            .frame(height: Self.height)
            .accessibilityElement()
            .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
    }
}
