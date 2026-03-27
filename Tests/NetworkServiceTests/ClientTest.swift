//
//  ClientTest.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 3/25/26.
//

import Testing
import Foundation
@testable import NetworkService
@testable import NetworkServiceDomain

@Suite("Client тесты", .serialized)
struct ClientTests {
    @Test("perform()", arguments: [
        ClientTestCase(
            description: "200 без авторизации",
            auth: .none,
            response: .successUser,
            expected: ExpectedOutcome(result: .success(UserMock(id: 1, name: "test")), refreshCalls: 0)
        ),
        ClientTestCase(
            description: "200 с авторизацией — валидный токен",
            auth: .validToken,
            response: .successUser,
            expected: ExpectedOutcome(result: .success(UserMock(id: 1, name: "test")), refreshCalls: 0)
        ),
        ClientTestCase(
            description: "401 → refresh → retry → 200",
            auth: .expiredToken(refreshResult: .success(TokenResponse(accessToken: "new_token", refreshToken: nil, expiresIn: nil))),
            response: .successUser,
            expected: ExpectedOutcome(result: .success(UserMock(id: 1, name: "test")), refreshCalls: 1)
        ),
        ClientTestCase(
            description: "401 → refresh невалиден → .unauthorized",
            auth: .expiredToken(refreshResult: .failure(.unauthorized)),
            response: .unauthorized,
            expected: ExpectedOutcome(result: .failure(.unauthorized), refreshCalls: 1)
        ),
        ClientTestCase(
            description: "500 → .serverError",
            auth: .none,
            response: .serverError,
            expected: ExpectedOutcome(result: .failure(.serverError(statusCode: 500)), refreshCalls: 0)
        ),
        ClientTestCase(
            description: "200 невалидный JSON → .decodingFailed",
            auth: .none,
            response: .invalidJSON,
            expected: ExpectedOutcome(result: .failure(.decodingFailed("Не удалось декодировать в UTF-8")), refreshCalls: 0)
        ),
    ])
    func clientPerform(testCase: ClientTestCase) async {
        // Given
        MockURLProtocol.requestCount = 0
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.test")!,
                statusCode: testCase.response.statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, testCase.response.data)
        }

        let storage = MockTokenStorage()
        let tokenRefresher = TokenRefresher()
        let userSession = UserSession(storage: storage)
        let sessionManager = SessionManager(sessionProvider: userSession, tokenRefresher: tokenRefresher)
        let interceptor = AuthInterceptor(sessionManager: sessionManager)
        let client = NetworkClient(session: createURLSession(), interceptors: [interceptor], maxRetries: 3)
        let requiresAuth = await testCase.auth.configure(storage: storage, tokenRefresher: tokenRefresher)
        let request = RequestMock(requiresAuth: requiresAuth)

        // When
        do {
            let value = try await client.perform(request)

            // Проверяем, ожидали ли мы успех
            if case .success(let expected) = testCase.expected.result {
                #expect(value == expected)
            }
            else {
                Issue.record("Ожидалась ошибка, но получен успех: \(value)")
            }
        }
        catch {
            switch (error, testCase.expected.result) {
            case (.unauthorized, .failure(.unauthorized)):
                break

            case (.serverError(let code), .failure(.serverError(let expectedCode))):
                #expect(code == expectedCode)

            case (.decodingFailed, .failure(.decodingFailed)):
                break

            default:
                Issue.record("Неожиданная ошибка: \(error), ожидалось: \(testCase.expected.result)")
            }
        }

        #expect(tokenRefresher.refreshTokenCallCount == testCase.expected.refreshCalls)
    }
}

// MARK: - Вспомогательные типы для тестов

/// Состояние авторизации для теста
enum AuthCondition: Sendable {
    case none                         // Запрос без авторизации
    case validToken                   // Авторизация есть, токен свежий
    case expiredToken(refreshResult: Result<TokenResponse, NetworkError>) // Токен протух

    /// Настраивает моки авторизации, возвращает `requiresAuth`
    func configure(storage: MockTokenStorage, tokenRefresher: TokenRefresher) async -> Bool {
        switch self {
        case .none:
            return false
        case .validToken:
            let token = AuthToken(accessToken: "old_access_token", refreshToken: "old_refresh_token", expirationTimestamp: String(Date().addingTimeInterval(3600).timeIntervalSince1970))
            storage.saveToken(token)
            return true
        case .expiredToken(let refreshResult):
            let token = AuthToken(accessToken: "old_access_token", refreshToken: "old_refresh_token", expirationTimestamp: "0")
            storage.saveToken(token)
            tokenRefresher.refreshTokenResult = refreshResult
            return true
        }
    }
}

/// Ответ сервера (мок)
struct NetworkResponse: Sendable {
    let statusCode: Int
    let data: Data

    static let successUser = NetworkResponse(statusCode: 200, data: Data("{\"id\":1,\"name\":\"test\"}".utf8))
    static let invalidJSON = NetworkResponse(statusCode: 200, data: Data("{\"wrong\":\"json\"}".utf8))
    static let unauthorized = NetworkResponse(statusCode: 401, data: Data())
    static let serverError = NetworkResponse(statusCode: 500, data: Data())
}

/// Ожидаемый результат теста
struct ExpectedOutcome: Sendable {
    let result: Result<UserMock, NetworkError>
    let refreshCalls: Int
}

// MARK: - Тест-кейс

struct ClientTestCase: Sendable {
    let description: String
    let auth: AuthCondition
    let response: NetworkResponse
    let expected: ExpectedOutcome
}
