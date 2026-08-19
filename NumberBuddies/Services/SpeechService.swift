import AVFoundation

@MainActor
final class SpeechService {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private lazy var voice: AVSpeechSynthesisVoice? = Self.selectKidFriendlyVoice()

    private init() {}

    func speak(_ text: String) {
        guard AppSettings.readAloudEnabled, !text.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.38
        utterance.pitchMultiplier = 1.12
        utterance.preUtteranceDelay = 0.15
        utterance.postUtteranceDelay = 0.05
        synthesizer.speak(utterance)
    }

    func speakEncouragement(_ text: String) {
        guard AppSettings.readAloudEnabled else { return }

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.18
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private static func selectKidFriendlyVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let english = voices.filter { $0.language.hasPrefix("en") }

        let preferredNames = ["Samantha", "Allison", "Nicky", "Karen", "Ava", "Zoe"]
        for name in preferredNames {
            if let match = english.first(where: {
                $0.name.localizedCaseInsensitiveContains(name) && $0.quality == .enhanced
            }) {
                return match
            }
        }

        for name in preferredNames {
            if let match = english.first(where: { $0.name.localizedCaseInsensitiveContains(name) }) {
                return match
            }
        }

        return english.first(where: { $0.quality == .enhanced })
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}

enum SpokenNumbers {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static func word(for value: Int) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
