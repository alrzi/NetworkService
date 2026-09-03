import Foundation

struct DataOperation: SessionOperation {
    func execute(
        session: URLSession,
        request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }

    func responseData(forLogging output: Data) -> Data? {
        output
    }
}
