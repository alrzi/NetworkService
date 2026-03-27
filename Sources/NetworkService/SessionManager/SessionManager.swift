//
//  SessionManager.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation
import NetworkServiceDomain

/// Менеджер сессий, управляющий токенами авторизации
actor SessionManager {
    private let sessionProvider: any SessionCredentialsProvider
    private let tokenRefresher: TokenRefreshing
    private var refreshTask: Task<Result<String, NetworkError>, Never>?

    init(
        sessionProvider: any SessionCredentialsProvider,
        tokenRefresher: TokenRefreshing
    ) {
        self.sessionProvider = sessionProvider
        self.tokenRefresher = tokenRefresher
    }

    /// Получает валидный токен доступа
    /// - Returns: Действующий токен доступа
    func getValidToken() async throws(NetworkError) -> String {
        if let token = sessionProvider.getValidToken(), !token.isExpired {
            return token.accessToken
        }

        return try await refreshToken()
    }
}

// MARK: - Private

private extension SessionManager {
    /// Обновляет токен доступа
    /// - Returns: Новый токен доступа
    func refreshToken() async throws(NetworkError) -> String {
        if let existingTask = refreshTask {
            return try await existingTask.value.get()
        }

        let task = Task<Result<String, NetworkError>, Never> {
            defer {
                refreshTask = nil
            }

            guard let refreshToken = sessionProvider.getValidToken()?.refreshToken else {
                await sessionProvider.notifyInvalidToken()
                return .failure(.unauthorized)
            }

            do {
                let response = try await tokenRefresher.refreshToken(refreshToken)
                let token = AuthToken(from: response)
                sessionProvider.updateToken(token)
                return .success(token.accessToken)
            }
            catch {
                let networkError = NetworkError.from(error)

                if networkError.needsTokenRefresh {
                    await sessionProvider.notifyInvalidToken()
                }

                return .failure(networkError)
            }
        }
        
        refreshTask = task
        return try await task.value.get()
    }
}
