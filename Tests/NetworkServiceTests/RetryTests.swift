import Foundation
import Testing
@testable import NetworkService
@testable import NetworkServiceDomain

@Suite
struct RetryTests {
    @Test("Retry логика авторизации", arguments: [
        AuthRetryTestCase(
            description: "401 → refresh успешен → retry",
            initialError: .unauthorized,
            refreshResult: .success(TokenResponse(accessToken: "new_token", refreshToken: nil, expiresIn: nil)),
            expectedResult: .retry,
            expectedRefreshCallCount: 1
        ),
        AuthRetryTestCase(
            description: "401 → refresh token невалиден → без retry",
            initialError: .unauthorized,
            refreshResult: .failure(.unauthorized),
            expectedResult: .doNotRetry,
            expectedRefreshCallCount: 1
        ),
        AuthRetryTestCase(
            description: "401 → нет сети при refresh → без retry",
            initialError: .unauthorized,
            refreshResult: .failure(.networkUnavailable(.notConnectedToInternet)),
            expectedResult: .doNotRetry,
            expectedRefreshCallCount: 1
        ),
        AuthRetryTestCase(
            description: "500 → без retry",
            initialError: .serverError(statusCode: 500),
            refreshResult: .success(TokenResponse(accessToken: "", refreshToken: nil, expiresIn: nil)),
            expectedResult: .doNotRetry,
            expectedRefreshCallCount: 0
        ),
    ])
    func authRetryLogic(testCase: AuthRetryTestCase) async {
        let storage = MockTokenStorage()
        let oldToken = AuthToken(accessToken: "old_access_token", refreshToken: "old", expirationTimestamp: "0")
        storage.saveToken(oldToken)
        let tokenRefresher = TokenRefresher()
        tokenRefresher.refreshTokenResult = testCase.refreshResult

        let userSession = UserSession(storage: storage)
        let sessionManager = SessionManager(sessionProvider: userSession, tokenRefresher: tokenRefresher)
        let interceptor = AuthInterceptor(sessionManager: sessionManager)

        let result = await interceptor.retry(
            request: URLRequest(url: URL(string: "https://api.test")!),
            error: testCase.initialError,
            attempt: 0
        )

        #expect(result == testCase.expectedResult, "\(testCase.description)")
        #expect(tokenRefresher.refreshTokenCallCount == testCase.expectedRefreshCallCount)
    }

    @Test("Политика повторных попыток", arguments: [
        RetryTestCase(
            description: "POST не повторяется автоматически",
            method: .post,
            error: .networkUnavailable(.timedOut),
            expectedDecision: .doNotRetry
        ),
        RetryTestCase(
            description: "GET повторяется для временной ошибки сервера",
            method: .get,
            error: .serverError(statusCode: 503),
            expectedDecision: .retry
        ),
    ])
    func retryPolicy(testCase: RetryTestCase) async {
        let interceptor = RetryInterceptor(maxRetries: 1, baseDelay: .zero)
        var request = URLRequest(url: URL(string: "https://api.test")!)
        request.httpMethod = testCase.method.rawValue

        let decision = await interceptor.retry(
            request: request,
            error: testCase.error,
            attempt: 0
        )

        #expect(decision == testCase.expectedDecision, "\(testCase.description)")
    }
}
