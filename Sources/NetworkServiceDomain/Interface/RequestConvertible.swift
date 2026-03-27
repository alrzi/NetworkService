//
//  RequestConvertible.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 05.03.2025.
//

import Foundation

public protocol RequestConvertible {
    func asURLRequest() throws(RequestConvertibleError) -> URLRequest
}
