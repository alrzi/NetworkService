//
//  NetworkServiceContainer.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation
import NetworkServiceDomain

/// Контейнер для создания сетевого клиента
public enum NetworkServiceContainer {
    /// Создает сетевой клиент без авторизации
    /// - Parameters:
    ///   - session: URLSession (по умолчанию .shared)
    ///   - configuration: Конфигурация сервиса
    ///   - additionalInterceptors: Дополнительные интерцепторы (добавляются после стандартных)
    /// - Returns: Сетевой клиент
    public static func make(
        session: URLSession = .shared,
        configuration: NetworkServiceConfiguration = .init(),
        additionalInterceptors: [any RequestInterceptor] = []
    ) -> some NetworkClientProtocol {
        makeClient(
            session: session,
            configuration: configuration,
            additionalInterceptors: additionalInterceptors
        )
    }

    /// Создает сетевой клиент с токеном (без обновления)
    /// - Parameters:
    ///   - session: URLSession (по умолчанию .shared)
    ///   - sessionProvider: Провайдер credentials
    ///   - configuration: Конфигурация сервиса
    ///   - additionalInterceptors: Дополнительные интерцепторы (добавляются после стандартных)
    /// - Returns: Сетевой клиент
    public static func makeWithToken(
        session: URLSession = .shared,
        sessionProvider: any SessionCredentialsProvider,
        configuration: NetworkServiceConfiguration = .init(),
        additionalInterceptors: [any RequestInterceptor] = []
    ) -> some NetworkClientProtocol {
        makeClient(
            session: session,
            configuration: configuration,
            authInterceptors: [TokenInterceptor(sessionProvider: sessionProvider)],
            additionalInterceptors: additionalInterceptors
        )
    }

    /// Создает сетевой клиент с полной авторизацией (обновление токена)
    /// - Parameters:
    ///   - session: URLSession (по умолчанию .shared)
    ///   - refreshSession: URLSession для обновления токена (по умолчанию .ephemeral)
    ///   - sessionProvider: Провайдер credentials (обычно UserSession)
    ///   - refreshTokenRequestFactory: Фабрика для создания запроса обновления токена
    ///   - configuration: Конфигурация сервиса
    ///   - additionalInterceptors: Дополнительные интерцепторы (добавляются после стандартных)
    /// - Returns: Сетевой клиент
    public static func makeWithAuth<RefreshRequest: RequestProtocol>(
        session: URLSession = .shared,
        refreshSession: URLSession = URLSession(configuration: .ephemeral),
        sessionProvider: any SessionCredentialsProvider,
        refreshTokenRequestFactory: @escaping @Sendable (String) -> RefreshRequest,
        configuration: NetworkServiceConfiguration = .init(),
        additionalInterceptors: [any RequestInterceptor] = []
    ) -> some NetworkClientProtocol
    where RefreshRequest.Response == TokenResponse {
        let tokenRefresher = TokenRefresher<RefreshRequest>(
            session: refreshSession,
            requestFactory: refreshTokenRequestFactory
        )

        let sessionManager = SessionManager(
            sessionProvider: sessionProvider,
            tokenRefresher: tokenRefresher
        )

        return makeClient(
            session: session,
            configuration: configuration,
            authInterceptors: [AuthInterceptor(sessionManager: sessionManager)],
            additionalInterceptors: additionalInterceptors
        )
    }
}

// MARK: - Private

private extension NetworkServiceContainer {
    static func makeClient(
        session: URLSession,
        configuration: NetworkServiceConfiguration,
        authInterceptors: [any RequestInterceptor] = [],
        additionalInterceptors: [any RequestInterceptor]
    ) -> some NetworkClientProtocol {
        var interceptors: [any RequestInterceptor] = []
        interceptors.append(contentsOf: authInterceptors)
        interceptors.append(RetryInterceptor(maxRetries: configuration.maxRetries))        
        interceptors.append(contentsOf: additionalInterceptors)
        interceptors.append(LoggingInterceptor(logLevel: configuration.logLevel))

        return NetworkClient(
            session: session,
            interceptors: interceptors,
            maxRetries: configuration.maxRetries
        )
    }
}
