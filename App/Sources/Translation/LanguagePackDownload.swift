import NaturalLanguage
import SwiftData
import SwiftUI
import Translation

struct LanguagePackDownload: ViewModifier {
    private struct LanguagePair: Hashable {
        let source: String
        let target: String
    }

    let isEnabled: Bool
    @Environment(Settings.self) private var settings
    @Query private var books: [Book]
    @State private var queue: [LanguagePair] = []

    func body(content: Content) -> some View {
        content
            .onChange(of: pairs) { old, new in
                guard isEnabled else {
                    return
                }
                queue += new.subtracting(old).subtracting(queue)
            }
            .translationTask(configuration) { @concurrent session in
                try? await session.prepareTranslation()
                await finishFirst()
            }
    }

    private func finishFirst() async {
        if let source = queue.first?.source {
            for scheme in [NLTagScheme.lemma, .lexicalClass] {
                _ = try? await NLTagger.requestAssets(for: NLLanguage(rawValue: source), tagScheme: scheme)
            }
        }
        queue.removeFirst()
    }

    private var pairs: Set<LanguagePair> {
        Set(
            books.map { LanguagePair(source: $0.language, target: settings.translationLanguage) }
                .filter { $0.source != $0.target })
    }

    private var configuration: TranslationSession.Configuration? {
        queue.first.map { pair in
            TranslationSession.Configuration(
                source: Locale.Language(identifier: pair.source), target: Locale.Language(identifier: pair.target))
        }
    }
}
