import Foundation

enum DeepSeekError: Error {
    case missingKey
    case transport
    case badStatus(Int)
    case noContent

    var friendlyLine: String {
        switch self {
        case .missingKey:
            return AppConfig.missingKeyLine
        case .badStatus(401), .badStatus(403):
            return AppConfig.badKeyLine
        case .badStatus(402):
            return AppConfig.noBalanceLine
        case .badStatus(429):
            return AppConfig.rateLimitLine
        case .badStatus(let code) where code >= 500:
            return AppConfig.serverLine
        case .badStatus:
            return AppConfig.networkLine
        case .transport, .noContent:
            return AppConfig.networkLine
        }
    }
}

struct DeepSeekClient {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 40
        configuration.waitsForConnectivity = false
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        session = URLSession(configuration: configuration)
    }

    /// 流式请求。`onDelta` 在主线程被调用，首句一到就可以开始 TTS。
    func stream(
        messages: [ChatMessage],
        apiKey: String,
        model: String,
        onDelta: @escaping @MainActor (String) -> Void
    ) async throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DeepSeekError.missingKey
        }

        let cleanHistory = TokenBudget.historyForRequest(messages)
        let body = RequestBody(
            model: model,
            messages: [APIMessage(role: "system", content: Persona.systemPrompt)]
                + cleanHistory.map { APIMessage(role: $0.role.rawValue, content: $0.content) },
            stream: true,
            max_tokens: model == "deepseek-reasoner" ? AppConfig.maxReasoningTokens : AppConfig.maxOutputTokens,
            temperature: model == "deepseek-reasoner" ? nil : 1.15,
            top_p: model == "deepseek-reasoner" ? nil : 0.95
        )

        var request = URLRequest(url: AppConfig.apiURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let bytes: URLSession.AsyncBytes
        let response: URLResponse
        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw DeepSeekError.transport
        }

        guard let http = response as? HTTPURLResponse else {
            throw DeepSeekError.transport
        }
        guard (200..<300).contains(http.statusCode) else {
            throw DeepSeekError.badStatus(http.statusCode)
        }

        var received = false
        do {
            for try await rawLine in bytes.lines {
                try Task.checkCancellation()
                let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                guard line.hasPrefix("data:") else { continue }
                let payload = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if payload == "[DONE]" { break }
                guard let data = payload.data(using: .utf8) else { continue }
                guard let envelope = try? JSONDecoder().decode(StreamEnvelope.self, from: data),
                      let content = envelope.choices.first?.delta.content,
                      !content.isEmpty else {
                    continue
                }
                received = true
                await onDelta(content)
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw DeepSeekError.transport
        }

        if !received {
            throw DeepSeekError.noContent
        }
    }
}

private struct RequestBody: Encodable {
    let model: String
    let messages: [APIMessage]
    let stream: Bool
    let max_tokens: Int
    let temperature: Double?
    let top_p: Double?
}

private struct APIMessage: Encodable {
    let role: String
    let content: String
}

private struct StreamEnvelope: Decodable {
    let choices: [StreamChoice]
}

private struct StreamChoice: Decodable {
    let delta: StreamDelta
}

private struct StreamDelta: Decodable {
    let content: String?
}
