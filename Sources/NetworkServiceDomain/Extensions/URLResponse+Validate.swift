//
//  URLResponse+Validate.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation

public extension URLResponse {
    /// Валидирует HTTP ответ, выбрасывая NetworkError при ошибке
    /// - Returns: HTTPURLResponse
    func validate() throws(NetworkError) -> HTTPURLResponse {
        guard let httpResponse = self as? HTTPURLResponse else {
            throw .serverError(statusCode: -1)
        }

        switch httpResponse.statusCode {
        case 200...299: return httpResponse
        case 401: throw .unauthorized
        case 500...599: throw .serverError(statusCode: httpResponse.statusCode)
        default: throw .serverError(statusCode: httpResponse.statusCode)
        }
    }
}
