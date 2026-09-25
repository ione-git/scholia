import SwiftUI
import UIKit

public struct TextStyle: Identifiable, Sendable {
    public enum Family: Sendable {
        case serif
        case sans
    }

    public let name: String
    public let family: Family
    public let size: CGFloat
    public let lineHeight: CGFloat
    public let weight: Int
    public let tracking: CGFloat
    public let isUppercase: Bool

    public var id: String { name }

    public var uiFont: UIFont {
        switch family {
        case .serif:
            UIFont(
                descriptor: UIFontDescriptor(fontAttributes: [
                    .name: DesignSystem.serifFontName,
                    UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [
                        Self.weightAxis: weight
                    ],
                ]),
                size: size
            )
        case .sans:
            UIFont.systemFont(ofSize: size, weight: systemWeight)
        }
    }

    public var font: Font { Font(uiFont as CTFont) }

    private static let weightAxis = "wght".utf8.reduce(0) { $0 << 8 | Int($1) }

    private var systemWeight: UIFont.Weight {
        switch weight {
        case 100: .ultraLight
        case 200: .thin
        case 300: .light
        case 500: .medium
        case 600: .semibold
        case 700: .bold
        case 800: .heavy
        case 900: .black
        default: .regular
        }
    }
}

extension View {
    public func textStyle(_ style: TextStyle) -> some View {
        font(style.font)
            .tracking(style.tracking)
            .lineHeight(.exact(points: style.lineHeight))
            .textCase(style.isUppercase ? .uppercase : nil)
    }
}
