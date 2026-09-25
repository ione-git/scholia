import SwiftUI

public enum ReaderTheme: String, CaseIterable, Codable, Sendable {
    case paper
    case sepia
    case night
    case black

    public var page: Color {
        switch self {
        case .paper: ColorToken.surfacePaper.light
        case .sepia: ColorToken.surfaceSepia.color
        case .night: ColorToken.surfacePaper.dark
        case .black: ColorToken.surfaceBlack.color
        }
    }

    public var text: Color {
        switch self {
        case .paper: ColorToken.ink.light
        case .sepia: ColorToken.sepiaText.color
        case .night, .black: ColorToken.nightText.color
        }
    }
}
