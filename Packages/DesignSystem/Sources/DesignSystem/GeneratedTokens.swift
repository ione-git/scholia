import SwiftUI
import UIKit

extension ColorToken {
    public static let surface = ColorToken(
        name: "surface",
        light: UIColor(rgb: 0xf4f2ed, opacity: 1),
        dark: UIColor(rgb: 0x151412, opacity: 1)
    )
    public static let surfacePaper = ColorToken(
        name: "surface-paper",
        light: UIColor(rgb: 0xf7f5f0, opacity: 1),
        dark: UIColor(rgb: 0x1a1917, opacity: 1)
    )
    public static let surfaceSepia = ColorToken(
        name: "surface-sepia",
        light: UIColor(rgb: 0xefe3cb, opacity: 1),
        dark: UIColor(rgb: 0xefe3cb, opacity: 1)
    )
    public static let surfaceBlack = ColorToken(
        name: "surface-black",
        light: UIColor(rgb: 0x000000, opacity: 1),
        dark: UIColor(rgb: 0x000000, opacity: 1)
    )
    public static let surfaceCard = ColorToken(
        name: "surface-card",
        light: UIColor(rgb: 0xffffff, opacity: 1),
        dark: UIColor(rgb: 0x26241f, opacity: 1)
    )
    public static let surfaceGlass = ColorToken(
        name: "surface-glass",
        light: UIColor(rgb: 0xffffff, opacity: 0.7),
        dark: UIColor(rgb: 0x282622, opacity: 0.72)
    )
    public static let surfaceGlassStrong = ColorToken(
        name: "surface-glass-strong",
        light: UIColor(rgb: 0xffffff, opacity: 0.88),
        dark: UIColor(rgb: 0x282622, opacity: 0.88)
    )
    public static let glassBorder = ColorToken(
        name: "glass-border",
        light: UIColor(rgb: 0xffffff, opacity: 0.85),
        dark: UIColor(rgb: 0xffffff, opacity: 0.12)
    )
    public static let ink = ColorToken(
        name: "ink",
        light: UIColor(rgb: 0x1d1b17, opacity: 1),
        dark: UIColor(rgb: 0xedeae3, opacity: 1)
    )
    public static let inkMuted = ColorToken(
        name: "ink-muted",
        light: UIColor(rgb: 0x6c675e, opacity: 1),
        dark: UIColor(rgb: 0x9b968c, opacity: 1)
    )
    public static let inkFaint = ColorToken(
        name: "ink-faint",
        light: UIColor(rgb: 0xb9b4a9, opacity: 1),
        dark: UIColor(rgb: 0x5e5a52, opacity: 1)
    )
    public static let onInk = ColorToken(
        name: "on-ink",
        light: UIColor(rgb: 0xffffff, opacity: 1),
        dark: UIColor(rgb: 0x151412, opacity: 1)
    )
    public static let accent = ColorToken(
        name: "accent",
        light: UIColor(rgb: 0xb0471f, opacity: 1),
        dark: UIColor(rgb: 0xd8683a, opacity: 1)
    )
    public static let accentTint = ColorToken(
        name: "accent-tint",
        light: UIColor(rgb: 0xb0471f, opacity: 0.12),
        dark: UIColor(rgb: 0xd8683a, opacity: 0.18)
    )
    public static let onAccent = ColorToken(
        name: "on-accent",
        light: UIColor(rgb: 0xffffff, opacity: 1),
        dark: UIColor(rgb: 0xffffff, opacity: 1)
    )
    public static let track = ColorToken(
        name: "track",
        light: UIColor(rgb: 0xe3dfd6, opacity: 1),
        dark: UIColor(rgb: 0x33312d, opacity: 1)
    )
    public static let hairline = ColorToken(
        name: "hairline",
        light: UIColor(rgb: 0x000000, opacity: 0.08),
        dark: UIColor(rgb: 0xffffff, opacity: 0.1)
    )
    public static let controlFill = ColorToken(
        name: "control-fill",
        light: UIColor(rgb: 0x000000, opacity: 0.06),
        dark: UIColor(rgb: 0xffffff, opacity: 0.08)
    )
    public static let controlBorder = ColorToken(
        name: "control-border",
        light: UIColor(rgb: 0x000000, opacity: 0.12),
        dark: UIColor(rgb: 0xffffff, opacity: 0.14)
    )
    public static let wordTap = ColorToken(
        name: "word-tap",
        light: UIColor(rgb: 0xffc440, opacity: 0.5),
        dark: UIColor(rgb: 0xffc440, opacity: 0.35)
    )
    public static let selection = ColorToken(
        name: "selection",
        light: UIColor(rgb: 0x0a66c2, opacity: 0.22),
        dark: UIColor(rgb: 0x5aa0ff, opacity: 0.3)
    )
    public static let selectionHandle = ColorToken(
        name: "selection-handle",
        light: UIColor(rgb: 0x0a66c2, opacity: 1),
        dark: UIColor(rgb: 0x5aa0ff, opacity: 1)
    )
    public static let highlightYellow = ColorToken(
        name: "highlight-yellow",
        light: UIColor(rgb: 0xfacc3c, opacity: 0.42),
        dark: UIColor(rgb: 0xfacc3c, opacity: 0.35)
    )
    public static let highlightGreen = ColorToken(
        name: "highlight-green",
        light: UIColor(rgb: 0x7bc67e, opacity: 0.4),
        dark: UIColor(rgb: 0x7bc67e, opacity: 0.35)
    )
    public static let highlightBlue = ColorToken(
        name: "highlight-blue",
        light: UIColor(rgb: 0x6fa8f5, opacity: 0.4),
        dark: UIColor(rgb: 0x6fa8f5, opacity: 0.35)
    )
    public static let highlightPink = ColorToken(
        name: "highlight-pink",
        light: UIColor(rgb: 0xf28bb0, opacity: 0.4),
        dark: UIColor(rgb: 0xf28bb0, opacity: 0.35)
    )
    public static let highlightPurple = ColorToken(
        name: "highlight-purple",
        light: UIColor(rgb: 0xb48cf2, opacity: 0.4),
        dark: UIColor(rgb: 0xb48cf2, opacity: 0.35)
    )
    public static let highlightYellowSolid = ColorToken(
        name: "highlight-yellow-solid",
        light: UIColor(rgb: 0xf2c94c, opacity: 1),
        dark: UIColor(rgb: 0xf2c94c, opacity: 1)
    )
    public static let highlightGreenSolid = ColorToken(
        name: "highlight-green-solid",
        light: UIColor(rgb: 0x7bc67e, opacity: 1),
        dark: UIColor(rgb: 0x7bc67e, opacity: 1)
    )
    public static let highlightBlueSolid = ColorToken(
        name: "highlight-blue-solid",
        light: UIColor(rgb: 0x6fa8f5, opacity: 1),
        dark: UIColor(rgb: 0x6fa8f5, opacity: 1)
    )
    public static let highlightPinkSolid = ColorToken(
        name: "highlight-pink-solid",
        light: UIColor(rgb: 0xf28bb0, opacity: 1),
        dark: UIColor(rgb: 0xf28bb0, opacity: 1)
    )
    public static let highlightPurpleSolid = ColorToken(
        name: "highlight-purple-solid",
        light: UIColor(rgb: 0xb48cf2, opacity: 1),
        dark: UIColor(rgb: 0xb48cf2, opacity: 1)
    )
    public static let danger = ColorToken(
        name: "danger",
        light: UIColor(rgb: 0xb3261e, opacity: 1),
        dark: UIColor(rgb: 0xe5675f, opacity: 1)
    )
    public static let scrim = ColorToken(
        name: "scrim",
        light: UIColor(rgb: 0x1d1b17, opacity: 0.32),
        dark: UIColor(rgb: 0x000000, opacity: 0.5)
    )
    public static let nightText = ColorToken(
        name: "night-text",
        light: UIColor(rgb: 0xe6e2d9, opacity: 1),
        dark: UIColor(rgb: 0xe6e2d9, opacity: 1)
    )
    public static let sepiaText = ColorToken(
        name: "sepia-text",
        light: UIColor(rgb: 0x4a3a22, opacity: 1),
        dark: UIColor(rgb: 0x4a3a22, opacity: 1)
    )
    public static let all: [ColorToken] = [
        .surface,
        .surfacePaper,
        .surfaceSepia,
        .surfaceBlack,
        .surfaceCard,
        .surfaceGlass,
        .surfaceGlassStrong,
        .glassBorder,
        .ink,
        .inkMuted,
        .inkFaint,
        .onInk,
        .accent,
        .accentTint,
        .onAccent,
        .track,
        .hairline,
        .controlFill,
        .controlBorder,
        .wordTap,
        .selection,
        .selectionHandle,
        .highlightYellow,
        .highlightGreen,
        .highlightBlue,
        .highlightPink,
        .highlightPurple,
        .highlightYellowSolid,
        .highlightGreenSolid,
        .highlightBlueSolid,
        .highlightPinkSolid,
        .highlightPurpleSolid,
        .danger,
        .scrim,
        .nightText,
        .sepiaText,
    ]
}

