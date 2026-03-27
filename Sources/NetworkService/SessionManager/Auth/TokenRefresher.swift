//
//  AuthService.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation
import NetworkServiceDomain

/// Протокол сервиса авторизации
protocol TokenRefreshing: Sendable {
    /// Обновляет токен
    /// - Parameter refreshToken: Токен обновления
    /// - Returns: Новый токен
    func refreshToken(_ refreshToken: String) async throws(NetworkError) -> TokenResponse
}

/// Отправляет запрос на обновление токена
struct TokenRefresher<Request: RequestProtocol>: TokenRefreshing
where Request.Response == TokenResponse {
    private let session: URLSession
    private let requestFactory: @Sendable (String) -> Request

    init(
        session: URLSession,
        requestFactory: @escaping @Sendable (String) -> Request
    ) {
        self.session = session
        self.requestFactory = requestFactory
    }

    func refreshToken(_ refreshToken: String) async throws(NetworkError) -> TokenResponse {
        do {
            let request = requestFactory(refreshToken)
            let urlRequest = try request.asURLRequest()
            let (data, response) = try await session.data(for: urlRequest)
            _ = try response.validate()
            return try request.response(from: data)
        }
        catch {
            throw NetworkError.from(error)
        }
    }
}
