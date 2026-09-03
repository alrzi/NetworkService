import Foundation
import Testing
@testable import NetworkServiceDomain

@Suite
struct AuthTokenTests {
    @Test("Токен без даты истечения считается действительным")
    func tokenWithoutExpirationDateIsValid() {
        let token = AuthToken(
            accessToken: "access",
            refreshToken: nil,
            expirationTimestamp: nil
        )

        #expect(!token.isExpired)
    }

    @Test("Фабрика извлекает дату истечения из JWT")
    func factoryReadsExpirationDateFromJWT() {
        let token = AuthTokenFactory().make(
            from: TokenResponse(
                accessToken: "header.eyJleHAiOjB9.signature",
                refreshToken: nil,
                expiresIn: nil
            ),
            fallbackRefreshToken: nil
        )

        #expect(token.isExpired)
    }
}
