import AVFoundation
import Foundation

@MainActor
final class SpeechOutput: NSObject, ObservableObject {
    private var synthesizer: AVSpeechSynthesizer?
    private var pending = 0
    private var streamOpen = false
    private var didStart = false
    private var config = VoiceConfig.default
    private var activeVoice: AVSpeechSynthesisVoice?

    var onStart: (() -> Void)?
    var onFinish: (() -> Void)?

    var isSpeaking: Bool {
        synthesizer?.isSpeaking ?? false
    }

    func beginStream(config: VoiceConfig) {
        startSession(streaming: true, config: config)
    }

    func enqueue(_ text: String) {
        let clean = TokenBudget.speechText(text)
        guard !clean.isEmpty, let synthesizer else { return }

        pending += 1
        let utterance = AVSpeechUtterance(string: clean)
        if let activeVoice {
            utterance.voice = activeVoice
        }
        utterance.pitchMultiplier = Float(config.pitch)
        utterance.rate = Float(config.rate)
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.01
        utterance.postUtteranceDelay = 0.035
        synthesizer.speak(utterance)
    }

    func endStream() {
        streamOpen = false
        finishIfNeeded()
    }

    func speakOneShot(_ text: String, config: VoiceConfig) {
        startSession(streaming: false, config: config)
        enqueue(text)
        finishIfNeeded()
    }

    func stop() {
        let old = synthesizer
        synthesizer = nil
        old?.delegate = nil
        old?.stopSpeaking(at: .immediate)
        pending = 0
        streamOpen = false
        didStart = false
        activeVoice = nil
    }

    private func startSession(streaming: Bool, config: VoiceConfig) {
        stop()
        self.config = config
        activeVoice = VoiceCatalog.bestVoice(for: config.voiceIdentifier)
        streamOpen = streaming
        didStart = false
        pending = 0

        let newSynthesizer = AVSpeechSynthesizer()
        newSynthesizer.delegate = self
        synthesizer = newSynthesizer
    }

    private func finishIfNeeded() {
        guard !streamOpen, pending <= 0 else { return }
        let callback = onFinish
        synthesizer = nil
        activeVoice = nil
        callback?()
    }
}

extension SpeechOutput: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.synthesizer === synthesizer else { return }
            guard !self.didStart else { return }
            self.didStart = true
            self.onStart?()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.synthesizer === synthesizer else { return }
            self.pending = max(0, self.pending - 1)
            self.finishIfNeeded()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.synthesizer === synthesizer else { return }
            self.pending = max(0, self.pending - 1)
            self.finishIfNeeded()
        }
    }
}
