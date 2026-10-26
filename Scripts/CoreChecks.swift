import Foundation

@main
struct CoreChecks {
    static func main() {
        check(TokenBudget.historyForRequest([]).isEmpty, "empty history")

        let longHistory = (0..<20).map { index in
            ChatMessage(
                role: index % 2 == 0 ? .user : .assistant,
                content: String(repeating: "鱼", count: 200)
            )
        }
        let trimmed = TokenBudget.historyForRequest(longHistory)
        check(trimmed.count <= AppConfig.maxHistoryMessages, "history message cap")
        check(trimmed.allSatisfy { $0.content.count <= 96 }, "per-message clip")
        check(trimmed.allSatisfy { $0.role != .system }, "system excluded")

        let speech = TokenBudget.speechText("大肥鱼：*咕噜*（摇尾巴）你好呀～\n今天想聊什么？")
        check(!speech.contains("摇尾巴"), "stage direction removed")
        check(!speech.contains("*"), "markdown removed")
        check(!speech.hasPrefix("大肥鱼"), "speaker prefix removed")
        check(speech.contains("你好呀"), "content retained")

        var chunker = SentenceChunker()
        let first = chunker.append("你好呀，饲")
        check(first.isEmpty, "no premature chunk")
        let second = chunker.append("养员！今天想聊什么？本鱼在听。")
        check(second.count >= 2, "punctuation chunks")
        check(chunker.flush() == nil, "nothing left after complete sentences")

        var longChunker = SentenceChunker()
        _ = longChunker.append("一句没有标点但是很长很长很长很长很长很长很长很长很长的话")
        check(longChunker.flush() != nil, "long buffer flushes")

        AppSettings.model = "deepseek-reasoner"
        check(AppSettings.model == "deepseek-reasoner", "model persistence")
        AppSettings.model = "not-a-model"
        check(AppSettings.model == "deepseek-reasoner", "invalid model rejected")
        AppSettings.model = AppConfig.defaultModel

        print("core checks passed")
    }

    static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            print("FAIL: \(message)")
            exit(1)
        }
    }
}
