import Foundation

extension WordTranslation {
    var grammar: String? {
        let partOfSpeech = partOfSpeech.map { String(localized: $0.name) }
        switch (lemma, partOfSpeech) {
        case (let lemma?, let partOfSpeech?):
            return String(localized: "\(lemma) · \(partOfSpeech)")
        case (let lemma?, nil):
            return lemma
        case (nil, let partOfSpeech?):
            return partOfSpeech
        case (nil, nil):
            return nil
        }
    }

    var details: String {
        guard let lemma, let partOfSpeech else {
            return grammar.map { String(localized: "\(ipa) · \($0)") } ?? ipa
        }
        return String(
            localized: "\(ipa) · \(lemma) · \(String(localized: partOfSpeech.name))",
            comment: "Word card, under the word: IPA transcription, dictionary form and part of speech")
    }
}

extension PartOfSpeech {
    fileprivate var name: LocalizedStringResource {
        switch self {
        case .noun: "noun"
        case .verb: "verb"
        case .adjective: "adjective"
        case .adverb: "adverb"
        case .pronoun: "pronoun"
        case .determiner: "determiner"
        case .particle: "particle"
        case .preposition: "preposition"
        case .number: "number"
        case .conjunction: "conjunction"
        case .interjection: "interjection"
        }
    }
}
