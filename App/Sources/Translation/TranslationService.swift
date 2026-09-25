import Observation

@Observable
final class TranslationService {
    let provider: any TranslationProvider
    @ObservationIgnored private var cache: [TranslationRequest: WordTranslation] = [:]

    init(provider: any TranslationProvider) {
        self.provider = provider
    }

    func translate(_ request: TranslationRequest) async throws -> WordTranslation {
        if let cached = cache[request] {
            return cached
        }
        let translation = try await provider.translate(request)
        cache[request] = translation
        return translation
    }
}
