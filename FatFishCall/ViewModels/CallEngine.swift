import AVFoundation
import Darwin
import Foundation
import SwiftUI
import UIKit

enum CallPhase: Equatable {
    case idle
    case connecting
    case listening
    case thinking
    case speaking
    case ended
}

@MainActor
final class CallEngine: ObservableObject {
    @Published private(set) var phase: CallPhase = .idle
    @Published private(set) var userText = ""
    @Published private(set) var assistantText = ""
    @Published private(set) var hint: String?
    @Published private(set) var lastError: String?
    @Published private(set) var isMuted = false
    @Published private(set) var speakerOn = true
    @Published private(set) var elapsed = 0
    @Published private(set) var hasAPIKey = false
    @Published private(set) var needsSystemSettings = false
    @Published private(set) var isSettingsPresented = false
    @Published private(set) var voiceConfig: VoiceConfig
    @Published private(set) var selectedModel: String

    private let speechIn = SpeechInput()
    private let speechOut = SpeechOutput()
    private let client = DeepSeekClient()

    private var history: [ChatMessage] = []
    private var streamTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var callStartedAt: Date?
    private var isCallActive = false
    private var hasGreeted = false
    private var pendingLocalListen = false
    private var streamEnded = false
    private var spokeAnything = false
    private var chunker = SentenceChunker()
    private var requestGeneration = UUID()

    private let backchannels = [
        "嗯嗯，本鱼在听～",
        "咕噜，你继续说～",
        "在呢在呢。"
    ]

    init() {
        voiceConfig = VoiceConfig.load()
        selectedModel = AppSettings.model
        hasAPIKey = KeychainStore.readAPIKey() != nil
        bindCallbacks()
    }

    // MARK: - Public controls

    func startCall() {
        guard !isCallActive else { return }
        isCallActive = true
        phase = .connecting
        hint = nil
        lastError = nil
        userText = ""
        assistantText = ""
        elapsed = 0
        callStartedAt = nil

        Task { await bootstrap() }
    }

    func restartCall() {
        guard !isCallActive else { return }
        hasGreeted = false
        history = []
        startCall()
    }

