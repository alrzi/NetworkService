//
//  NetworkError+Mapping.swift
//  NetworkServiceDomain
//
//  Created by Александр Зиновьев on 26.03.2026.
//

import Foundation

public extension NetworkError {
    /// Маппит любую ошибку в NetworkError
    static func from(_ error: Error) -> NetworkError {
        switch error {
        case let networkError as NetworkError:
            return networkError

        case let urlError as URLError:
            return .networkUnavailable(urlError.code)

        case let requestError as RequestConvertibleError:
            return .requestCreationFailed(requestError.localizedDescription)

        case let decodingError as DecodingError:
            return .decodingFailed(decodingError.localizedDescription)

        default:
            return .unknown(error.localizedDescription)
        }
    }
}
