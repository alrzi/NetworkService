import Foundation

struct BytesOperation: SessionOperation {
    func execute(
        session: URLSession,
        request: URLRequest
    ) async throws -> (URLSession.AsyncBytes, URLResponse) {
        try await session.bytes(for: request)
    }

    func responseData(forLogging output: URLSession.AsyncBytes) -> Data? {
        nil
    }

    func discard(_ output: URLSession.AsyncBytes) {
        output.task.cancel()
    }
}