    func hangUp() {
        guard isCallActive else { return }
        isCallActive = false
        requestGeneration = UUID()
        streamTask?.cancel()
        streamTask = nil
        speechIn.stop()
        speechOut.stop()
        timerTask?.cancel()
        timerTask = nil
        pendingLocalListen = false
        streamEnded = false
        phase = .ended
        hint = "通话结束"
        AudioSession.deactivate()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        if AppConfig.exitOnHangup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                exit(0)
            }
        }
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            speechIn.stop()
            if phase == .listening {
                phase = .idle
                hint = "已静音，点一下麦克风取消"
            }
        } else {
            hint = nil
            if phase == .idle, isCallActive, !isSettingsPresented {
                startListening()
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func toggleSpeaker() {
        speakerOn.toggle()
        AudioSession.setSpeaker(speakerOn)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func tapFish() {
        switch phase {
        case .thinking, .speaking:
            bargeIn()
        case .idle:
            if hasAPIKey {
                startListening()
            } else {
                openSettings()
            }
        default:
            break
        }
    }

    func bargeIn() {
        guard isCallActive, phase == .thinking || phase == .speaking else { return }
        requestGeneration = UUID()
        streamTask?.cancel()
        streamTask = nil
        speechOut.stop()
        speechIn.stop()
        streamEnded = false
        pendingLocalListen = false
        phase = .idle
        hint = "你说，本鱼听着"
        startListening()
    }

    func openSettings() {
        guard isCallActive, phase != .ended else { return }
        speechIn.stop()
        requestGeneration = UUID()
        streamTask?.cancel()
        streamTask = nil
        speechOut.stop()
        pendingLocalListen = false
        streamEnded = false
        phase = .idle
        isSettingsPresented = true
    }

    func setSettingsPresented(_ presented: Bool) {
        if presented {
            openSettings()
        } else {
            isSettingsPresented = false
        }
    }

    func settingsDismissed() {
        guard isCallActive, !isSettingsPresented else { return }
        refreshKeyState()
        guard hasAPIKey else {
            phase = .idle
            hint = "还没有 API Key，点齿轮喂给本鱼一把"
            return
        }
        startClockIfNeeded()
        hint = nil
        lastError = nil
        if !hasGreeted {
            hasGreeted = true
            speakLocal(AppConfig.greeting, thenListen: true)
        } else if phase == .idle {
            scheduleListening()
        }
    }

    @discardableResult
    func saveAPIKey(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastError = "API Key 不能为空。"
            return false
        }
        guard KeychainStore.saveAPIKey(trimmed) else {
            lastError = "Key 没存进去，再试一次。"
            return false
        }
        hasAPIKey = true
        hint = nil
        lastError = nil
        needsSystemSettings = false
        return true
    }

    func clearAPIKey() {
        KeychainStore.deleteAPIKey()
        hasAPIKey = false
        lastError = nil
        hint = "API Key 已清除"
        speechIn.stop()
        speechOut.stop()
        streamTask?.cancel()
        streamTask = nil
        requestGeneration = UUID()
        phase = .idle
        userText = ""
        assistantText = ""
        history = []
        hasGreeted = false
        callStartedAt = nil
        elapsed = 0
        timerTask?.cancel()
        timerTask = nil
    }

    func setModel(_ id: String) {
        guard ModelCatalog.options.contains(where: { $0.id == id }) else { return }
        selectedModel = id
        AppSettings.model = id
    }

    func setVoice(_ identifier: String) {
        voiceConfig.voiceIdentifier = identifier
        voiceConfig.save()
    }

    func setPitch(_ pitch: Double) {
        voiceConfig.pitch = min(max(pitch, 1.10), 1.65)
        voiceConfig.save()
    }

    func setRate(_ rate: Double) {
        voiceConfig.rate = min(max(rate, 0.42), 0.62)
        voiceConfig.save()
    }

    func previewVoice() {
        guard isCallActive, phase != .ended else { return }
        speechIn.stop()
        requestGeneration = UUID()
        streamTask?.cancel()
        streamTask = nil
        streamEnded = false
        pendingLocalListen = false
        try? AudioSession.activate(speaker: speakerOn)
        phase = .speaking
        assistantText = "饲养员，听听本鱼的声音，软不软呀？咕噜咕噜～"
        speechOut.speakOneShot(assistantText, config: voiceConfig)
    }

    func handleScenePhase(_ newPhase: ScenePhase) {
        guard isCallActive else { return }
        if newPhase == .background {
            speechIn.stop()
            requestGeneration = UUID()
            streamTask?.cancel()
            streamTask = nil
            speechOut.stop()
            pendingLocalListen = false
            streamEnded = false
            if phase != .ended {
                phase = .idle
                hint = "回来啦，点一下本鱼继续"
            }
        }
    }

    var maskedKey: String? {
        KeychainStore.maskedKey()
    }

    // MARK: - Bootstrap

    private func bootstrap() async {
        let permissions = await SpeechInput.requestPermissions()
        guard isCallActive else { return }

        guard permissions.speechGranted else {
            phase = .idle
            needsSystemSettings = true
            hint = "语音识别权限被关掉了"
            lastError = "去系统设置打开「语音识别」"
            return
        }
        guard permissions.microphoneGranted else {
            phase = .idle
            needsSystemSettings = true
            hint = "麦克风权限被关掉了"
            lastError = "去系统设置打开「麦克风」"
            return
        }

        needsSystemSettings = false
        do {
            try AudioSession.activate(speaker: speakerOn)
        } catch {
            phase = .idle
            hint = "音频通道没打开"
            lastError = "检查一下音频输出设备"
            return
        }

        guard !isSettingsPresented else {
            phase = .idle
            return
        }

        refreshKeyState()
        guard hasAPIKey else {
            phase = .idle
            hint = "先喂给本鱼一把 DeepSeek API Key"
            isSettingsPresented = true
            return
        }

        startClockIfNeeded()
        phase = .idle
        if !hasGreeted {
            hasGreeted = true
            speakLocal(AppConfig.greeting, thenListen: true)
        } else {
            scheduleListening()
        }
    }

    private func bindCallbacks() {
        speechIn.onPartial = { [weak self] text in
            self?.handlePartial(text)
        }
        speechIn.onFinal = { [weak self] text in
            self?.handleFinal(text)
        }
        speechIn.onError = { [weak self] message in
            self?.handleInputError(message)
        }
        speechOut.onStart = { [weak self] in
            guard let self, self.phase != .ended else { return }
            self.phase = .speaking
        }
        speechOut.onFinish = { [weak self] in
            self?.handleSpeechFinished()
        }
    }

    // MARK: - Listening

    private func startListening() {
        guard isCallActive, !isMuted, !isSettingsPresented, phase == .idle else { return }
        guard hasAPIKey else {
            phase = .idle
            hint = "先喂给本鱼一把 DeepSeek API Key"
            isSettingsPresented = true
            return
        }

        do {
            try AudioSession.activate(speaker: speakerOn)
        } catch {
            phase = .idle
            hint = "麦克风没打开"
            lastError = "检查一下音频输入设备"
            return
        }

        userText = ""
        hint = nil
        needsSystemSettings = false
        phase = .listening
        speechIn.start()
    }

    private func handlePartial(_ text: String) {
        guard isCallActive, !isSettingsPresented else { return }
        if userText.isEmpty {
            assistantText = ""
        }
        userText = text
    }

    private func handleFinal(_ text: String) {
        guard isCallActive, !isSettingsPresented else { return }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        userText = clean
        guard !clean.isEmpty else {
            phase = .idle
            hint = AppConfig.notHeardLine
            return
        }

        if isBackchannel(clean) {
            speakLocal(backchannels.randomElement() ?? backchannels[0], thenListen: true)
            return
        }

        sendToDeepSeek(clean)
    }

    private func handleInputError(_ message: String) {
        guard isCallActive, !isSettingsPresented else { return }
        phase = .idle
        hint = message
        lastError = message
    }

    private func isBackchannel(_ text: String) -> Bool {
        let stripped = text
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
        guard stripped.count <= 3 else { return false }
        let fillers: Set<String> = [
            "嗯", "嗯嗯", "哦", "哦哦", "啊", "哈哈", "好", "好的",
            "对", "对的", "是", "是的", "行", "可以", "在", "在呢", "嘿"
        ]
        return fillers.contains(stripped)
    }

    // MARK: - DeepSeek

    private func sendToDeepSeek(_ text: String) {
        speechIn.stop()
        speechOut.stop()
        requestGeneration = UUID()
        streamTask?.cancel()
        streamTask = nil
        pendingLocalListen = false
        streamEnded = false
        spokeAnything = false
        assistantText = ""
        hint = nil
        lastError = nil
        phase = .thinking

        history.append(ChatMessage(role: .user, content: text))
        history = TokenBudget.trimStoredHistory(history)

        guard let key = KeychainStore.readAPIKey() else {
            hasAPIKey = false
            phase = .idle
            isSettingsPresented = true
            hint = "先喂给本鱼一把 DeepSeek API Key"
            return
        }
        hasAPIKey = true

        do {
            try AudioSession.activate(speaker: speakerOn)
        } catch {
            lastError = "音频通道没打开"
        }

        chunker = SentenceChunker()
        speechOut.beginStream(config: voiceConfig)

        let generation = UUID()
        requestGeneration = generation
        let model = selectedModel
        let requestHistory = history

        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.client.stream(
                    messages: requestHistory,
                    apiKey: key,
                    model: model
                ) { [weak self] delta in
                    guard let self, self.requestGeneration == generation else { return }
                    self.consume(delta)
                }
                guard !Task.isCancelled, self.requestGeneration == generation else { return }
                self.finishAssistantStream()
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, self.requestGeneration == generation else { return }
                self.handleStreamFailure(error)
            }
        }
    }

    private func consume(_ delta: String) {
        guard isCallActive, phase != .ended else { return }
        assistantText += delta

        let sentences = chunker.append(delta)
        for sentence in sentences {
            enqueueSpeech(sentence)
        }
    }

    private func enqueueSpeech(_ sentence: String) {
        let clean = TokenBudget.speechText(sentence)
        guard !clean.isEmpty else { return }
        spokeAnything = true
        phase = .speaking
        speechOut.enqueue(clean)
    }

    private func finishAssistantStream() {
        if let tail = chunker.flush() {
            enqueueSpeech(tail)
        }

        guard spokeAnything else {
            streamEnded = false
            speakLocal(AppConfig.emptyLine, thenListen: true)
            return
        }

        streamEnded = true
        speechOut.endStream()
    }

    private func handleStreamFailure(_ error: Error) {
        let line = (error as? DeepSeekError)?.friendlyLine ?? AppConfig.networkLine
        lastError = line

        if spokeAnything {
            streamEnded = true
            speechOut.endStream()
        } else {
            streamEnded = false
            speakLocal(line, thenListen: true)
        }
    }

    // MARK: - Speaking

    private func speakLocal(_ text: String, thenListen: Bool) {
        streamTask?.cancel()
        streamTask = nil
        requestGeneration = UUID()
        speechOut.stop()
        streamEnded = false
        pendingLocalListen = thenListen
        hint = nil
        assistantText = text
        phase = .speaking
        try? AudioSession.activate(speaker: speakerOn)
        speechOut.speakOneShot(text, config: voiceConfig)
    }

    private func handleSpeechFinished() {
        guard isCallActive else { return }

        if isSettingsPresented {
            phase = .idle
            return
        }

        if pendingLocalListen {
            pendingLocalListen = false
            phase = .idle
            scheduleListening()
            return
        }

        guard streamEnded else {
            phase = .idle
            if !isMuted, hasAPIKey {
                scheduleListening()
            } else if isMuted {
                hint = "已静音，点一下麦克风取消"
            }
            return
        }
        streamEnded = false

        let finalText = assistantText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalText.isEmpty {
            history.append(ChatMessage(role: .assistant, content: finalText))
            history = TokenBudget.trimStoredHistory(history)
        }

        phase = .idle
        if isMuted {
            hint = "已静音，点一下麦克风取消"
        } else {
            scheduleListening()
        }
    }

    private func scheduleListening(afterNanoseconds: UInt64 = 220_000_000) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: afterNanoseconds)
            guard let self, !Task.isCancelled else { return }
            self.startListening()
        }
    }

    // MARK: - Housekeeping

    private func refreshKeyState() {
        hasAPIKey = KeychainStore.readAPIKey() != nil
    }

    private func startClockIfNeeded() {
        guard callStartedAt == nil else { return }
        callStartedAt = Date()
        elapsed = 0
        startTimer()
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, self.isCallActive else { break }
                guard let start = self.callStartedAt else { continue }
                self.elapsed = Int(Date().timeIntervalSince(start))
            }
        }
    }
}
