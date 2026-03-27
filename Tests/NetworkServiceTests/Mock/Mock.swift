//
//  Mock.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 3/25/26.
//

import Testing
import Foundation
@testable import NetworkService
@testable import NetworkServiceDomain

final class MockTokenStorage: TokenStorageProtocol, @unchecked Sendable {
    private var storage: [String: String] = [:]

    func fetch(for key: String) -> String? {
        storage[key]
    }

    func save(_ token: String, for key: String) {
        storage[key] = token
    }

    func clear(for key: String) {
        storage.removeValue(forKey: key)
    }

    func clearAll() {
        storage.removeAll()
    }
}

final class TokenRefresher: TokenRefreshing, @unchecked Sendable {
    private(set) var refreshTokenCallCount = 0
    var refreshTokenResult: Result<TokenResponse, NetworkError> = .success(
        TokenResponse(accessToken: "new_access_token", refreshToken: "new_refresh_token", expiresIn: 3600)
    )

    func refreshToken(_ refreshToken: String) async throws(NetworkError) -> TokenResponse {
        refreshTokenCallCount += 1
        return try refreshTokenResult.get()
    }
}

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    nonisolated(unsafe) static var requestCount = 0

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1
        guard let handler = Self.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
        catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

struct UserMock: Codable, Sendable, Equatable {
    let id: Int
    let name: String
}

struct RequestMock: RequestProtocol {
    typealias Response = UserMock

    var method: NetworkServiceDomain.HTTPMethod = .get
    var requiresAuth: Bool = false

    func asURLRequest() throws(NetworkServiceDomain.RequestConvertibleError) -> URLRequest {
        URLRequest(url: URL(string: "https://api.test")!)
    }

    func response(from data: Data) throws -> UserMock {
        try JSONDecoder().decode(UserMock.self, from: data)
    }
}


func createURLSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: config)
    return session
}
