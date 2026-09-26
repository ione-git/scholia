import DesignSystem
import ReaderEngine
import SwiftUI

extension ReaderAppearance {
    init(settings: Settings, theme: ReaderTheme) {
        self.init(
            style: ReaderStyle(
                font: settings.readerFont, sizeStep: settings.textSizeStep, spacing: settings.lineSpacing),
            colors: theme.colors,
            pageTurn: settings.pageTurn.engine
        )
    }
}

extension ReaderStyle {
    static let sizeSteps = 1...ReadingSize.steps.count

    init(font: ReaderFont, sizeStep: Int, spacing: LineSpacing) {
        let size = ReadingSize.steps[min(max(sizeStep, Self.sizeSteps.lowerBound), Self.sizeSteps.upperBound) - 1]
        let body = TextStyle.readingBody
        self.init(
            font: font.typeface,
            fontSize: size.fontSize,
            lineHeight: spacing.lineHeight(in: size),
            paragraphIndent: size.fontSize * body.textIndent / body.size,
            sideMargin: .space7,
            topMargin: .navTop + .controlH + .space8,
            minimumBottomMargin: .controlH + .space10,
            highlightRadius: .radiusXs
        )
    }
}

extension LineSpacing {
    fileprivate func lineHeight(in size: ReadingSize) -> CGFloat {
        switch self {
        case .tight: size.tightLineHeight
        case .normal: size.normalLineHeight
        case .loose: size.looseLineHeight
        }
    }
}

extension PageTurn {
    fileprivate var engine: ReaderPageTurn {
        switch self {
        case .slide: .slide
        case .curl: .curl
        case .fade: .fade
        case .scroll: .scroll
        }
    }
}

extension ReaderFont {
    private static let literataChip = chipFont(ReaderFont.literata.typeface.family)
    private static let charterChip = chipFont(ReaderFont.charter.typeface.family)
    private static let georgiaChip = chipFont(ReaderFont.georgia.typeface.family)

    var typeface: ReaderTypeface {
        switch self {
        case .literata:
            .bundled(
                family: DesignSystem.serifFamilyName, regular: DesignSystem.serifFontURL,
                italic: DesignSystem.serifItalicFontURL)
        case .charter: .installed(family: "Charter")
        case .georgia: .installed(family: "Georgia")
        case .system: .installed(family: "-apple-system")
        }
    }

    var title: Text {
        switch self {
        case .literata: Text(verbatim: "Literata")
        case .charter: Text(verbatim: "Charter")
        case .georgia: Text(verbatim: "Georgia")
        case .system:
            Text(
                LocalizedStringResource(
                    "readerSettings.font.system", defaultValue: "System",
                    comment: "Font chip in the reader settings sheet: the system sans-serif typeface"))
        }
    }

    var chipFont: Font {
        switch self {
        case .literata: Self.literataChip
        case .charter: Self.charterChip
        case .georgia: Self.georgiaChip
        case .system: .subheadline
        }
    }

    private static func chipFont(_ family: String) -> Font {
        .custom(family, size: TextStyle.callout.size, relativeTo: .subheadline)
    }
}

extension ReaderTheme {
    var isDark: Bool { self == .night || self == .black }

    var title: LocalizedStringResource {
        switch self {
        case .paper: "Paper"
        case .sepia: "Sepia"
        case .night: "Night"
        case .black: "Black"
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .paper: "Paper theme"
        case .sepia: "Sepia theme"
        case .night: "Night theme"
        case .black: "Black theme"
        }
    }

    var colors: ReaderColors {
        ReaderColors(
            page: UIColor(page),
            text: UIColor(text),
            selection: UIColor(isDark ? ColorToken.selectionHandle.dark : ColorToken.selectionHandle.light)
        )
    }

    var highlightColor: UIColor {
        UIColor(isDark ? ColorToken.highlightYellow.dark : ColorToken.highlightYellow.light)
    }

    func shown(in colorScheme: ColorScheme) -> ReaderTheme {
        colorScheme == .dark && !isDark ? .night : self
    }
}
