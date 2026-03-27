//
//  TokenStorageProtocol.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation

/// Протокол хранилища токенов
public protocol TokenStorageProtocol: Sendable {
    /// Получает токен из хранилища
    /// - Parameter key: Ключ токена
    /// - Returns: Значение токена или nil
    func fetch(for key: String) -> String?
    
    /// Сохраняет токен в хранилище
    /// - Parameters:
    ///   - token: Значение токена
    ///   - key: Ключ токена
    func save(_ token: String, for key: String)
    
    /// Удаляет токен из хранилища
    /// - Parameter key: Ключ токена
    func clear(for key: String)
    
    /// Удаляет все токены
    func clearAll()
}
