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

    /// Открывает поток после проверки HTTP-статуса.
    /// Ошибки чтения приходят при обходе потока. Для досрочного завершения вызовите `bytes.task.cancel()`.
    func bytes(
        for request: any RequestConvertible,
        requiresAuth: Bool
    ) async throws(NetworkError) -> (bytes: URLSession.AsyncBytes, response: HTTPURLResponse)

    func upload<Request: RequestProtocol>(
        _ request: Request,
        delegate: URLSessionTaskDelegate?
    ) async throws(NetworkError) -> Request.Response

    func upload<Request: RequestProtocol>(
        _ request: Request,
        fromFile fileURL: URL,
        delegate: URLSessionTaskDelegate?
    ) async throws(NetworkError) -> Request.Response

    func performDownload<Request: DownloadRequestProtocol>(
        _ request: Request,
        delegate: URLSessionDownloadDelegate?
    ) async throws(NetworkError) -> URL
}

public extension NetworkClientProtocol {
    func bytes(
        for request: any RequestConvertible
    ) async throws(NetworkError) -> (bytes: URLSession.AsyncBytes, response: HTTPURLResponse) {
        try await bytes(for: request, requiresAuth: false)
    }
}
