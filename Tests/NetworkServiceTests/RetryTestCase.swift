import Foundation
import Testing
@testable import NetworkServiceDomain

struct RetryTestCase: Sendable, CustomTestStringConvertible {
    let description: String
    let method: HTTPMethod
    let error: NetworkError
    let expectedDecision: RetryDecision

    var testDescription: String {
        description
    }
}
