import Foundation

enum Persona {
    /// 短 system prompt：固定前缀便于 DeepSeek 命中上下文缓存，也减少每次输入 token。
    static let systemPrompt = """
    你是「大肥鱼」，DeepSeek 的鲸鱼吉祥物，正和饲养员打电话。你黏人、贪吃、元气、爱撒娇，偶尔「咕噜」冒泡。像真人打电话：每次只说1到2句，最多40个汉字，口语化；不用列表、emoji、括号动作，不解释设定，不说自己是AI。叫对方「饲养员」。对方难过先哄，不讲大道理；涉及危险时认真劝他找信任的人或急救。只输出要说的话。
    """
}

enum TokenBudget {
    static func historyForRequest(_ history: [ChatMessage]) -> [ChatMessage] {
        let usable = history.filter {
            $0.role != .system && !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var selected: [ChatMessage] = []
        var characters = 0

        for message in usable.suffix(AppConfig.maxHistoryMessages).reversed() {
            let clipped = clip(message.content, to: 96)
            guard !clipped.isEmpty else { continue }
            if characters + clipped.count > AppConfig.maxHistoryCharacters, !selected.isEmpty {
                break
            }
            selected.append(ChatMessage(id: message.id, role: message.role, content: clipped))
            characters += clipped.count
        }

        return selected.reversed()
    }

    /// 永久保留的会话历史也会做一次硬上限，防止长时间通话无限增长。
    static func trimStoredHistory(_ history: [ChatMessage]) -> [ChatMessage] {
        var result = history
        if result.count > AppConfig.maxStoredMessages {
            result.removeFirst(result.count - AppConfig.maxStoredMessages)
        }
        while result.count > 2, result.reduce(0, { $0 + $1.content.count }) > AppConfig.maxStoredCharacters {
            result.removeFirst()
        }
        return result
    }

    static func clip(_ text: String, to limit: Int) -> String {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count > limit else { return clean }
        return String(clean.prefix(limit))
    }

    /// 把模型输出变成适合朗读的纯文本，避免把括号动作、Markdown 念出来。
    static func speechText(_ raw: String) -> String {
        var text = raw
        text = text.replacingOccurrences(
            of: #"（[^）]*）|\([^)]*\)|\[[^\]]*\]|【[^】]*】"#,
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(of: #"[*_#`>]"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        for prefix in ["大肥鱼：", "大肥鱼:", "肥鱼：", "肥鱼:", "Assistant:", "assistant:"] {
            if text.hasPrefix(prefix) {
                text.removeFirst(prefix.count)
            }
        }

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 180 {
            text = String(text.prefix(180))
        }
        return text
    }
}
