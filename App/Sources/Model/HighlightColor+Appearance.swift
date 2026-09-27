import DesignSystem
import SwiftUI

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

    var swatch: Color {
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
        case .yellow: LocalizedStringResource("Yellow", comment: "Highlight colour name, label of its swatch")
        case .green: LocalizedStringResource("Green", comment: "Highlight colour name, label of its swatch")
        case .blue: LocalizedStringResource("Blue", comment: "Highlight colour name, label of its swatch")
        case .pink: LocalizedStringResource("Pink", comment: "Highlight colour name, label of its swatch")
        case .purple: LocalizedStringResource("Purple", comment: "Highlight colour name, label of its swatch")
        }
    }
}
