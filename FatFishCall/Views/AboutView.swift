import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                introCard
                featureCard
                creditsCard
                disclaimerCard
                linksCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background { OceanBackground() }
        .navigationTitle("关于本 App")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FishTheme.deep.opacity(0.96), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [FishTheme.sky, Color(hex: "#1B6C9C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 86, height: 86)
                    .shadow(color: FishTheme.sky.opacity(0.4), radius: 24, y: 10)

                Image(systemName: "fish.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("大肥鱼热线")
                .font(.system(size: 25, weight: .bold, design: .rounded))

            Text("用声音陪你说说话的 DeepSeek 大肥鱼")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))

            Text("版本 \(version)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.30))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var introCard: some View {
        InfoCard {
            Text("这不是一个正经的 AI 助手，而是一通打给大肥鱼的热线。")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))

            Text("接通后直接说话，它会用软软的小奶音回你。想插话就轻点大肥鱼，想挂断就按红色按钮——按你的要求，挂断会直接退出 App。")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .lineSpacing(4)
        }
    }

    private var featureCard: some View {
        InfoCard {
            InfoRow(icon: "bolt.fill", title: "不思考，先开口", detail: "默认 DeepSeek Chat，流式首句一到就念")
            InfoRow(icon: "leaf.fill", title: "省 token", detail: "每轮最多 80 tokens，只带最近 6 句")
            InfoRow(icon: "waveform", title: "本地小奶音", detail: "Apple TTS 合成，音色音调都能调")
            InfoRow(icon: "lock.shield.fill", title: "Key 只在本机", detail: "存在钥匙串，不经过第三方服务器")
        }
    }

    private var creditsCard: some View {
        InfoCard {
            Text("幕后")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))

            Text("界面 SwiftUI · 语音识别 Apple Speech · 语音合成 AVSpeechSynthesizer · 对话 DeepSeek API。")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
                .lineSpacing(3)
        }
    }

    private var disclaimerCard: some View {
        InfoCard {
            Label("非官方粉丝作品", systemImage: "heart.fill")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(FishTheme.coral)

            Text("本 App 与 DeepSeek 官方无关。DeepSeek 的名称、标识和相关权利归其权利人所有。App 里的大肥鱼形象是手绘的 SwiftUI 图形。")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.48))
                .lineSpacing(3)
        }
    }

    private var linksCard: some View {
        InfoCard {
            Link(destination: AppConfig.deepSeekURL) {
                LinkRow(title: "DeepSeek 官网", icon: "safari.fill")
            }

            Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                LinkRow(title: "Apple 隐私政策", icon: "apple.logo")
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                LinkRow(title: "本 App 的隐私政策", icon: "hand.raised.fill")
            }
        }
    }

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("大肥鱼热线 隐私政策")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("最后更新：2026 年 10 月 26 日")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))

                summaryCard

                privacySection(
                    title: "1. 一句话总结",
                    body: "本 App 没有自己的服务器，不收集账号、通讯录、位置或广告标识，也没有统计和广告 SDK。你的 API Key 只存在本机；语音优先在本机识别；只有识别出来的文字会发给你配置的 DeepSeek API。"
                )

                privacySection(
                    title: "2. 我们收集什么",
                    body: "不收集：姓名、手机号、邮箱、通讯录、相册、精确定位、设备广告标识、使用统计。\n\n会处理：你主动说出的语音（用于本机转文字）、转出的文字、最近的对话上下文、你在设置里填写的 API Key 和音色偏好。"
                )

                privacySection(
                    title: "3. API Key",
                    body: "API Key 通过 iOS Keychain 保存在本机，标记为仅本机、解锁后可读。它只用于向 api.deepseek.com 发起请求。本 App 不运营中转服务器，不会把 Key 上传到任何第三方。你可以在设置里随时清除；清除后 App 无法再调用 DeepSeek。"
                )

                privacySection(
                    title: "4. 麦克风与语音识别",
                    body: "麦克风只在你处于「本鱼在听」状态时工作，用于 Apple Speech 语音识别。App 会优先要求设备端识别（requiresOnDeviceRecognition）；如果设备或系统不支持中文离线识别，语音可能由 Apple 的语音服务处理。音频不会发送给 DeepSeek。"
                )

                privacySection(
                    title: "5. 文字对话",
                    body: "识别出的文字会连同固定人设提示和最近几条上下文，通过 HTTPS 发送到 DeepSeek API，用来生成回复。DeepSeek 可能按其隐私政策记录和处理这些请求。请不要在通话里说身份证号、银行卡、密码等敏感信息。"
                )

                privacySection(
                    title: "6. 本地存储",
                    body: "Keychain：DeepSeek API Key。\nUserDefaults：音色、音调、语速、模型选择。\n对话历史只存在内存里，App 退出或系统回收后清空，不写入磁盘。"
                )

                privacySection(
                    title: "7. 第三方服务",
                    body: "DeepSeek API：接收文字并生成回复，受 DeepSeek 的隐私政策约束（可在下方链接查看）。\nApple Speech：把语音转成文字，受 Apple 隐私政策约束。\nAVSpeechSynthesizer：在本机合成语音。\n除上述系统能力和你配置的 DeepSeek API 外，没有其他第三方 SDK。"
                )

                privacySection(
                    title: "8. 安全",
                    body: "所有 DeepSeek 请求使用 HTTPS；Key 存放在 Keychain；App 不记录请求头或 Key 到日志。没有任何系统能保证绝对安全，请自行保管好 API Key，并定期在 DeepSeek 后台轮换。"
                )

                privacySection(
                    title: "9. 未成年人",
                    body: "未成年人应在监护人同意和指导下使用。请勿让儿童在通话中提供个人或家庭敏感信息。"
                )

                privacySection(
                    title: "10. 你的选择",
                    body: "你可以随时在设置里更换或清除 API Key、关闭麦克风权限、停止使用并删除 App。卸载 App 会一并删除本地 Key 和偏好设置。"
                )

                privacySection(
                    title: "11. 政策更新",
                    body: "如果功能或数据处理方式发生变化，本页面会更新并修改「最后更新」日期。继续使用即表示你接受更新后的政策。"
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("相关链接")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))

                    Link("DeepSeek 官网", destination: AppConfig.deepSeekURL)
                    Link("DeepSeek 隐私政策", destination: AppConfig.deepSeekPrivacyURL)
                    Link("Apple 隐私政策", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(FishTheme.panel)
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .textSelection(.enabled)
        .background { OceanBackground() }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FishTheme.deep.opacity(0.96), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("没有账号，没有服务器，没有追踪", systemImage: "checkmark.shield.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(FishTheme.mint)

            Text("Key 在本机，声音在本机合成，只有文字会去 DeepSeek。")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FishTheme.mint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(FishTheme.mint.opacity(0.16), lineWidth: 1)
        )
    }

    private func privacySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))

            Text(body)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.56))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FishTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(FishTheme.stroke, lineWidth: 1)
        )
    }
}

private struct InfoCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(FishTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(FishTheme.stroke, lineWidth: 1)
        )
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FishTheme.mint)
                .frame(width: 28, height: 28)
                .background(Circle().fill(FishTheme.mint.opacity(0.10)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                Text(detail)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.40))
            }
        }
    }
}

private struct LinkRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FishTheme.sky)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.25))
        }
    }
}
