import Foundation

nonisolated enum TargetLanguage {
    static let identifiers = [
        "ar", "de", "en", "es", "fr", "hi", "id", "it", "ja", "ko", "nl", "pl", "pt", "ru", "th", "tr", "uk", "vi",
        "zh-Hans", "zh-Hant",
    ]

    static var device: String {
        let device = Locale.Language(identifier: Locale.preferredLanguages.first ?? english)
        return identifiers.first { identifier in
            let language = Locale.Language(identifier: identifier)
            return language.languageCode == device.languageCode && language.script == device.script
        } ?? english
    }

    private static let english = "en"
}
