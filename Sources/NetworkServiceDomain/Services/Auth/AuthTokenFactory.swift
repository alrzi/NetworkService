import Foundation

public struct AuthTokenFactory {
    // MARK: - Private properties

    private let jwtExpirationDateParser: JWTExpirationDateParser

    // MARK: - Lifecycle

    public init() {
        self.jwtExpirationDateParser = .init()
    }

    // MARK: - Public methods

    public func make(
        from response: TokenResponse,
        fallbackRefreshToken: String?
    ) -> AuthToken {
        let expirationDate = response.expiresIn
            .map { Date().addingTimeInterval(TimeInterval($0)) }
            ?? jwtExpirationDateParser.parse(response.accessToken)

        return AuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken ?? fallbackRefreshToken,
            expirationDate: expirationDate
        )
    }
}
