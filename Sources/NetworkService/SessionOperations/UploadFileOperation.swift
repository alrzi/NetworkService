import Foundation

struct UploadFileOperation: SessionOperation {
    let fileURL: URL
    let delegate: URLSessionTaskDelegate?

    func execute(
        session: URLSession,
        request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try await session.upload(
            for: request,
            fromFile: fileURL,
            delegate: delegate
        )
    }

    func responseData(forLogging output: Data) -> Data? {
        output
    }
}
