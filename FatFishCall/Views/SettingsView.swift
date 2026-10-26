import Foundation
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var engine: CallEngine
    @Environment(\.dismiss) private var dismiss

    @State private var keyInput = ""
    @State private var isEditingKey = false
    @State private var revealKey = false
    @State private var keyMessage: String?
    @State private var showClearConfirmation = false
    @State private var voices: [VoiceOption] = []

    var body: some View {
        NavigationStack {
            Form {
                heroSection
                connectionSection
                voiceSection
                tokenSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background { OceanBackground() }
            .tint(FishTheme.mint)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FishTheme.deep.opacity(0.96), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                voices = VoiceCatalog.chineseVoices()
                if !engine.hasAPIKey {
                    isEditingKey = true
                }
            }
            .alert("清除 API Key？", isPresented: $showClearConfirmation) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    engine.clearAPIKey()
                    keyInput = ""
                    isEditingKey = true
                    keyMessage = "已清除。"
                }
            } message: {
                Text("清除后需要重新输入才能继续通话。")
            }
        }
    }

    private var heroSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [FishTheme.sky, Color(hex: "#1D6FA3")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                    Image(systemName: "fish.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: FishTheme.sky.opacity(0.35), radius: 12, y: 5)

                VStack(alignment: .leading, spacing: 3) {
                    Text("大肥鱼热线")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                    Text("DeepSeek 语音通话 · 省流版")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
        }
    }

    private var connectionSection: some View {
        Section {
            if engine.hasAPIKey && !isEditingKey {
                HStack(spacing: 10) {
                    Label("API Key", systemImage: "key.fill")
                    Spacer()
                    Text(engine.maskedKey ?? "已保存")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Button("更换 API Key") {
                    keyInput = ""
                    revealKey = false
                    keyMessage = nil
                    isEditingKey = true
                }

                Button("清除 API Key", role: .destructive) {
                    showClearConfirmation = true
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .foregroundStyle(FishTheme.mint)
                        Group {
                            if revealKey {
                                TextField("sk-...", text: $keyInput)
                            } else {
                                SecureField("sk-...", text: $keyInput)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))

                        Button {
                            revealKey.toggle()
                        } label: {
                            Image(systemName: revealKey ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.18))
                    )

                    HStack(spacing: 14) {
                        Button {
                            if let string = UIPasteboard.general.string {
                                keyInput = string.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        } label: {
                            Label("粘贴", systemImage: "doc.on.clipboard")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(FishTheme.sky)

                        Spacer()

                        Button {
                            saveKey()
                        } label: {
                            Text("保存")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(FishTheme.mint))
                                .foregroundStyle(FishTheme.ink)
                        }
                        .buttonStyle(.plain)
                        .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    }

                    Link(destination: AppConfig.apiKeysURL) {
                        Label("去 DeepSeek 开放平台拿 Key", systemImage: "arrow.up.forward")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(FishTheme.sky.opacity(0.85))

                    if engine.hasAPIKey {
                        Button("取消更换") {
                            keyInput = ""
                            keyMessage = nil
                            isEditingKey = false
                        }
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 3)
            }

            if let keyMessage {
                Text(keyMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(keyMessage.hasPrefix("已") ? FishTheme.mint : Color.orange)
            }

            Picker(selection: modelBinding) {
                ForEach(ModelCatalog.options) { option in
                    Text(option.name).tag(option.id)
                }
            } label: {
                Label("模型", systemImage: "cpu")
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading, spacing: 4) {
                Text(ModelCatalog.option(for: engine.selectedModel).detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                if engine.selectedModel == "deepseek-reasoner" {
                    Label("Reasoner 会先思考，电话里会明显变慢，也更费 token。", systemImage: "tortoise.fill")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.orange)
                }
            }
        } header: {
            Text("DeepSeek 连接")
        } footer: {
            Text("Key 只存在本机钥匙串，不经过任何中转服务器。默认 Chat 不思考，首句流式返回就开口。")
                .font(.system(size: 11))
        }
    }

    private var voiceSection: some View {
        Section {
            NavigationLink {
                VoicePickerView()
            } label: {
                HStack {
                    Label("音色", systemImage: "waveform")
                    Spacer()
                    Text(currentVoiceName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("奶音")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                    Spacer()
                    Text(String(format: "%.2f×", engine.voiceConfig.pitch))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: pitchBinding, in: 1.10...1.65, step: 0.01)
                    .tint(FishTheme.mint)
            }
            .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("语速")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                    Spacer()
                    Text(String(format: "%.2f×", engine.voiceConfig.rate / 0.5))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: rateBinding, in: 0.42...0.62, step: 0.01)
                    .tint(FishTheme.mint)
            }
            .padding(.vertical, 2)

            Button {
                engine.previewVoice()
            } label: {
                Label("试听这个音色", systemImage: "play.circle.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(FishTheme.mint)
            }
        } header: {
            Text("声音")
        } footer: {
            Text("音色来自 iOS 本地语音合成，不耗 DeepSeek token。到「设置 > 辅助功能 > 朗读内容 > 声音 > 中文」下载增强或高级音质，会更软更自然。")
                .font(.system(size: 11))
        }
    }

    private var tokenSection: some View {
        Section {
            tokenRow(icon: "bolt.fill", title: "Chat 每轮最多 80 tokens", detail: "不产生思考过程；Reasoner 单独设 300")
            tokenRow(icon: "clock.arrow.circlepath", title: "只带最近 6 句上下文", detail: "超出的旧对话自动丢掉")
            tokenRow(icon: "speaker.wave.2.fill", title: "本地合成语音", detail: "TTS 不花 DeepSeek token")
            tokenRow(icon: "text.bubble.fill", title: "本地问候和提示", detail: "不调用 API，也不计费")
        } header: {
            Text("省流策略")
        } footer: {
            Text("默认 DeepSeek Chat 不思考，配合流式返回，首句一到就开始说话，不用等全文生成完。")
                .font(.system(size: 11))
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("关于本 App", systemImage: "info.circle")
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("隐私政策", systemImage: "hand.raised.fill")
            }

            HStack {
                Text("版本")
                Spacer()
                Text(appVersion)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("关于")
        } footer: {
            Text("非官方粉丝作品，与 DeepSeek 官方无关。DeepSeek 名称归其权利人所有。")
                .font(.system(size: 11))
        }
    }

    private var modelBinding: Binding<String> {
        Binding(
            get: { engine.selectedModel },
            set: { engine.setModel($0) }
        )
    }

    private var pitchBinding: Binding<Double> {
        Binding(
            get: { engine.voiceConfig.pitch },
            set: { engine.setPitch($0) }
        )
    }

    private var rateBinding: Binding<Double> {
        Binding(
            get: { engine.voiceConfig.rate },
            set: { engine.setRate($0) }
        )
    }

    private var currentVoiceName: String {
        guard !engine.voiceConfig.voiceIdentifier.isEmpty else {
            return "自动选最萌"
        }
        return voices.first(where: { $0.id == engine.voiceConfig.voiceIdentifier })?.name ?? "系统中文音色"
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func tokenRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FishTheme.mint)
                .frame(width: 26, height: 26)
                .background(Circle().fill(FishTheme.mint.opacity(0.10)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Text(detail)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 1)
    }

    private func saveKey() {
        guard engine.saveAPIKey(keyInput) else {
            keyMessage = "没存进去，检查一下 Key 再试。"
            return
        }
        keyInput = ""
        revealKey = false
        isEditingKey = false
        keyMessage = "已保存，点右上角完成开始通话。"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
