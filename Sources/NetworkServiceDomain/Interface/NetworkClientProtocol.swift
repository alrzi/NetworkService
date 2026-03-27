//
//  NetworkClientProtocol.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation

/// Протокол сетевого клиента
public protocol NetworkClientProtocol: Sendable {
    /// Выполняет сетевой запрос
    /// - Parameter request: Запрос
    /// - Returns: Ответ
    func perform<Request: RequestProtocol>(
        _ request: Request
    ) async throws(NetworkError) -> Request.Response
}
