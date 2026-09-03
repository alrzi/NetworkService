import Foundation

protocol SessionOperation {
    associatedtype Output

    func execute(
        session: URLSession,
        request: URLRequest
    ) async throws -> (Output, URLResponse)

    func responseData(forLogging output: Output) -> Data?
}
