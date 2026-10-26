import Foundation

enum AppConfig {
    static let appName = "大肥鱼热线"
    static let apiURL = URL(string: "https://api.deepseek.com/chat/completions")!
    static let apiKeysURL = URL(string: "https://platform.deepseek.com/api_keys")!
    static let deepSeekURL = URL(string: "https://www.deepseek.com/")!
    static let deepSeekPrivacyURL = URL(string: "https://cdn.deepseek.com/policies/zh-CN/deepseek-privacy-policy.html")!

    /// 语音场景只给很短的回答，既省 token，也避免大肥鱼念长篇大论。
    static let maxOutputTokens = 80
    static let maxReasoningTokens = 300
    static let maxHistoryMessages = 6
    static let maxHistoryCharacters = 560
    static let maxStoredMessages = 8
    static let maxStoredCharacters = 900

    static let defaultModel = "deepseek-chat"

    static let greeting = "喂～饲养员！本鱼来啦，咕噜咕噜。今天想聊点什么呀？"
    static let missingKeyLine = "饲养员，本鱼还没拿到 DeepSeek 的钥匙呢。点右上角的齿轮，把 API Key 喂给我吧。"
    static let emptyLine = "本鱼刚才走神了，没憋出话来。你再跟我说一次好不好？"
    static let networkLine = "哎呀，本鱼这边浪太大，信号被拍断了。再试一次好不好？"
    static let rateLimitLine = "本鱼被限流啦，喘口气再聊。"
    static let badKeyLine = "这把钥匙好像不对，本鱼进不去。去设置里换一把吧。"
    static let noBalanceLine = "本鱼的饭票好像用完了，去 DeepSeek 后台看一眼吧。"
    static let serverLine = "DeepSeek 那边打了个喷嚏，等会儿再聊。"
    static let notHeardLine = "没听清，你点一下本鱼再说一次。"

    /// 个人使用默认挂断即退出 App；上架 App Store 需改成 false。
    static let exitOnHangup = true
}

struct ModelOption: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let isRecommended: Bool
}

enum ModelCatalog {
    static let options: [ModelOption] = [
        ModelOption(
            id: "deepseek-chat",
            name: "DeepSeek Chat",
            detail: "不思考，首句最快，最省 token",
            isRecommended: true
        ),
        ModelOption(
            id: "deepseek-reasoner",
            name: "DeepSeek Reasoner",
            detail: "会先思考，明显更慢、更费 token",
            isRecommended: false
        )
    ]

    static func option(for id: String) -> ModelOption {
        options.first(where: { $0.id == id }) ?? options[0]
    }

    static func displayName(for id: String) -> String {
        option(for: id).name
    }
}

enum AppSettings {
    private static let modelKey = "fatfish.model"

    static var model: String {
        get {
            let saved = UserDefaults.standard.string(forKey: modelKey)
            guard let saved, ModelCatalog.options.contains(where: { $0.id == saved }) else {
                return AppConfig.defaultModel
            }
            return saved
        }
        set {
            guard ModelCatalog.options.contains(where: { $0.id == newValue }) else { return }
            UserDefaults.standard.set(newValue, forKey: modelKey)
        }
    }
}
