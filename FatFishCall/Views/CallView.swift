import Foundation
import SwiftUI
import UIKit

struct CallView: View {
    @EnvironmentObject private var engine: CallEngine
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                OceanBackground()

                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 8)
                    fishSection(size: fishSize(for: proxy.size.height))
                    statusPill
                    hintArea
                    transcriptPanel(minHeight: transcriptHeight(for: proxy.size.height))
                        .padding(.top, 10)
                    Spacer(minLength: 10)
                    controls
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)
                .padding(.bottom, 8)

                if engine.phase == .ended {
                    endedOverlay
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .animation(.easeInOut(duration: 0.25), value: engine.phase)
        .onAppear { engine.startCall() }
        .onChange(of: scenePhase) { _, newPhase in
            engine.handleScenePhase(newPhase)
        }
        .sheet(isPresented: settingsBinding, onDismiss: {
            engine.settingsDismissed()
        }) {
            SettingsView()
                .environmentObject(engine)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(FishTheme.deep)
        }
    }

    private func fishSize(for height: CGFloat) -> CGFloat {
        min(286, max(222, height * 0.34))
    }

    private func transcriptHeight(for height: CGFloat) -> CGFloat {
        min(92, max(78, height * 0.12))
    }

    private var settingsBinding: Binding<Bool> {
        Binding(
            get: { engine.isSettingsPresented },
            set: { engine.setSettingsPresented($0) }
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text("大肥鱼")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(engine.hasAPIKey ? FishTheme.mint : Color.orange)
                            .frame(width: 5, height: 5)
                        Text(engine.hasAPIKey ? "在线" : "待配置")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(engine.hasAPIKey ? FishTheme.mint : Color.orange)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(
                            (engine.hasAPIKey ? FishTheme.mint : Color.orange).opacity(0.12)
                        )
                    )
                }

                Text("DeepSeek 语音热线 · 不思考")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer(minLength: 8)

            Text(formattedDuration)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .contentTransition(.numericText())

            Button {
                engine.openSettings()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(.white.opacity(0.07)))
                        .overlay(Circle().stroke(.white.opacity(0.08)))

                    if !engine.hasAPIKey {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(FishTheme.deep, lineWidth: 1.5))
                            .offset(x: 1, y: -1)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("设置")
        }
    }

    private func fishSection(size: CGFloat) -> some View {
        ZStack {
            PulseRings(
                active: engine.phase == .listening || engine.phase == .speaking,
                color: engine.phase == .speaking ? FishTheme.coral : FishTheme.mint
            )
            .frame(width: size * 0.86, height: size * 0.86)

            FatFishView(
                isSpeaking: engine.phase == .speaking,
                isListening: engine.phase == .listening
            )
            .frame(width: size, height: size * 0.92)
            .scaleEffect(engine.phase == .speaking ? 1.035 : 1.0)
            .animation(
                .easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                value: engine.phase == .speaking
            )
            .contentShape(Rectangle())
            .onTapGesture { engine.tapFish() }
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { engine.tapFish() }
        }
        .frame(maxWidth: .infinity)
        .frame(height: size * 0.94)
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            if engine.phase == .thinking {
                ProgressView()
                    .controlSize(.mini)
                    .tint(FishTheme.mint)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: statusColor.opacity(0.8), radius: 5)
            }

            Text(statusText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Capsule().fill(.white.opacity(0.07)))
        .overlay(Capsule().stroke(.white.opacity(0.09), lineWidth: 1))
    }

    @ViewBuilder
    private var hintArea: some View {
        if let hint = engine.hint, !hint.isEmpty {
            VStack(spacing: 8) {
                Text(hint)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                if engine.needsSystemSettings {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Label("打开系统设置", systemImage: "arrow.up.forward.app.fill")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(FishTheme.mint)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(FishTheme.mint.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 9)
        }
    }

    private func transcriptPanel(minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            if !engine.userText.isEmpty {
                transcriptRow(
                    label: "你",
                    text: engine.userText,
                    color: FishTheme.mint,
                    lineLimit: 2
                )
            }

            if !engine.assistantText.isEmpty {
                transcriptRow(
                    label: "鱼",
                    text: engine.assistantText,
                    color: FishTheme.coral,
                    lineLimit: 3
                )
            }

            if engine.userText.isEmpty && engine.assistantText.isEmpty {
                Text(placeholderText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
                    .lineSpacing(2)
            }

            if let error = engine.lastError,
               !error.isEmpty,
               error != engine.assistantText,
               error != (engine.hint ?? "") {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.orange.opacity(0.9))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(FishTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FishTheme.stroke, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.18), value: engine.userText)
        .animation(.easeInOut(duration: 0.18), value: engine.assistantText)
    }

    private func transcriptRow(
        label: String,
        text: String,
        color: Color,
        lineLimit: Int
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 18, height: 18)
                .background(Circle().fill(color.opacity(0.12)))

            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .lineSpacing(2)
                .lineLimit(lineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var controls: some View {
        HStack(alignment: .top, spacing: 30) {
            CallActionButton(
                icon: engine.isMuted ? "mic.slash.fill" : "mic.fill",
                title: engine.isMuted ? "取消静音" : "静音",
                active: engine.isMuted
            ) {
                engine.toggleMute()
            }

            Button {
                engine.hangUp()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(
                            Circle().fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FF7A7A"), Color(hex: "#D92D4A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
                        .shadow(color: Color(hex: "#D92D4A").opacity(0.42), radius: 20, y: 8)

                    Text("挂断")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("挂断并退出")

            CallActionButton(
                icon: engine.speakerOn ? "speaker.wave.2.fill" : "speaker.fill",
                title: engine.speakerOn ? "免提" : "听筒",
                active: engine.speakerOn
            ) {
                engine.toggleSpeaker()
            }
        }
        .padding(.top, 4)
    }

    private var footer: some View {
        VStack(spacing: 5) {
            Label("省流模式 · Chat 每轮 ≤ 80 tokens", systemImage: "leaf.fill")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(FishTheme.mint.opacity(0.62))

            Text("轻点大肥鱼可插话 · 挂断会退出 App")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.30))
        }
        .padding(.top, 12)
    }

    private var endedOverlay: some View {
        ZStack {
            Color.black.opacity(0.58).ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "fish.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(FishTheme.sky)

                Text("通话结束")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text("大肥鱼去吐泡泡了，下次再来找它玩。")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)

                Button("再拨一次") {
                    engine.restartCall()
                }
                .buttonStyle(.borderedProminent)
                .tint(FishTheme.mint)
                .foregroundStyle(FishTheme.ink)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 40)
        }
    }

    private var formattedDuration: String {
        let minutes = engine.elapsed / 60
        let seconds = engine.elapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var statusText: String {
        switch engine.phase {
        case .idle:
            if engine.needsSystemSettings { return "需要系统权限" }
            if !engine.hasAPIKey { return "等一把 API Key" }
            if engine.isMuted { return "已静音" }
            return "轻点大肥鱼开聊"
        case .connecting:
            return "正在接通…"
        case .listening:
            return "本鱼在听…"
        case .thinking:
            return "本鱼在想…"
        case .speaking:
            return "本鱼在说…"
        case .ended:
            return "已挂断"
        }
    }

    private var statusColor: Color {
        switch engine.phase {
        case .listening: return FishTheme.mint
        case .thinking: return Color(hex: "#FFD166")
        case .speaking: return FishTheme.coral
        case .connecting: return FishTheme.sky
        case .idle: return .white.opacity(0.35)
        case .ended: return FishTheme.coral
        }
    }

    private var placeholderText: String {
        switch engine.phase {
        case .idle:
            if engine.needsSystemSettings {
                return "麦克风或语音识别权限还没开，点下面的按钮去系统设置。"
            }
            if !engine.hasAPIKey {
                return "点右上角齿轮，喂本鱼一把 DeepSeek API Key。"
            }
            return "点一下大肥鱼，或者直接开口说话。"
        case .connecting:
            return "正在打开麦克风，马上就好。"
        case .listening:
            return "你慢慢说，本鱼听着呢。"
        case .thinking:
            return "本鱼在组织语言，马上开口。"
        case .speaking:
            return "轻点大肥鱼，可以插话。"
        case .ended:
            return "下次再来找本鱼玩。"
        }
    }
}

private struct CallActionButton: View {
    let icon: String
    let title: String
    var active: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(active ? FishTheme.ink : .white.opacity(0.86))
                    .frame(width: 58, height: 58)
                    .background(
                        Circle().fill(active ? FishTheme.mint : Color.white.opacity(0.09))
                    )
                    .overlay(
                        Circle().stroke(
                            active ? Color.clear : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                    )

                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
