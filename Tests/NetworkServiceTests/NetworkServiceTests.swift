import Testing
import Foundation
@testable import NetworkService
@testable import NetworkServiceDomain

@Suite("SessionManager тесты")
struct SessionManagerTests {
    
    @Test("Конкурентные запросы при истекшем токене — только один вызов refreshToken")
    func concurrentRequestsWhenTokenExpired() async {
        // Given — истекший токен
        let storage = MockTokenStorage()
        let expiredToken = AuthToken(accessToken: "expired_access_token", refreshToken: "valid_refresh_token", expirationTimestamp: "0")
        storage.saveToken(expiredToken)

        let userSession = UserSession(storage: storage)
        let tokenRefresher = TokenRefresher()
        let sessionManager = SessionManager(sessionProvider: userSession, tokenRefresher: tokenRefresher)

        // When — запускаем 10 конкурентных запросов
        await withTaskGroup(of: String?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try? await sessionManager.getValidToken()
                }
            }
            
            // Собираем результаты
            var results: [String?] = []
            for await result in group {
                results.append(result)
            }
            
            // Then
            #expect(tokenRefresher.refreshTokenCallCount == 1, "Должен быть только один вызов refreshToken")
            #expect(results.allSatisfy { $0 == "new_access_token" }, "Все запросы должны получить новый токен")
        }
    }
    
    @Test("Валидный токен — не вызывает refreshToken")
    func validTokenDoesNotRefresh() async {
        // Given — валидный токен
        let storage = MockTokenStorage()
        let futureExpiration = String(Date().addingTimeInterval(3600).timeIntervalSince1970)
        let validToken = AuthToken(accessToken: "valid_access_token", refreshToken: nil, expirationTimestamp: futureExpiration)
        storage.saveToken(validToken)

        let userSession = UserSession(storage: storage)
        let tokenRefresher = TokenRefresher()
        let sessionManager = SessionManager(sessionProvider: userSession, tokenRefresher: tokenRefresher)

        // When
        let token = try? await sessionManager.getValidToken()
        
        // Then
        #expect(token == "valid_access_token", "Должен вернуть существующий токен")
        #expect(tokenRefresher.refreshTokenCallCount == 0, "Не должен вызывать refreshToken")
    }
    
}
