import Foundation
import NetworkServiceDomain

struct UploadOperation: SessionOperation {
    let delegate: URLSessionTaskDelegate?

    func execute(
        session: URLSession,
        request: URLRequest
    ) async throws -> (Data, URLResponse) {
        guard let bodyData = request.httpBody else {
            throw NetworkError.requestCreationFailed("Upload request must contain an HTTP body")
        }

        var uploadRequest = request
        uploadRequest.httpBody = nil
        return try await session.upload(
            for: uploadRequest,
            from: bodyData,
            delegate: delegate
        )
    }

    func responseData(forLogging output: Data) -> Data? {
        output
    }
}
