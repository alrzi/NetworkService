//
//  AuthHeaderHelper.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation

/// Хелпер для работы с заголовками авторизации
enum AuthHeaderHelper {
    private static let requiresAuthHeader = "X-Requires-Auth"

    /// Проверяет, требуется ли адаптация запроса
    static func shouldAdapt(_ request: URLRequest) -> Bool {
        request.value(forHTTPHeaderField: requiresAuthHeader) == "true"
    }

    /// Помечает запрос как требующий авторизации
    static func markRequiresAuth(_ request: inout URLRequest) {
        request.setValue("true", forHTTPHeaderField: requiresAuthHeader)
    }

    /// Добавляет заголовок Authorization и удаляет служебный заголовок
    static func adapt(_ request: URLRequest, token: String) -> URLRequest {
        var modifiedRequest = request
        modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        modifiedRequest.setValue(nil, forHTTPHeaderField: requiresAuthHeader)
        return modifiedRequest
    }
}
