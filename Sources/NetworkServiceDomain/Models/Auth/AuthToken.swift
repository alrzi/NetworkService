//
//  AuthToken.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation

/// Сущность токена авторизации
public struct AuthToken: Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let expirationDate: Date?

    /// Проверяет, истёк ли токен (с учётом буфера в 60 секунд)
    public var isExpired: Bool {
        guard let expirationDate else {
            return true
        }
        return Date() > expirationDate.addingTimeInterval(-60)
    }

    /// Timestamp для сохранения в storage
    public var expirationTimestamp: String? {
        guard let expirationDate else {
            return nil
        }
        return String(expirationDate.timeIntervalSince1970)
    }

    /// Создаёт из ответа сервера
    public init(from response: TokenResponse) {
        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        self.expirationDate = response.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
    }

    /// Создаёт из storage (timestamp от 1970 года)
    public init(accessToken: String, refreshToken: String?, expirationTimestamp: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expirationDate = expirationTimestamp.flatMap { TimeInterval($0) }.map { Date(timeIntervalSince1970: $0) }
    }
}
