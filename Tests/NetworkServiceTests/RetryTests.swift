//
//  RetryTests.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 3/25/26.
//

import Testing
import Foundation
@testable import NetworkService
@testable import NetworkServiceDomain

@Suite
struct RetryTests {
    @Test("Retry логика", arguments: [
        // 401 → refresh успешен → retry
        RetryTestCase(
            description: "401 → refresh успешен → retry",
            initialError: .unauthorized,
            refreshResult: .success(TokenResponse(accessToken: "new_token", refreshToken: nil, expiresIn: nil)),
            expectedResult: .retry,
            expectedRefreshCallCount: 1
        ),
        // 401 → refresh token невалиден → без retry
        RetryTestCase(
            description: "401 → refresh token невалиден → без retry",
            initialError: .unauthorized,
            refreshResult: .failure(.unauthorized),
            expectedResult: .doNotRetry,
            expectedRefreshCallCount: 1
        ),
        // 401 → нет сети → retry
        RetryTestCase(
            description: "401 → нет сети → retry",
            initialError: .unauthorized,
            refreshResult: .failure(.networkUnavailable(.notConnectedToInternet)),
            expectedResult: .retry,
            expectedRefreshCallCount: 1
        ),
        // 500 → без retry
        RetryTestCase(
            description: "500 → без retry",
            initialError: .serverError(statusCode: 500),
            refreshResult: .success(TokenResponse(accessToken: "", refreshToken: nil, expiresIn: nil)),
            expectedResult: .doNotRetry,
            expectedRefreshCallCount: 0
        ),
    ])
    func retryLogic(testCase: RetryTestCase) async {
        // Given
        let storage = MockTokenStorage()
        let oldToken = AuthToken(accessToken: "old_access_token", refreshToken: "old", expirationTimestamp: "0")
        storage.saveToken(oldToken)
        let tokenRefresher = TokenRefresher()
        tokenRefresher.refreshTokenResult = testCase.refreshResult

        let userSession = UserSession(storage: storage)
        let sessionManager = SessionManager(sessionProvider: userSession, tokenRefresher: tokenRefresher)
        let interceptor = AuthInterceptor(sessionManager: sessionManager)

        // When
        let result = await interceptor.retry(
            request: URLRequest(url: URL(string: "https://api.test")!),
            error: testCase.initialError,
            attempt: 0
        )

        // Then
        #expect(result == testCase.expectedResult, "\(testCase.description)")
        #expect(tokenRefresher.refreshTokenCallCount == testCase.expectedRefreshCallCount)
    }
}

struct RetryTestCase: Sendable, CustomTestStringConvertible {
    let description: String
    let initialError: NetworkError  // Ошибка первого запроса
    let refreshResult: Result<TokenResponse, NetworkError>  // Результат обновления токена
    let expectedResult: RetryDecision  // Ожидаемый результат
    let expectedRefreshCallCount: Int  // Сколько раз вызван refreshToken

    var testDescription: String { description }
}
