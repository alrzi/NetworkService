import Foundation

/// Запрос для скачивания файла.
public protocol DownloadRequestProtocol: RequestConvertible {
    var method: HTTPMethod { get }
    var requiresAuth: Bool { get }
}

public extension DownloadRequestProtocol {
    var requiresAuth: Bool {
        false
    }
}
