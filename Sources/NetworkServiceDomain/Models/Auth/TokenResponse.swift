//
//  TokenResponse.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation

/// Ответ при обновлении токена
public struct TokenResponse: Decodable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: Int?

    public init(accessToken: String, refreshToken: String? = nil, expiresIn: Int? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}
