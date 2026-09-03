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
            return false
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

    public init(
        accessToken: String,
        refreshToken: String?,
        expirationDate: Date?
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expirationDate = expirationDate
    }

    /// Создаёт из storage (timestamp от 1970 года)
    public init(accessToken: String, refreshToken: String?, expirationTimestamp: String?) {
        self.init(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expirationDate: expirationTimestamp
                .flatMap(TimeInterval.init)
                .map(Date.init(timeIntervalSince1970:))
        )
    }
}
