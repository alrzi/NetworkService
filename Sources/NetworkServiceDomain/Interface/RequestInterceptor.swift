//
//  RequestInterceptor.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation

/// Протокол интерцептора запросов
public protocol RequestInterceptor: Sendable {
    /// Адаптирует запрос перед отправкой
    /// - Parameter request: Исходный URLRequest
    /// - Returns: Модифицированный URLRequest
    func adapt(_ request: URLRequest) async throws(NetworkError) -> URLRequest
    
    /// Решает, нужно ли повторить запрос после ошибки
    /// - Parameters:
    ///   - request: Исходный запрос
    ///   - error: Ошибка, которая произошла
    ///   - attempt: Номер текущей попытки
    /// - Returns: Решение о повторной попытке
    func retry(
        request: URLRequest,
        error: NetworkError,
        attempt: Int
    ) async -> RetryDecision
}

// MARK: - Default implementations

public extension RequestInterceptor {
    func adapt(_ request: URLRequest) async throws(NetworkError) -> URLRequest {
        request
    }
    
    func retry(
        request: URLRequest,
        error: NetworkError,
        attempt: Int
    ) async -> RetryDecision {
        .doNotRetry
    }
}
