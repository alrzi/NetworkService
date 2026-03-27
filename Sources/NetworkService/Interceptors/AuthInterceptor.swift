//
//  AuthInterceptor.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation
import NetworkServiceDomain

/// Интерцептор для авторизации запросов
struct AuthInterceptor: RequestInterceptor {
    private let sessionManager: SessionManager

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func adapt(_ request: URLRequest) async throws(NetworkError) -> URLRequest {
        guard AuthHeaderHelper.shouldAdapt(request) else {
            return request
        }

        let token = try await sessionManager.getValidToken()
        return AuthHeaderHelper.adapt(request, token: token)
    }

    func retry(
        request: URLRequest,
        error: NetworkError,
        attempt: Int
    ) async -> RetryDecision {
        // Если требуется обновление токена, пробуем обновить и повторить
        guard error.needsTokenRefresh else {
            return .doNotRetry
        }

        do {
            // Принудительно обновляем токен
            _ = try await sessionManager.getValidToken()
            return .retry
        }
        catch {
            // Refresh token невалиден — прекращаем попытки
            if case .unauthorized = error {
                return .doNotRetry
            }
            // Временная ошибка — можно повторить
            return .retry
        }
    }
}
