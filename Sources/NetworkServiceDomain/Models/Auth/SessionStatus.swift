//
//  SessionStatus.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation

/// Состояние сессии пользователя
public enum SessionStatus: Sendable {
    /// Пользователь авторизован
    case authenticated
    /// Пользователь не авторизован
    case unauthenticated
}
