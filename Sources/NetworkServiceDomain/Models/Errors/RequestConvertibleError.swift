//
//  RequestConvertibleError.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation

/// Ошибки создания URLRequest
public enum RequestConvertibleError: Error {
    /// Некорректная строка URL
    case malformedURLString
    /// Не удалось скомпоновать URL из компонентов
    case componentToURLFailure
    /// Ошибка формирования HTTP body
    case httpBodyWrong
}
