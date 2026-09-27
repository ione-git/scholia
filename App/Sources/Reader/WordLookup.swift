import ReaderEngine
import SwiftUI

struct WordLookup {
    enum Phase {
        case loading
        case translated(WordTranslation)
        case failed
        case notNeeded
    }

    let word: ReaderWord
    let phase: Phase
}

extension Text {
    static func translating(_ word: String) -> Text {
        Text("Translating \(word)")
    }

    static var translationUnavailable: Text {
        Text("Translation unavailable")
    }

    static var noTranslationNeeded: Text {
        Text("No translation needed")
    }

    static var opensDetails: Text {
        Text(
            "Opens details",
            comment: "VoiceOver hint on the translation in the word bubble or pill: opens the word card")
    }
}
