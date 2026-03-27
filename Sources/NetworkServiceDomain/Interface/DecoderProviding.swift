//
//  DecoderProviding.swift
//  NetworkService
//
//  Created by Александр Зиновьев on 05.03.2025.
//

import Foundation

public protocol DecoderProviding {
    associatedtype Decoder
    
    var decoder: Decoder { get }
}
