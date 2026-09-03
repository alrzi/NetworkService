import Foundation
@testable import NetworkServiceDomain

struct DownloadRequestMock: DownloadRequestProtocol {
    let method: HTTPMethod = .get

    func asURLRequest() throws(RequestConvertibleError) -> URLRequest {
        URLRequest(url: URL(string: "https://api.test/download")!)
    }
}