extension ShapeStyle where Self == Color {
    public static var surface: Color { ColorToken.surface.color }
    public static var surfacePaper: Color { ColorToken.surfacePaper.color }
    public static var surfaceSepia: Color { ColorToken.surfaceSepia.color }
    public static var surfaceBlack: Color { ColorToken.surfaceBlack.color }
    public static var surfaceCard: Color { ColorToken.surfaceCard.color }
    public static var surfaceGlass: Color { ColorToken.surfaceGlass.color }
    public static var surfaceGlassStrong: Color { ColorToken.surfaceGlassStrong.color }
    public static var glassBorder: Color { ColorToken.glassBorder.color }
    public static var ink: Color { ColorToken.ink.color }
    public static var inkMuted: Color { ColorToken.inkMuted.color }
    public static var inkFaint: Color { ColorToken.inkFaint.color }
    public static var onInk: Color { ColorToken.onInk.color }
    public static var accent: Color { ColorToken.accent.color }
    public static var accentTint: Color { ColorToken.accentTint.color }
    public static var onAccent: Color { ColorToken.onAccent.color }
    public static var track: Color { ColorToken.track.color }
    public static var hairline: Color { ColorToken.hairline.color }
    public static var controlFill: Color { ColorToken.controlFill.color }
    public static var controlBorder: Color { ColorToken.controlBorder.color }
    public static var wordTap: Color { ColorToken.wordTap.color }
    public static var selection: Color { ColorToken.selection.color }
    public static var selectionHandle: Color { ColorToken.selectionHandle.color }
    public static var highlightYellow: Color { ColorToken.highlightYellow.color }
    public static var highlightGreen: Color { ColorToken.highlightGreen.color }
    public static var highlightBlue: Color { ColorToken.highlightBlue.color }
    public static var highlightPink: Color { ColorToken.highlightPink.color }
    public static var highlightPurple: Color { ColorToken.highlightPurple.color }
    public static var highlightYellowSolid: Color { ColorToken.highlightYellowSolid.color }
    public static var highlightGreenSolid: Color { ColorToken.highlightGreenSolid.color }
    public static var highlightBlueSolid: Color { ColorToken.highlightBlueSolid.color }
    public static var highlightPinkSolid: Color { ColorToken.highlightPinkSolid.color }
    public static var highlightPurpleSolid: Color { ColorToken.highlightPurpleSolid.color }
    public static var danger: Color { ColorToken.danger.color }
    public static var scrim: Color { ColorToken.scrim.color }
    public static var nightText: Color { ColorToken.nightText.color }
    public static var sepiaText: Color { ColorToken.sepiaText.color }
}

