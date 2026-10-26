import AVFoundation
import Foundation

struct VoiceConfig: Equatable {
    var voiceIdentifier: String
    var pitch: Double
    var rate: Double

    static let defaultPitch = 1.36
    static let defaultRate = 0.53

    static let `default` = VoiceConfig(
        voiceIdentifier: "",
        pitch: defaultPitch,
        rate: defaultRate
    )

    static func load() -> VoiceConfig {
        let defaults = UserDefaults.standard
        let savedPitch = defaults.object(forKey: "fatfish.voice.pitch") as? Double ?? defaultPitch
        let savedRate = defaults.object(forKey: "fatfish.voice.rate") as? Double ?? defaultRate
        return VoiceConfig(
            voiceIdentifier: defaults.string(forKey: "fatfish.voice.id") ?? "",
            pitch: min(max(savedPitch, 1.10), 1.65),
            rate: min(max(savedRate, 0.42), 0.62)
        )
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(voiceIdentifier, forKey: "fatfish.voice.id")
        defaults.set(pitch, forKey: "fatfish.voice.pitch")
        defaults.set(rate, forKey: "fatfish.voice.rate")
    }
}

struct VoiceOption: Identifiable, Hashable {
    let id: String
    let name: String
    let languageLabel: String
    let qualityLabel: String
    let qualityRank: Int
    let isFemale: Bool

    var displayName: String {
        "\(name) · \(languageLabel)"
    }

    var subtitle: String {
        qualityLabel
    }
}

enum VoiceCatalog {
    static func chineseVoices() -> [VoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.lowercased().hasPrefix("zh") }
            .map { voice in
                VoiceOption(
                    id: voice.identifier,
                    name: voice.name,
                    languageLabel: languageLabel(voice.language),
                    qualityLabel: qualityLabel(voice.quality),
                    qualityRank: qualityRank(voice.quality),
                    isFemale: voice.gender == .female
                )
            }
            .sorted { lhs, rhs in
                if lhs.qualityRank != rhs.qualityRank { return lhs.qualityRank > rhs.qualityRank }
                if lhs.languageLabel != rhs.languageLabel { return lhs.languageLabel < rhs.languageLabel }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    static func bestVoice(for identifier: String) -> AVSpeechSynthesisVoice? {
        if !identifier.isEmpty,
           let saved = AVSpeechSynthesisVoice(identifier: identifier) {
            return saved
        }

        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.lowercased().hasPrefix("zh") }
        let best = voices.max { lhs, rhs in
            score(lhs) < score(rhs)
        }
        return best ?? AVSpeechSynthesisVoice(language: "zh-CN")
    }

    static func voice(for option: VoiceOption) -> AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice(identifier: option.id)
    }

    private static func score(_ voice: AVSpeechSynthesisVoice) -> Int {
        // 甜妹音优先：宁可选增强版婷婷，也不自动选高级男声。
        var value = qualityRank(voice.quality) * 10
        if voice.language == "zh-CN" { value += 8 }
        if voice.language == "zh-TW" { value += 4 }
        if voice.name.localizedCaseInsensitiveContains("Tingting") { value += 24 }
        if voice.name.localizedCaseInsensitiveContains("Meijia") { value += 18 }
        if voice.gender == .female { value += 10 }
        return value
    }

    private static func qualityRank(_ quality: AVSpeechSynthesisVoiceQuality) -> Int {
        switch quality {
        case .premium: return 3
        case .enhanced: return 2
        default: return 1
        }
    }

    private static func qualityLabel(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .premium: return "高级音质"
        case .enhanced: return "增强音质"
        default: return "标准音质"
        }
    }

    private static func languageLabel(_ language: String) -> String {
        switch language {
        case "zh-CN": return "中文（中国）"
        case "zh-TW": return "中文（台湾）"
        case "zh-HK": return "中文（香港）"
        case "zh-MO": return "中文（澳门）"
        default: return language
        }
    }
}
