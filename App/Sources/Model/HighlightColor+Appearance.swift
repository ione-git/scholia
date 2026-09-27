import DesignSystem
import Foundation

extension HighlightColor {
    var fill: ColorToken {
        switch self {
        case .yellow: .highlightYellow
        case .green: .highlightGreen
        case .blue: .highlightBlue
        case .pink: .highlightPink
        case .purple: .highlightPurple
        }
    }

    var solid: ColorToken {
        switch self {
        case .yellow: .highlightYellowSolid
        case .green: .highlightGreenSolid
        case .blue: .highlightBlueSolid
        case .pink: .highlightPinkSolid
        case .purple: .highlightPurpleSolid
        }
    }

    var name: LocalizedStringResource {
        switch self {
        case .yellow:
            LocalizedStringResource(
                "readerHighlights.color.yellow", defaultValue: "Yellow",
                comment: "Highlights list row, VoiceOver value: the highlight's colour")
        case .green:
            LocalizedStringResource(
                "readerHighlights.color.green", defaultValue: "Green",
                comment: "Highlights list row, VoiceOver value: the highlight's colour")
        case .blue:
            LocalizedStringResource(
                "readerHighlights.color.blue", defaultValue: "Blue",
                comment: "Highlights list row, VoiceOver value: the highlight's colour")
        case .pink:
            LocalizedStringResource(
                "readerHighlights.color.pink", defaultValue: "Pink",
                comment: "Highlights list row, VoiceOver value: the highlight's colour")
        case .purple:
            LocalizedStringResource(
                "readerHighlights.color.purple", defaultValue: "Purple",
                comment: "Highlights list row, VoiceOver value: the highlight's colour")
        }
    }
}
