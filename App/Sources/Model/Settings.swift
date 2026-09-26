import DesignSystem
import SwiftData

nonisolated enum WordTapStyle: String, Codable {
    case bubble
    case minimal
    case card
}

nonisolated enum AppTheme: String, Codable {
    case system
    case light
    case dark
}

nonisolated enum LibrarySort: String, Codable, CaseIterable {
    case recentlyOpened
    case recentlyAdded
    case title
    case author
}

nonisolated enum ReaderFont: String, Codable {
    case literata
    case charter
    case georgia
    case system
}

nonisolated enum LineSpacing: String, Codable {
    case tight
    case normal
    case loose
}

nonisolated enum PageTurn: String, Codable {
    case slide
    case curl
    case fade
    case scroll
}

nonisolated struct TimeOfDay: Codable, Hashable {
    var hour: Int
    var minute: Int
}

@Model
final class Settings {
    var translationLanguage: String
    var wordTapStyle: WordTapStyle
    var dailyGoalMinutes: Int
    var remindsDaily: Bool
    var reminderTime: TimeOfDay
    var appTheme: AppTheme
    var librarySort: LibrarySort
    var readerTheme: ReaderTheme
    var readerFont: ReaderFont
    var textSizeStep: Int
    var lineSpacing: LineSpacing
    var pageTurn: PageTurn
    var locksRotation: Bool
    var highlightColor: HighlightColor

    init(
        translationLanguage: String, wordTapStyle: WordTapStyle, dailyGoalMinutes: Int, remindsDaily: Bool,
        reminderTime: TimeOfDay, appTheme: AppTheme, librarySort: LibrarySort, readerTheme: ReaderTheme,
        readerFont: ReaderFont, textSizeStep: Int, lineSpacing: LineSpacing, pageTurn: PageTurn, locksRotation: Bool,
        highlightColor: HighlightColor
    ) {
        self.translationLanguage = translationLanguage
        self.wordTapStyle = wordTapStyle
        self.dailyGoalMinutes = dailyGoalMinutes
        self.remindsDaily = remindsDaily
        self.reminderTime = reminderTime
        self.appTheme = appTheme
        self.librarySort = librarySort
        self.readerTheme = readerTheme
        self.readerFont = readerFont
        self.textSizeStep = textSizeStep
        self.lineSpacing = lineSpacing
        self.pageTurn = pageTurn
        self.locksRotation = locksRotation
        self.highlightColor = highlightColor
    }

    static func makeDefault() -> Settings {
        Settings(
            translationLanguage: TargetLanguage.device, wordTapStyle: .bubble, dailyGoalMinutes: 20,
            remindsDaily: false, reminderTime: TimeOfDay(hour: 21, minute: 0), appTheme: .system,
            librarySort: .recentlyOpened, readerTheme: .paper, readerFont: .literata, textSizeStep: 3,
            lineSpacing: .normal, pageTurn: .slide, locksRotation: false, highlightColor: .yellow)
    }
}
