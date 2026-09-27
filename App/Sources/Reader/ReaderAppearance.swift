import DesignSystem
import ReaderEngine
import SwiftUI

extension ReaderStyle {
    static var book: ReaderStyle {
        ReaderStyle(
            font: ReaderTypeface(
                family: DesignSystem.serifFamilyName,
                regular: DesignSystem.serifFontURL,
                italic: DesignSystem.serifItalicFontURL
            ),
            fontSize: TextStyle.readingBody.size,
            lineHeight: TextStyle.readingBody.lineHeight,
            paragraphIndent: TextStyle.readingBody.textIndent,
            sideMargin: .space7,
            topMargin: .navTop + .controlH + .space8,
            minimumBottomMargin: .controlH + .space10,
            highlightRadius: .radiusXs
        )
    }
}

extension ReaderTheme {
    var isDark: Bool { self == .night || self == .black }

    var colors: ReaderColors {
        ReaderColors(
            page: UIColor(page),
            text: UIColor(text),
            selection: UIColor(isDark ? ColorToken.selectionHandle.dark : ColorToken.selectionHandle.light),
            wordTap: UIColor(isDark ? ColorToken.wordTap.dark : ColorToken.wordTap.light)
        )
    }

    func highlightColor(_ color: HighlightColor) -> UIColor {
        let token: ColorToken =
            switch color {
            case .yellow: .highlightYellow
            case .green: .highlightGreen
            case .blue: .highlightBlue
            case .pink: .highlightPink
            case .purple: .highlightPurple
            }
        return UIColor(isDark ? token.dark : token.light)
    }

    func shown(in colorScheme: ColorScheme) -> ReaderTheme {
        colorScheme == .dark && !isDark ? .night : self
    }
}
