//
//  JSONDecoder+snakeCaseIsoDateDecoder.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 05.03.2025.
//

import Foundation

public extension JSONDecoder {
    static let snakeCaseIsoDateDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
