//
//  LogLevel.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 27.03.2026.
//

import Foundation

/// Уровень детализации логирования
public enum LogLevel: Sendable {
    /// Логирование отключено
    case disabled
    /// Метод + URL + статус-код
    case basic
    /// + заголовки и тело запроса/ответа
    case detailed
}
