import SwiftUI

extension Text {
    public init(verbatim content: String, spokenIn locale: Locale) {
        var string = AttributedString(content)
        string.languageIdentifier = locale.identifier
        self.init(string)
    }
}