extension TextStyle {
    public static let wordmark = TextStyle(
        name: "wordmark",
        family: .serif,
        size: 30,
        lineHeight: 30,
        weight: 600,
        tracking: -0.3,
        textIndent: 0,
        isUppercase: false
    )
    public static let titleBook = TextStyle(
        name: "title-book",
        family: .serif,
        size: 26,
        lineHeight: 29.9,
        weight: 500,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let titleCard = TextStyle(
        name: "title-card",
        family: .serif,
        size: 22,
        lineHeight: 25.3,
        weight: 500,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let listSerif = TextStyle(
        name: "list-serif",
        family: .serif,
        size: 17,
        lineHeight: 22.1,
        weight: 400,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let coverTitle = TextStyle(
        name: "cover-title",
        family: .serif,
        size: 14,
        lineHeight: 16.8,
        weight: 500,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let readingBody = TextStyle(
        name: "reading-body",
        family: .serif,
        size: 17,
        lineHeight: 27,
        weight: 400,
        tracking: 0,
        textIndent: 25.5,
        isUppercase: false
    )
    public static let readingQuote = TextStyle(
        name: "reading-quote",
        family: .serif,
        size: 16,
        lineHeight: 24,
        weight: 400,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let headline = TextStyle(
        name: "headline",
        family: .sans,
        size: 26,
        lineHeight: 28.6,
        weight: 600,
        tracking: -0.26,
        textIndent: 0,
        isUppercase: false
    )
    public static let translation = TextStyle(
        name: "translation",
        family: .sans,
        size: 20,
        lineHeight: 24,
        weight: 500,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let section = TextStyle(
        name: "section",
        family: .sans,
        size: 20,
        lineHeight: 24,
        weight: 600,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let title3 = TextStyle(
        name: "title-3",
        family: .sans,
        size: 17,
        lineHeight: 21.25,
        weight: 600,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let body = TextStyle(
        name: "body",
        family: .sans,
        size: 16,
        lineHeight: 20.8,
        weight: 400,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let callout = TextStyle(
        name: "callout",
        family: .sans,
        size: 15,
        lineHeight: 20.25,
        weight: 500,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let subhead = TextStyle(
        name: "subhead",
        family: .sans,
        size: 14,
        lineHeight: 18.2,
        weight: 500,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let footnote = TextStyle(
        name: "footnote",
        family: .sans,
        size: 13,
        lineHeight: 17.55,
        weight: 400,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let caption = TextStyle(
        name: "caption",
        family: .sans,
        size: 12,
        lineHeight: 15.6,
        weight: 400,
        tracking: 0,
        textIndent: 0,
        isUppercase: false
    )
    public static let labelCaps = TextStyle(
        name: "label-caps",
        family: .sans,
        size: 11,
        lineHeight: 13.2,
        weight: 600,
        tracking: 0.88,
        textIndent: 0,
        isUppercase: true
    )
    public static let all: [TextStyle] = [
        .wordmark,
        .titleBook,
        .titleCard,
        .listSerif,
        .coverTitle,
        .readingBody,
        .readingQuote,
        .headline,
        .translation,
        .section,
        .title3,
        .body,
        .callout,
        .subhead,
        .footnote,
        .caption,
        .labelCaps,
    ]
}

extension CGFloat {
    public static let space1: CGFloat = 4
    public static let space2: CGFloat = 8
    public static let space3: CGFloat = 12
    public static let space4: CGFloat = 16
    public static let space5: CGFloat = 20
    public static let space6: CGFloat = 24
    public static let space7: CGFloat = 28
    public static let space8: CGFloat = 32
    public static let space10: CGFloat = 40
    public static let controlH: CGFloat = 44
    public static let navTop: CGFloat = 62
    public static let radiusXs: CGFloat = 4
    public static let radiusSm: CGFloat = 6
    public static let radiusMd: CGFloat = 12
    public static let radiusLg: CGFloat = 18
    public static let radiusXl: CGFloat = 22
    public static let radius2xl: CGFloat = 24
    public static let radiusSheet: CGFloat = 36
    public static let radiusPill: CGFloat = 999
    public static let glassBlur: CGFloat = 20
    public static let glassSaturate: CGFloat = 1.4
    public static let hairlineW: CGFloat = 0.5
}

extension NumberToken {
    public static let spacing: [NumberToken] = [
        NumberToken(name: "space-1", value: .space1),
        NumberToken(name: "space-2", value: .space2),
        NumberToken(name: "space-3", value: .space3),
        NumberToken(name: "space-4", value: .space4),
        NumberToken(name: "space-5", value: .space5),
        NumberToken(name: "space-6", value: .space6),
        NumberToken(name: "space-7", value: .space7),
        NumberToken(name: "space-8", value: .space8),
        NumberToken(name: "space-10", value: .space10),
        NumberToken(name: "control-h", value: .controlH),
        NumberToken(name: "nav-top", value: .navTop),
    ]
    public static let radius: [NumberToken] = [
        NumberToken(name: "radius-xs", value: .radiusXs),
        NumberToken(name: "radius-sm", value: .radiusSm),
        NumberToken(name: "radius-md", value: .radiusMd),
        NumberToken(name: "radius-lg", value: .radiusLg),
        NumberToken(name: "radius-xl", value: .radiusXl),
        NumberToken(name: "radius-2xl", value: .radius2xl),
        NumberToken(name: "radius-sheet", value: .radiusSheet),
        NumberToken(name: "radius-pill", value: .radiusPill),
    ]
    public static let effects: [NumberToken] = [
        NumberToken(name: "glass-blur", value: .glassBlur),
        NumberToken(name: "glass-saturate", value: .glassSaturate),
        NumberToken(name: "hairline-w", value: .hairlineW),
    ]
}

extension ShadowToken {
    public static let card = ShadowToken(
        name: "shadow-card",
        layers: [
            .drop(x: 0, y: 1, blur: 2, spread: 0, color: UIColor(rgb: 0x000000, opacity: 0.04)),
            .drop(x: 0, y: 6, blur: 20, spread: 0, color: UIColor(rgb: 0x000000, opacity: 0.06)),
        ]
    )
    public static let glass = ShadowToken(
        name: "shadow-glass",
        layers: [
            .drop(x: 0, y: 1, blur: 4, spread: 0, color: UIColor(rgb: 0x000000, opacity: 0.06)),
            .drop(x: 0, y: 0, blur: 0, spread: 0.5, color: UIColor(rgb: 0x000000, opacity: 0.05)),
        ]
    )
    public static let popover = ShadowToken(
        name: "shadow-popover",
        layers: [
            .drop(x: 0, y: 12, blur: 32, spread: 0, color: UIColor(rgb: 0x000000, opacity: 0.16)),
            .drop(x: 0, y: 0, blur: 0, spread: 0.5, color: UIColor(rgb: 0x000000, opacity: 0.06)),
        ]
    )
    public static let sheet = ShadowToken(
        name: "shadow-sheet",
        layers: [
            .drop(x: 0, y: -2, blur: 30, spread: 0, color: UIColor(rgb: 0x000000, opacity: 0.12)),
            .drop(x: 0, y: 0, blur: 0, spread: 0.5, color: UIColor(rgb: 0x000000, opacity: 0.05)),
        ]
    )
    public static let cover = ShadowToken(
        name: "shadow-cover",
        layers: [
            .drop(x: 0, y: 2, blur: 6, spread: 0, color: UIColor(rgb: 0x000000, opacity: 0.16)),
            .inset(x: 3, y: 0, blur: 0, spread: 0, color: UIColor(rgb: 0xffffff, opacity: 0.16)),
        ]
    )
    public static let coverHero = ShadowToken(
        name: "shadow-cover-hero",
        layers: [
            .drop(x: 0, y: 20, blur: 44, spread: 0, color: UIColor(rgb: 0x2e3a4f, opacity: 0.35)),
            .drop(x: 0, y: 2, blur: 6, spread: 0, color: UIColor(rgb: 0x000000, opacity: 0.18)),
            .inset(x: 4, y: 0, blur: 0, spread: 0, color: UIColor(rgb: 0xffffff, opacity: 0.16)),
        ]
    )
    public static let all: [ShadowToken] = [
        .card,
        .glass,
        .popover,
        .sheet,
        .cover,
        .coverHero,
    ]
}
