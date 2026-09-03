import Foundation

struct JWTExpirationDateParser {
    func parse(_ token: String) -> Date? {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            return nil
        }

        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - payload.count % 4) % 4
        payload.append(String(repeating: "=", count: padding))

        guard
            let data = Data(base64Encoded: payload),
            let object = try? JSONSerialization.jsonObject(with: data),
            let claims = object as? [String: Any]
        else {
            return nil
        }

        let timestamp: TimeInterval?
        switch claims["exp"] {
        case let value as NSNumber:
            timestamp = value.doubleValue

        case let value as String:
            timestamp = TimeInterval(value)

        default:
            timestamp = nil
        }

        return timestamp.map(Date.init(timeIntervalSince1970:))
    }
}
