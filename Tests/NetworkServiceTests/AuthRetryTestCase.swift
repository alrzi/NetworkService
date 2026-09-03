import Foundation
import Testing
@testable import NetworkServiceDomain

struct AuthRetryTestCase: Sendable, CustomTestStringConvertible {
    let description: String
    let initialError: NetworkError
    let refreshResult: Result<TokenResponse, NetworkError>
    let expectedResult: RetryDecision
    let expectedRefreshCallCount: Int

    var testDescription: String {
        description
    }
}
