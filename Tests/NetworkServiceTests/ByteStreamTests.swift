import Foundation
import NetworkService
import NetworkServiceDomain
import Testing

@Suite("HTTP byte streams", .timeLimit(.minutes(1)))
@MainActor
struct ByteStreamTests {
    @Test
    func `events are readable before the server finishes its response`() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let client = NetworkServiceContainer.make(session: session)
        let url = try #require(URL(string: "https://stream.test/events"))
        let request = URLRequestWrapper(request: URLRequest(url: url), method: .get)

        let (bytes, response) = try await client.bytes(for: request)
        defer { bytes.task.cancel() }
        #expect(response.statusCode == 200)
        var lines = bytes.lines.makeAsyncIterator()
        #expect(try await lines.next() == "data: first")
    }

    @Test
    func `a rejected response throws before its open body is read`() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let client = NetworkServiceContainer.make(session: session)
        let url = try #require(URL(string: "https://stream.test/rejected"))
        await #expect(throws: NetworkError.unauthorized) {
            let request = URLRequestWrapper(request: URLRequest(url: url), method: .get)
            _ = try await client.bytes(for: request)
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ResponseStreamProtocol.self]
        configuration.timeoutIntervalForRequest = 5
        return URLSession(configuration: configuration)
    }
}

private final class ResponseStreamProtocol: URLProtocol {
    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let authorized = request.url?.path == "/events"
        guard let url = request.url, let response = HTTPURLResponse(
            url: url,
            statusCode: authorized ? 200 : 401,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/event-stream"]
        )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("data: first\n\n".utf8))
        // Leave the response open until the client cancels the task.
    }

    override func stopLoading() {}
}
