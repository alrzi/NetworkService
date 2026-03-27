//
//  NetworkError.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation

/// Типы ошибок сети, разделенные по категориям
public enum NetworkError: Error, Sendable, Equatable {
    /// Ошибки сети (нет связи, таймаут)
    case networkUnavailable(URLError.Code)

    /// Ошибки сервера (5xx)
    case serverError(statusCode: Int)

    /// Ошибки авторизации (401)
    case unauthorized

    /// Ошибки парсинга
    case decodingFailed(String)

    /// Ошибки создания запроса
    case requestCreationFailed(String)

    /// Другие ошибки
    case unknown(String)

    /// Можно ли повторить запрос без дополнительных действий
    public var isRetryable: Bool {
        switch self {
        case .networkUnavailable(let code):
            return [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost].contains(code)

        case .serverError(let statusCode):
            return (500...599).contains(statusCode)

        case .unauthorized, .decodingFailed, .requestCreationFailed, .unknown:
            return false
        }
    }

    /// Требуется ли обновление токена перед повтором
    public var needsTokenRefresh: Bool {
        if case .unauthorized = self {
            return true
        }
        return false
    }
}

// MARK: - LocalizedError

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable(let code):
            return "Сеть недоступна: \(URLError(code).localizedDescription)"

        case .serverError(let statusCode):
            return "Ошибка сервера: \(statusCode)"

        case .unauthorized:
            return "Ошибка авторизации"

        case .decodingFailed(let description):
            return "Ошибка декодирования: \(description)"

        case .requestCreationFailed(let description):
            return "Ошибка создания запроса: \(description)"

        case .unknown(let description):
            return "Неизвестная ошибка: \(description)"
        }
    }
}
