//
//  TokenStorageProtocol+Tokens.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation
import NetworkServiceDomain

extension TokenStorageProtocol {
    /// Сохраняет токен
    func saveToken(_ token: AuthToken) {
        save(token.accessToken, for: TokenKey.accessToken.rawValue)

        if let refreshToken = token.refreshToken {
            save(refreshToken, for: TokenKey.refreshToken.rawValue)
        }

        if let timestamp = token.expirationTimestamp {
            save(timestamp, for: TokenKey.tokenExpiration.rawValue)
        }
    }

    /// Загружает токен
    func loadToken() -> AuthToken? {
        guard let accessToken = fetch(for: TokenKey.accessToken.rawValue) else {
            return nil
        }

        let refreshToken = fetch(for: TokenKey.refreshToken.rawValue)
        let expirationTimestamp = fetch(for: TokenKey.tokenExpiration.rawValue)

        return AuthToken(accessToken: accessToken, refreshToken: refreshToken, expirationTimestamp: expirationTimestamp)
    }
}

/// Ключи для хранения токенов
private enum TokenKey: String, Sendable {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case tokenExpiration = "token_expiration"
}
