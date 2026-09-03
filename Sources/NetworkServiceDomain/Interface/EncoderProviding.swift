import Foundation

public protocol EncoderProviding {
    associatedtype Encoder

    var encoder: Encoder { get }
}
