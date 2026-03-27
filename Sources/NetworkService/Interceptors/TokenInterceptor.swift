//
//  TokenInterceptor.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation
import NetworkServiceDomain

/// Интерцептор для приклеивания токена без логики обновления
struct TokenInterceptor: RequestInterceptor {
    private let sessionProvider: any SessionCredentialsProvider

    init(sessionProvider: any SessionCredentialsProvider) {
        self.sessionProvider = sessionProvider
    }

    func adapt(_ request: URLRequest) async throws(NetworkError) -> URLRequest {
        guard AuthHeaderHelper.shouldAdapt(request) else {
            return request
        }

        guard let token = sessionProvider.getValidToken() else {
            throw .unauthorized
        }

        return AuthHeaderHelper.adapt(request, token: token.accessToken)
    }

    func retry(
        request: URLRequest,
        error: NetworkError,
        attempt: Int
    ) async -> RetryDecision {
        .doNotRetry
    }
}
