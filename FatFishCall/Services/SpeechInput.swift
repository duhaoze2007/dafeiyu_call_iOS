import AVFoundation
import Foundation
import Speech

enum SpeechInputError: LocalizedError {
    case noInput
    case unavailable

    var errorDescription: String? {
        switch self {
        case .noInput:
            return "麦克风没有声音输入，检查一下设备。"
        case .unavailable:
            return "语音识别暂时不可用，稍后再试。"
        }
    }
}

@MainActor
final class SpeechInput: ObservableObject {
    struct Permissions {
        let speechStatus: SFSpeechRecognizerAuthorizationStatus
        let microphoneGranted: Bool

        var speechGranted: Bool { speechStatus == .authorized }
        var allGranted: Bool { speechGranted && microphoneGranted }
    }

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTask: Task<Void, Never>?
    private var maxDurationTask: Task<Void, Never>?
    private var transcript = ""
    private var isRunning = false
    private var tapInstalled = false
    private var sessionID = UUID()

    var onPartial: ((String) -> Void)?
    var onFinal: ((String) -> Void)?
    var onError: ((String) -> Void)?

    static func requestPermissions() async -> Permissions {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let microphoneGranted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return Permissions(speechStatus: speechStatus, microphoneGranted: microphoneGranted)
    }

    func start() {
        guard !isRunning else { return }
        guard let recognizer else {
            onError?("这台设备暂不支持中文语音识别。")
            return
        }
        guard recognizer.isAvailable else {
            onError?("语音识别暂时不可用，稍后再试。")
            return
        }

        transcript = ""
        let currentSession = UUID()
        sessionID = currentSession
        isRunning = true

        do {
            let newRequest = SFSpeechAudioBufferRecognitionRequest()
            newRequest.shouldReportPartialResults = true
            newRequest.taskHint = .dictation
            newRequest.addsPunctuation = true
            newRequest.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
            request = newRequest

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw SpeechInputError.noInput
            }

            if tapInstalled {
                input.removeTap(onBus: 0)
                tapInstalled = false
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                newRequest.append(buffer)
            }
            tapInstalled = true

            audioEngine.prepare()
            try audioEngine.start()

            task = recognizer.recognitionTask(with: newRequest) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self,
                          self.sessionID == currentSession,
                          self.isRunning else { return }

                    if let result {
                        let text = result.bestTranscription.formattedString
                        if text != self.transcript {
                            self.transcript = text
                            self.onPartial?(text)
                        }
                        self.scheduleSilenceTimeout()
                        if result.isFinal {
                            self.finish()
                        }
                    } else if let error {
                        if self.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.fail(error)
                        } else {
                            self.finish()
                        }
                    }
                }
            }

            scheduleMaxDuration()
        } catch {
            isRunning = false
            cleanup()
            onError?(friendlyMessage(for: error))
        }
    }

    func stop() {
        guard isRunning || tapInstalled else { return }
        isRunning = false
        cleanup()
    }

    private func scheduleSilenceTimeout() {
        silenceTask?.cancel()
        silenceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard let self, !Task.isCancelled, self.isRunning else { return }
            self.finish()
        }
    }

    private func scheduleMaxDuration() {
        maxDurationTask?.cancel()
        maxDurationTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            guard let self, !Task.isCancelled, self.isRunning else { return }
            self.finish()
        }
    }

    private func finish() {
        guard isRunning else { return }
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        isRunning = false
        cleanup()

        if text.isEmpty {
            onError?(AppConfig.notHeardLine)
        } else {
            onFinal?(text)
        }
    }

    private func fail(_ error: Error) {
        guard isRunning else { return }
        isRunning = false
        cleanup()
        onError?(friendlyMessage(for: error))
    }

    private func friendlyMessage(for error: Error) -> String {
        if let speechError = error as? SpeechInputError {
            return speechError.localizedDescription
        }
        return "没听清，你点一下本鱼再说一次。"
    }

    private func cleanup() {
        silenceTask?.cancel()
        silenceTask = nil
        maxDurationTask?.cancel()
        maxDurationTask = nil

        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()

        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
    }
}
