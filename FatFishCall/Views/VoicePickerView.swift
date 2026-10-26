import SwiftUI
import UIKit

struct VoicePickerView: View {
    @EnvironmentObject private var engine: CallEngine
    @State private var voices: [VoiceOption] = []

    var body: some View {
        List {
            Section {
                Button {
                    select(identifier: "")
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FishTheme.mint)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(FishTheme.mint.opacity(0.12)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("自动选最萌")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Text("优先中文（中国）的增强/高级女声")
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if engine.voiceConfig.voiceIdentifier.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(FishTheme.mint)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
                .listRowBackground(FishTheme.panel)
            } footer: {
                Text("点一下就能试听。自动模式会挑系统里音质最好的中文女声。")
                    .font(.system(size: 11))
            }

            Section {
                if voices.isEmpty {
                    Text("系统里还没有中文音色，去系统设置里下载一个吧。")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .listRowBackground(FishTheme.panel)
                } else {
                    ForEach(voices) { voice in
                        voiceRow(voice)
                    }
                }
            } header: {
                Text("已安装的中文音色")
            } footer: {
                Text("想要更软的小奶音：系统设置 > 辅助功能 > 朗读内容 > 声音 > 中文，下载「增强」或「高级」音质，再回来选它。")
                    .font(.system(size: 11))
            }
        }
        .scrollContentBackground(.hidden)
        .background { OceanBackground() }
        .listStyle(.insetGrouped)
        .tint(FishTheme.mint)
        .navigationTitle("音色")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            voices = VoiceCatalog.chineseVoices()
        }
    }

    private func voiceRow(_ voice: VoiceOption) -> some View {
        let selected = engine.voiceConfig.voiceIdentifier == voice.id

        return Button {
            select(identifier: voice.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selected ? FishTheme.ink : FishTheme.sky)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle().fill(selected ? FishTheme.mint : FishTheme.sky.opacity(0.10))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(voice.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        if voice.isFemale {
                            Text("女声")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(FishTheme.coral.opacity(0.14)))
                                .foregroundStyle(FishTheme.coral)
                        }
                    }

                    HStack(spacing: 6) {
                        Text(voice.languageLabel)
                        Text("·")
                        Text(voice.qualityLabel)
                            .foregroundStyle(qualityColor(voice.qualityRank))
                    }
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "play.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(selected ? FishTheme.mint : .white.opacity(0.28))
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .listRowBackground(FishTheme.panel)
    }

    private func select(identifier: String) {
        engine.setVoice(identifier)
        engine.previewVoice()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func qualityColor(_ rank: Int) -> Color {
        switch rank {
        case 3: return FishTheme.mint
        case 2: return FishTheme.sky
        default: return .secondary
        }
    }
}
