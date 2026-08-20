import AVFoundation

@MainActor
final class CheerSoundService: NSObject {
    static let shared = CheerSoundService()

    private var player: AVAudioPlayer?
    private var pendingSpeech: (() -> Void)?

    private let resourceNames = [
        "cheer-pop",
        "cheer-sparkle",
        "cheer-star",
        "cheer-yay",
        "cheer-bonus",
    ]

    private override init() {
        super.init()
        configureAudioSession()
    }

    /// Plays a short cheer clip, then runs optional follow-up (usually TTS praise).
    func playCheer(then followUp: (() -> Void)? = nil) {
        guard AppSettings.cheerSoundsEnabled else {
            followUp?()
            return
        }

        pendingSpeech = followUp
        player?.stop()

        guard let url = randomCheerURL(),
              let cheerPlayer = try? AVAudioPlayer(contentsOf: url)
        else {
            pendingSpeech?()
            pendingSpeech = nil
            return
        }

        cheerPlayer.delegate = self
        cheerPlayer.volume = 0.95
        cheerPlayer.prepareToPlay()
        player = cheerPlayer
        cheerPlayer.play()
    }

    func stop() {
        pendingSpeech = nil
        player?.stop()
        player = nil
    }

    private func randomCheerURL() -> URL? {
        guard let name = resourceNames.randomElement() else { return nil }

        let candidates = [
            Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Resources/Cheers"),
            Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Cheers"),
            Bundle.main.url(forResource: name, withExtension: "caf"),
        ]
        return candidates.compactMap { $0 }.first
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}

extension CheerSoundService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            let followUp = pendingSpeech
            pendingSpeech = nil
            followUp?()
        }
    }
}
