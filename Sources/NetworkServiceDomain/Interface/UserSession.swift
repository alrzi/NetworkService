//
//  UserSession.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 25.03.2026.
//

import AsyncExtensions
import Foundation

/// Протокол для сетевого слоя — доступ к токенам
public protocol SessionCredentialsProvider: Sendable {
    /// Получает валидный токен
    /// - Returns: Валидный токен или nil, если токен невалиден
    func getValidToken() -> AuthToken?
    
    /// Обновляет токен
    /// - Parameter newToken: Новый токен
    func updateToken(_ newToken: AuthToken)
    
    /// Уведомляет о невалидном токене (очищает сессию)
    func notifyInvalidToken() async
}

/// Протокол контекста идентификации пользователя — для подписок на статус
public protocol UserSessionProtocol: Sendable {
    /// Реактивный поток состояний сессии (read-only)
    var status: CurrentValueAsyncSequenceReadOnly<SessionStatus> { get }
    
    /// Текущее состояние сессии
    var currentStatus: SessionStatus { get async }
    
    /// Устанавливает сессию после авторизации
    /// - Parameter token: Токен авторизации
    func setSession(token: AuthToken) async
    
    /// Принудительный выход
    func logout() async
}
