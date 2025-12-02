//
//  CoreDataVideoStore+VideoStore.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import CoreData

extension CoreDataVideoStore: VideoStore {

    public func retrieve() throws -> CachedVideos? {
        try ManagedCache.find(in: context).map {
            CachedVideos(videos: $0.localVideos, timestamp: $0.timestamp)
        }
    }

    public func insert(_ videos: [LocalVideo], timestamp: Date) throws {
        let managedCache = try ManagedCache.newUniqueInstance(in: context)
        managedCache.timestamp = timestamp
        managedCache.videos = ManagedVideo.videos(from: videos, in: context)
        try context.save()
    }

    public func deleteCachedVideos() throws {
        try ManagedCache.deleteCache(in: context)
    }

}
