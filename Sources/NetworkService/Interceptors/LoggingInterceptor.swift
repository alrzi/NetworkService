//
//  LoggingInterceptor.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation
import OSLog
import NetworkServiceDomain

/// Интерцептор для логирования запросов
struct LoggingInterceptor: RequestInterceptor {
    private let logger: Logger
    private let logLevel: LogLevel

    /// Инициализация интерцептора логирования
    /// - Parameters:
    ///   - subsystem: Подсистема OSLog (по умолчанию "com.networkservice")
    ///   - logLevel: Уровень детализации логов
    init(
        subsystem: String = "com.networkservice",
        logLevel: LogLevel = .basic
    ) {
        self.logger = Logger(subsystem: subsystem, category: "Network")
        self.logLevel = logLevel
    }

    func adapt(_ request: URLRequest) async throws(NetworkError) -> URLRequest {
        guard logLevel != .disabled else {
            return request
        }

        let method = request.httpMethod ?? "GET"
        let url = loggedURL(request.url)

        logger.info("➡️ \(method, privacy: .public) \(url, privacy: .public)")

        if logLevel == .detailed {
            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                logger.debug("Headers: \(formatHeaders(headers), privacy: .private)")
            }
            if let body = request.httpBody {
                logger.debug("Body: \(formatJSON(body), privacy: .private)")
            }
        }

        return request
    }

    func retry(
        request: URLRequest,
        error: NetworkError,
        attempt: Int
    ) async -> RetryDecision {
        guard logLevel != .disabled else {
            return .doNotRetry
        }

        if case .networkUnavailable(.cancelled) = error {
            return .doNotRetry
        }

        guard case .networkUnavailable = error else {
            return .doNotRetry
        }

        let method = request.httpMethod ?? "GET"
        let url = loggedURL(request.url)
        logger.error("❌ \(method, privacy: .public) \(url, privacy: .public): \(error.localizedDescription, privacy: .public)")

        return .doNotRetry
    }
}

// MARK: - Response Logging

extension LoggingInterceptor {
    /// Логирует ответ
    /// - Parameters:
    ///   - request: Исходный запрос
    ///   - response: Ответ HTTP
    ///   - data: Данные ответа
    func logResponse(
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data?
    ) {
        guard logLevel != .disabled else {
            return
        }

        let method = request.httpMethod ?? "GET"
        let url = loggedURL(request.url)
        let statusCode = response.statusCode

        let emoji = (200...299).contains(statusCode) ? "✅" : "❌"

        if (200...299).contains(statusCode) {
            logger.info("\(emoji, privacy: .public) \(method, privacy: .public) \(url, privacy: .public) - \(statusCode, privacy: .public)")
        }
        else {
            let reason = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            logger.error("\(emoji, privacy: .public) \(method, privacy: .public) \(url, privacy: .public) - HTTP \(statusCode, privacy: .public) (\(reason, privacy: .public))")
        }

        if logLevel == .detailed, let data {
            logger.debug("Response: \(formatJSON(data), privacy: .private)")
        }
    }

    func logDecodingFailure(
        request: URLRequest,
        error: DecodingError,
        data: Data?
    ) {
        guard logLevel != .disabled else {
            return
        }

        let url = loggedURL(request.url)
        logger.error("❌ Decoding failed for \(url, privacy: .public): \(describe(error), privacy: .public)")

        if logLevel == .detailed, let data {
            logger.debug("Undecoded response: \(formatJSON(data), privacy: .private)")
        }
    }
}

// MARK: - Helpers

private extension LoggingInterceptor {
    func loggedURL(_ url: URL?) -> String {
        guard let url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url?.absoluteString ?? "unknown"
        }

        components.queryItems = components.queryItems?.map { item in
            ["token", "password", "code", "secret"].contains(item.name.lowercased())
                ? URLQueryItem(name: item.name, value: "<redacted>")
                : item
        }
        return components.string ?? url.absoluteString
    }

    func describe(_ error: DecodingError) -> String {
        switch error {
        case .dataCorrupted(let context):
            return "dataCorrupted at \(codingPath(context.codingPath)): \(context.debugDescription)"

        case .keyNotFound(let key, let context):
            return "keyNotFound '\(key.stringValue)' at \(codingPath(context.codingPath)): \(context.debugDescription)"

        case .typeMismatch(let type, let context):
            return "typeMismatch for \(String(describing: type)) at \(codingPath(context.codingPath)): \(context.debugDescription)"

        case .valueNotFound(let type, let context):
            return "valueNotFound for \(String(describing: type)) at \(codingPath(context.codingPath)): \(context.debugDescription)"

        @unknown default:
            return error.localizedDescription
        }
    }

    func codingPath(_ path: [any CodingKey]) -> String {
        path.isEmpty ? "$" : path.map(\.stringValue).joined(separator: ".")
    }

    /// Форматирует заголовки для логирования
    func formatHeaders(_ headers: [String: String]) -> String {
        headers
            .sorted { $0.key < $1.key }
            .map { "  \($0.key): \($0.value)" }
            .joined(separator: "\n")
    }

    /// Форматирует JSON данные для логирования
    func formatJSON(_ data: Data) -> String {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
            let prettyString = String(data: prettyData, encoding: .utf8)
        else {
            return String(data: data, encoding: .utf8) ?? "Unable to decode data (\(data.count) bytes)"
        }

        return prettyString
    }
}
