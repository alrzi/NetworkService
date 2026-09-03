import Foundation
import Testing
@testable import NetworkService
@testable import NetworkServiceDomain

@Suite("Передача файлов", .serialized)
struct TransferTests {
    @Test("upload() декодирует ответ")
    func uploadDecodesResponse() async throws {
        let body = Data("payload".utf8)
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.test")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(#"{"id":1,"name":"test"}"#.utf8))
        }
        let client = NetworkClient(
            session: createURLSession(),
            interceptors: [],
            maxRetries: 0
        )
        let request = RequestMock(method: .post, body: body)

        let response = try await client.upload(request, delegate: nil)

        #expect(response == UserMock(id: 1, name: "test"))
    }

    @Test("performDownload() возвращает временный файл")
    func performDownloadReturnsTemporaryFile() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.test/download")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("file".utf8))
        }
        let client = NetworkClient(
            session: createURLSession(),
            interceptors: [],
            maxRetries: 0
        )

        let fileURL = try await client.performDownload(
            DownloadRequestMock(),
            delegate: nil
        )

        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
