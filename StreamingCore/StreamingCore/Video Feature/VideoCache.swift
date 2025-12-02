//
//  VideoCache.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public protocol VideoCache {
    func save(_ videos: [Video]) throws
}
