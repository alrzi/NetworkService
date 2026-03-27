//
//  TokenStorage.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation
import Security
import NetworkServiceDomain

/// Обёртка над Keychain для хранения токенов
public final class TokenStorage: TokenStorageProtocol {
    private let service: String
    private let accessGroup: String?

    public init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    /// Получает токен из Keychain
    /// - Parameter key: Ключ токена
    /// - Returns: Значение токена или nil
    public func fetch(for key: String) -> String? {
        let query = fetchQuery(for: key)

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard
            status == errSecSuccess,
            let data = result as? Data,
            let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return token
    }

    /// Сохраняет токен в Keychain
    /// - Parameters:
    ///   - token: Значение токена
    ///   - key: Ключ токена
    public func save(_ token: String, for key: String) {
        guard let data = token.data(using: .utf8) else {
            return
        }

        // Сначала удаляем существующий токен
        clear(for: key)

        let query = saveQuery(for: key, data: data)
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Удаляет токен из Keychain
    /// - Parameter key: Ключ токена
    public func clear(for key: String) {
        let query = deleteQuery(for: key)
        SecItemDelete(query as CFDictionary)
    }

    /// Удаляет все токены
    public func clearAll() {
        let query = deleteAllQuery()
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Keychain Queries

private extension TokenStorage {
    /// Запрос для получения токена
    func fetchQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }

    /// Запрос для сохранения токена
    func saveQuery(for key: String, data: Data) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }

    /// Запрос для удаления токена
    func deleteQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }

    /// Запрос для удаления всех токенов
    func deleteAllQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
    }
}
