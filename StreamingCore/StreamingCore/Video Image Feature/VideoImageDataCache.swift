//
//  VideoImageDataCache.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public protocol VideoImageDataCache {
    func save(_ data: Data, for url: URL) throws
}
