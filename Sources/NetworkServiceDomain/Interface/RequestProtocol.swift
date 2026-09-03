//
//  RequestProtocol.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 05.03.2025.
//

import Foundation

public typealias CommonRequestProtocol = RequestProtocol & DecoderProviding

public protocol RequestProtocol: RequestConvertible {
    associatedtype Response
    
    var method: HTTPMethod { get }
    
    /// Требует ли запрос авторизации
    var requiresAuth: Bool { get }
    
    func response(from data: Data) throws -> Response
}

public extension RequestProtocol {
    var requiresAuth: Bool {
        false
    }
}

public extension RequestProtocol where Response: Decodable, Self: DecoderProviding, Decoder == JSONDecoder {
    func response(from data: Data) throws -> Response {
        try decoder.decode(Response.self, from: data)
    }
}

public extension RequestProtocol where Response == Void {
    func response(from data: Data) throws -> Response {
        ()
    }
}

// MARK: - AuthorizableRequest

/// Запрос, который должен выполняться с токеном авторизации.
public protocol AuthorizableRequest: CommonRequestProtocol { }

public extension AuthorizableRequest {
    var requiresAuth: Bool {
        true
    }
}
