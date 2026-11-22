//
//  NetworkClient.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 24.03.2026.
//

import Foundation
import NetworkServiceDomain

/// Сетевой клиент с поддержкой интерцепторов.
final class NetworkClient: NetworkClientProtocol {
    // MARK: - Private properties

    private let session: URLSession
    private let interceptors: [any RequestInterceptor]
    private let maxRetries: Int

    // MARK: - Lifecycle

    init(
        session: URLSession,
        interceptors: [any RequestInterceptor],
        maxRetries: Int
    ) {
        self.session = session
        self.interceptors = interceptors
        self.maxRetries = maxRetries
    }

    // MARK: - Public methods

    func perform<Request: RequestProtocol>(
        _ request: Request
    ) async throws(NetworkError) -> Request.Response {
        try await execute(
            request,
            requiresAuth: request.requiresAuth,
            operation: DataOperation()
        ) { data, _ in
            try request.response(from: data)
        }
    }

    func bytes(
        for request: any RequestConvertible,
        requiresAuth: Bool
    ) async throws(NetworkError) -> (bytes: URLSession.AsyncBytes, response: HTTPURLResponse) {
        try await execute(
            request,
            requiresAuth: requiresAuth,
            operation: BytesOperation()
        ) { bytes, response in
            (bytes, response)
        }
    }

    func upload<Request: RequestProtocol>(
        _ request: Request,
        delegate: URLSessionTaskDelegate?
    ) async throws(NetworkError) -> Request.Response {
        try await execute(
            request,
            requiresAuth: request.requiresAuth,
            operation: UploadOperation(delegate: delegate)
        ) { data, _ in
            try request.response(from: data)
        }
    }

    func upload<Request: RequestProtocol>(
        _ request: Request,
        fromFile fileURL: URL,
        delegate: URLSessionTaskDelegate?
    ) async throws(NetworkError) -> Request.Response {
        try await execute(
            request,
            requiresAuth: request.requiresAuth,
            operation: UploadFileOperation(fileURL: fileURL, delegate: delegate)
        ) { data, _ in
            try request.response(from: data)
        }
    }

    func performDownload<Request: DownloadRequestProtocol>(
        _ request: Request,
        delegate: URLSessionDownloadDelegate?
    ) async throws(NetworkError) -> URL {
        try await execute(
            request,
            requiresAuth: request.requiresAuth,
            operation: DownloadOperation(delegate: delegate)
        ) { temporaryURL, _ in
            temporaryURL
        }
    }
}

// MARK: - Request execution

private extension NetworkClient {
    func execute<Request: RequestConvertible, Operation: SessionOperation, Response>(
        _ request: Request,
        requiresAuth: Bool,
        operation: Operation,
        transform: (Operation.Output, HTTPURLResponse) throws -> Response,
        attempt: Int = 0
    ) async throws(NetworkError) -> Response {
        let baseURLRequest = try Result { try request.asURLRequest() }
            .mapError { NetworkError.requestCreationFailed($0.localizedDescription) }
            .get()

        var urlRequest = baseURLRequest
        if requiresAuth {
            AuthHeaderHelper.markRequiresAuth(&urlRequest)
        }

        do {
            for interceptor in interceptors {
                urlRequest = try await interceptor.adapt(urlRequest)
            }

            let (output, response) = try await operation.execute(session: session, request: urlRequest)
            let responseData = operation.responseData(forLogging: output)

            if let httpResponse = response as? HTTPURLResponse {
                interceptors.compactMap { $0 as? LoggingInterceptor }
                    .forEach {
                        $0.logResponse(request: urlRequest, response: httpResponse, data: responseData)
                    }
            }

            do {
                let httpResponse = try response.validate()
                return try transform(output, httpResponse)
            }
            catch {
                operation.discard(output)
                if let error = error as? DecodingError {
                    interceptors.compactMap { $0 as? LoggingInterceptor }
                        .forEach {
                            $0.logDecodingFailure(request: urlRequest, error: error, data: responseData)
                        }
                }
                throw error
            }
        }
        catch {
            let networkError = NetworkError.from(error)

            for interceptor in interceptors where await interceptor.retry(
                request: baseURLRequest,
                error: networkError,
                attempt: attempt
            ) == .retry {
                return try await execute(
                    request,
                    requiresAuth: requiresAuth,
                    operation: operation,
                    transform: transform,
                    attempt: attempt + 1
                )
            }

            throw networkError
        }
    }
}
