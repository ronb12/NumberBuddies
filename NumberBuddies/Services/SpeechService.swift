import AVFoundation

@MainActor
final class SpeechService: NSObject {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private lazy var voice: AVSpeechSynthesisVoice? = Self.selectNaturalVoice()
    private var queuedUtterances: [AVSpeechUtterance] = []

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public speech modes

    /// Reads a math problem — warm buddy narrator, clear pace.
    func speak(_ text: String) {
        speak(text, style: .problem)
    }

    /// Short cheers after a correct answer — bouncy and excited.
    func speakEncouragement(_ text: String) {
        speak(text, style: .celebration)
    }

    /// Gentle nudge on a first miss — upbeat, not discouraging.
    func speakRetry(_ text: String) {
        speak(text, style: .retry)
    }

    /// Reveals the answer after two tries — calm and reassuring.
    func speakHint(_ text: String) {
        speak(text, style: .hint)
    }

    /// Explains a helper step or invites kids to use a visual — teacher-buddy tone.
    func speakHelper(_ text: String) {
        speak(text, style: .helper)
    }

    /// Speaks several short phrases one after another (story → question, helper steps).
    func speakSequence(_ texts: [String]) {
        guard AppSettings.readAloudEnabled else { return }
        let parts = texts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !parts.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)
        queuedUtterances = parts.map { makeUtterance($0, style: .problem) }
        if let first = queuedUtterances.first {
            synthesizer.speak(first)
        }
    }

    func stop() {
        queuedUtterances.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Phrase pools

    static let celebrationPhrases = [
        "Nice work!",
        "You got it!",
        "Great job!",
        "Awesome!",
        "Way to go!",
        "Yes! You did it!",
        "Super star!",
        "High five!",
    ]

    static let retryPhrases = [
        "Hmm, try again!",
        "Almost! Give it another go!",
        "You can do it — try once more!",
        "So close! One more try!",
    ]

    static let helperIntroPhrases = [
        "Let's use a picture to help!",
        "I'll show you a helper!",
        "Tap the helper and follow along!",
    ]

    static func randomCelebration() -> String {
        celebrationPhrases.randomElement() ?? "Great job!"
    }

    static func randomRetry() -> String {
        retryPhrases.randomElement() ?? "Try again!"
    }

    // MARK: - Internals

    private enum VoiceStyle {
        case problem
        case celebration
        case retry
        case hint
        case helper

        /// Keep rates near Siri/default — high pitch + cartoon pacing sounded harsh.
        var rate: Float {
            switch self {
            case .problem: 0.48
            case .celebration: 0.50
            case .retry: 0.48
            case .hint: 0.46
            case .helper: 0.48
            }
        }

        var pitch: Float {
            switch self {
            case .problem: 1.0
            case .celebration: 1.05
            case .retry: 1.0
            case .hint: 1.0
            case .helper: 1.0
            }
        }

        var preDelay: TimeInterval {
            switch self {
            case .problem: 0.12
            case .celebration: 0.05
            case .retry: 0.08
            case .hint: 0.15
            case .helper: 0.10
            }
        }

        var postDelay: TimeInterval {
            switch self {
            case .problem: 0.08
            case .celebration: 0.05
            case .retry: 0.05
            case .hint: 0.10
            case .helper: 0.08
            }
        }
    }

    private func speak(_ text: String, style: VoiceStyle) {
        guard AppSettings.readAloudEnabled, !text.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)
        queuedUtterances.removeAll()
        synthesizer.speak(makeUtterance(text, style: style))
    }

    private func makeUtterance(_ text: String, style: VoiceStyle) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = style.rate
        utterance.pitchMultiplier = style.pitch
        utterance.preUtteranceDelay = style.preDelay
        utterance.postUtteranceDelay = style.postDelay
        return utterance
    }

    private static func selectNaturalVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let english = voices.filter { $0.language.hasPrefix("en") }

        // Prefer Siri / Samantha — clear system voice, not a cartoon kid pitch.
        let preferredNames = [
            "Siri", "Samantha", "Karen", "Allison", "Ava", "Nicky",
        ]

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

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard queuedUtterances.count > 1 else {
                queuedUtterances.removeAll()
                return
            }
            queuedUtterances.removeFirst()
            synthesizer.speak(queuedUtterances[0])
        }
    }
}

// MARK: - Spoken number formatting

enum SpokenNumbers {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static func word(for value: Int) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func ordinal(for value: Int) -> String {
        ordinalFormatter.string(from: NSNumber(value: value)) ?? word(for: value)
    }

    /// Turns display answers like `42`, `3/4`, or `0.5` into kid-friendly speech.
    static func spokenDisplayAnswer(_ display: String) -> String {
        let trimmed = display.trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = Int(trimmed) {
            return word(for: value)
        }
        if trimmed.contains("/") {
            return spokenFraction(trimmed)
        }
        if trimmed.hasPrefix("0.") {
            let tenths = trimmed.dropFirst(2)
            if let count = Int(tenths) {
                return "\(word(for: count)) tenths"
            }
        }
        if trimmed.hasSuffix("%"), let value = Int(trimmed.dropLast()) {
            return "\(word(for: value)) percent"
        }
        return trimmed
    }

    static func spokenFraction(_ text: String) -> String {
        let parts = text.split(separator: "/")
        guard parts.count == 2,
              let numerator = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let denominator = Int(parts[1].trimmingCharacters(in: .whitespaces)),
              denominator > 0
        else {
            return text.replacingOccurrences(of: "/", with: " over ")
        }

        if numerator == 1 {
            switch denominator {
            case 2: return "one half"
            case 3: return "one third"
            case 4: return "one quarter"
            case 5: return "one fifth"
            case 6: return "one sixth"
            case 8: return "one eighth"
            case 10: return "one tenth"
            default: return "one \(ordinal(for: denominator))"
            }
        }

        let numWord = word(for: numerator)
        switch denominator {
        case 2: return "\(numWord) halves"
        case 3: return "\(numWord) thirds"
        case 4: return "\(numWord) fourths"
        case 5: return "\(numWord) fifths"
        case 6: return "\(numWord) sixths"
        case 8: return "\(numWord) eighths"
        case 10: return "\(numWord) tenths"
        default: return "\(numWord) \(ordinal(for: denominator))s"
        }
    }

    static func spokenAnswer(for problem: TopicProblem) -> String {
        spokenDisplayAnswer(problem.correctDisplayAnswer)
    }
}
