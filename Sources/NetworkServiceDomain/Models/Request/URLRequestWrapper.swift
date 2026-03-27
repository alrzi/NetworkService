//
//  URLRequestWrapper.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 05.03.2025.
//

import Foundation

public struct URLRequestWrapper: RequestProtocol {
    private let request: URLRequest
    
    public let method: HTTPMethod

    public init(request: URLRequest, method: HTTPMethod) {
        self.request = request
        self.method = method
    }
    
    public func response(from data: Data) throws -> Data {
        data
    }

    public func asURLRequest() throws(RequestConvertibleError) -> URLRequest {
        request
    }
}
