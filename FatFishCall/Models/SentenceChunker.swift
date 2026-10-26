import Foundation

/// 把流式返回的文字尽快切成可朗读的短句。
/// 首句一到就交给 TTS，不必等整段回复生成完。
struct SentenceChunker {
    private var buffer = ""

    private let hardStops: Set<Character> = ["。", "！", "？", "!", "?", "…", "\n", "；", ";"]
    private let softStops: Set<Character> = ["，", ",", "、", "：", ":", "～", "~"]
    private let softLimit = 32
    private let hardLimit = 52

    mutating func append(_ delta: String) -> [String] {
        buffer += delta
        var output: [String] = []

        while let index = buffer.firstIndex(where: { hardStops.contains($0) }) {
            let end = buffer.index(after: index)
            let piece = String(buffer[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            buffer = String(buffer[end...])
            if isSpeakable(piece) {
                output.append(piece)
            }
        }

        while buffer.count > softLimit,
              let index = buffer.lastIndex(where: { softStops.contains($0) }) {
            let end = buffer.index(after: index)
            let piece = String(buffer[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            buffer = String(buffer[end...])
            if isSpeakable(piece) {
                output.append(piece)
            }
        }

        if buffer.count > hardLimit {
            let end = buffer.index(buffer.startIndex, offsetBy: hardLimit)
            let piece = String(buffer[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            buffer = String(buffer[end...])
            if isSpeakable(piece) {
                output.append(piece)
            }
        }

        return output
    }

    mutating func flush() -> String? {
        let piece = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        buffer = ""
        return isSpeakable(piece) ? piece : nil
    }

    private func isSpeakable(_ text: String) -> Bool {
        let meaningful = text.trimmingCharacters(
            in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines)
        )
        return !meaningful.isEmpty
    }
}
