import AVFoundation
import Observation

@Observable
final class Pronouncer {
    private(set) var requests: [String] = []
    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var voices: [String: AVSpeechSynthesisVoice?] = [:]

    init() {
        synthesizer.usesApplicationAudioSession = false
    }

    func canSpeak(_ language: String) -> Bool {
        voice(for: language) != nil
    }

    func speak(_ word: String, language: String) {
        guard let voice = voice(for: language) else {
            return
        }
        #if DEBUG
            requests.append("\(word) · \(language)")
        #endif
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = voice
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func voice(for language: String) -> AVSpeechSynthesisVoice? {
        if let voice = voices[language] {
            return voice
        }
        let voice = AVSpeechSynthesisVoice(language: language)
        voices[language] = voice
        return voice
    }
}
