//
//  RetryDecision.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation

/// Результат решения о повторной попытке
public enum RetryDecision: Sendable, Equatable {
    /// Повторить запрос
    case retry
    /// Не повторять
    case doNotRetry
}
