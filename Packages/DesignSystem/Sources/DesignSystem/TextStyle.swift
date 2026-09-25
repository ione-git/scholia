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

    func scaled(to newSize: CGFloat) -> TextStyle {
        let ratio = newSize / size
        return TextStyle(
            name: name, family: family, size: newSize, lineHeight: lineHeight * ratio, weight: weight,
            tracking: tracking * ratio, isUppercase: isUppercase)
    }

    func fitting(_ text: String, in width: CGFloat) -> TextStyle {
        let shown = (isUppercase ? text.uppercased() : text) as NSString
        let units = CFStringTokenizerCreate(
            nil, shown, CFRange(location: 0, length: shown.length), kCFStringTokenizerUnitLineBreak, nil)
        var widest: CGFloat = 0
        while !CFStringTokenizerAdvanceToNextToken(units).isEmpty {
            let range = CFStringTokenizerGetCurrentTokenRange(units)
            let unit = shown.substring(with: NSRange(location: range.location, length: range.length))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            widest = max(widest, unit.size(withAttributes: [.font: uiFont, .kern: tracking]).width)
        }
        guard widest > width else { return self }
        return scaled(to: (size * width / widest).rounded(.down))
    }

    public func weighted(_ newWeight: Int) -> TextStyle {
        TextStyle(
            name: name, family: family, size: size, lineHeight: lineHeight, weight: newWeight, tracking: tracking,
            isUppercase: isUppercase)
    }

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
