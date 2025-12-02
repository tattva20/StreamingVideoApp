//
//  VideoStore.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public typealias CachedVideos = (videos: [LocalVideo], timestamp: Date)

public protocol VideoStore {
    func deleteCachedVideos() throws
    func insert(_ videos: [LocalVideo], timestamp: Date) throws
    func retrieve() throws -> CachedVideos?
}
