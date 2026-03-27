//
//  NetworkServiceConfiguration.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 27.03.2026.
//

import Foundation
import NetworkServiceDomain

/// Конфигурация сетевого сервиса
public struct NetworkServiceConfiguration: Sendable {
    /// Максимальное количество повторных попыток
    public let maxRetries: Int
    /// Уровень детализации логирования
    public let logLevel: LogLevel

    /// Инициализация конфигурации
    /// - Parameters:
    ///   - maxRetries: Максимальное количество повторных попыток (по умолчанию 3)
    ///   - logLevel: Уровень детализации логов (по умолчанию .basic)
    public init(
        maxRetries: Int = 3,
        logLevel: LogLevel = .basic
    ) {
        self.maxRetries = maxRetries
        self.logLevel = logLevel
    }
}
