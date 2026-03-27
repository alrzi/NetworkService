//
//  NetworkClient.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation
import NetworkServiceDomain

/// Сетевой клиент с поддержкой интерцепторов
final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let interceptors: [any RequestInterceptor]
    private let maxRetries: Int

    init(
        session: URLSession,
        interceptors: [any RequestInterceptor],
        maxRetries: Int
    ) {
        self.session = session
        self.interceptors = interceptors
        self.maxRetries = maxRetries
    }

    /// Выполняет сетевой запрос
    /// - Parameter request: Запрос
    /// - Returns: Ответ
    func perform<Request: RequestProtocol>(
        _ request: Request
    ) async throws(NetworkError) -> Request.Response {
        try await performWithRetry(request, attempt: 0)
    }

    /// Выполняет запрос с логикой повторных попыток
    private func performWithRetry<Request: RequestProtocol>(
        _ request: Request,
        attempt: Int
    ) async throws(NetworkError) -> Request.Response {
        let baseURLRequest = try Result { try request.asURLRequest() }
            .mapError { NetworkError.requestCreationFailed($0.localizedDescription) }.get()

        var urlRequest = baseURLRequest
        if request.requiresAuth {
            AuthHeaderHelper.markRequiresAuth(&urlRequest)
        }

        do {
            for interceptor in interceptors {
                urlRequest = try await interceptor.adapt(urlRequest)
            }

            let (data, response) = try await session.data(for: urlRequest)
            let httpResponse = try response.validate()

            interceptors.compactMap { $0 as? LoggingInterceptor }
                .forEach { $0.logResponse(request: urlRequest, response: httpResponse, data: data) }

            return try request.response(from: data)
        }
        catch {
            let networkError = NetworkError.from(error)

            for interceptor in interceptors where await interceptor.retry(request: baseURLRequest, error: networkError, attempt: attempt) == .retry {
                return try await performWithRetry(request, attempt: attempt + 1)
            }

            throw networkError
        }
    }
}
