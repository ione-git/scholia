import DesignSystem
import ReaderEngine
import SwiftUI

struct WordTap: ViewModifier {
    let controller: ReaderController?
    let language: String
    let colorScheme: ColorScheme

    @Environment(Settings.self) private var settings
    @Environment(TranslationService.self) private var translationService
    @Environment(Pronouncer.self) private var pronouncer
    @State private var lookup: WordLookup?
    @State private var detailsRange: ReaderTextRange?
    @State private var canPronounce = false

    func body(content: Content) -> some View {
        content
            .overlay { inline }
            .cardSheet(
                item: card,
                closeLabel: Text(
                    "Close card", comment: "Word card: VoiceOver label of the dimmed page that closes the card"),
                closeIdentifier: "wordCard.close", onDismiss: closeDetails
            ) { item in
                WordCardSheet(
                    lookup: lookup(of: item.word), language: language,
                    translationLanguage: settings.translationLanguage, canPronounce: canPronounce
                )
                .preferredColorScheme(colorScheme)
            }
            .task(id: controller?.word?.range) { await translate(controller?.word) }
            .task { canPronounce = pronouncer.canSpeak(language) }
    }

    @ViewBuilder
    private var inline: some View {
        if let controller, let word = controller.word, settings.wordTapStyle != .card, word.range != detailsRange {
            TranslationBubblePlacement(anchor: word.rect, topLimit: .navTop + .controlH, gap: gap) {
                translation(lookup(of: word))
                    .accessibilityAction(.escape) { controller.clearWord() }
            }
            .id(word.range)
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func translation(_ lookup: WordLookup) -> some View {
        let open = { detailsRange = lookup.word.range }
        if settings.wordTapStyle == .minimal {
            WordPill(lookup: lookup, translationLanguage: settings.translationLanguage, open: open)
        } else {
            WordBubble(
                lookup: lookup, language: language, translationLanguage: settings.translationLanguage, open: open)
        }
    }

    private var gap: CGFloat {
        settings.wordTapStyle == .minimal ? TranslationPill.anchorGap : TranslationBubble.anchorGap
    }

    private var card: Binding<WordCardItem?> {
        Binding {
            guard let word = controller?.word, settings.wordTapStyle == .card || word.range == detailsRange else {
                return nil
            }
            return WordCardItem(word: word)
        } set: { item in
            guard item == nil else {
                return
            }
            if settings.wordTapStyle == .card {
                controller?.clearWord()
            } else {
                detailsRange = nil
            }
        }
    }

    private func closeDetails() {
        detailsRange = nil
        pronouncer.stop()
    }

    private func lookup(of word: ReaderWord) -> WordLookup {
        if let lookup, lookup.word.range == word.range {
            return WordLookup(word: word, phase: lookup.phase)
        }
        if language == settings.translationLanguage {
            return WordLookup(word: word, phase: .notNeeded)
        }
        let cached = translationService.cached(request(for: word))
        return WordLookup(word: word, phase: cached.map(WordLookup.Phase.translated) ?? .loading)
    }

    private func request(for word: ReaderWord) -> TranslationRequest {
        TranslationRequest(
            word: word.text, sentence: word.sentence, offsetInSentence: word.offsetInSentence, source: language,
            target: settings.translationLanguage)
    }

    private func translate(_ word: ReaderWord?) async {
        lookup = nil
        guard let word, case .loading = lookup(of: word).phase else {
            return
        }
        do {
            let translation = try await translationService.translate(request(for: word))
            guard !Task.isCancelled else {
                return
            }
            lookup = WordLookup(word: word, phase: .translated(translation))
        } catch {
            guard !Task.isCancelled else {
                return
            }
            lookup = WordLookup(word: word, phase: .failed)
        }
    }
}

private struct WordCardItem: Identifiable {
    let word: ReaderWord

    var id: ReaderTextRange { word.range }
}
