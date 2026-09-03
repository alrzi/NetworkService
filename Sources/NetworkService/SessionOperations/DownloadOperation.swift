import Foundation

struct DownloadOperation: SessionOperation {
    let delegate: URLSessionDownloadDelegate?

    func execute(
        session: URLSession,
        request: URLRequest
    ) async throws -> (URL, URLResponse) {
        try await session.download(for: request, delegate: delegate)
    }

    func responseData(forLogging output: URL) -> Data? {
        nil
    }
}
