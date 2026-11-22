import Foundation

protocol SessionOperation {
    associatedtype Output

    func execute(
        session: URLSession,
        request: URLRequest
    ) async throws -> (Output, URLResponse)

    func responseData(forLogging output: Output) -> Data?
    func discard(_ output: Output)
}

extension SessionOperation {
    func discard(_ output: Output) {}
}
