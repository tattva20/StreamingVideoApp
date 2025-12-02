//
//  VideoImageDataLoader.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public protocol VideoImageDataLoader {
	func loadImageData(from url: URL) throws -> Data
}
