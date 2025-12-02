import Foundation

@MainActor
public final class InMemoryVideoStore: VideoStore {
    private var cache: (videos: [LocalVideo], timestamp: Date)?
    private var videoImageDataCache = NSCache<NSURL, NSData>()

    public init() {}

    public func deleteCachedVideos() throws {
        cache = nil
    }

    public func insert(_ videos: [LocalVideo], timestamp: Date) throws {
        cache = (videos, timestamp)
    }

    public func retrieve() throws -> CachedVideos? {
        return cache
    }
}

extension InMemoryVideoStore: VideoImageDataStore {
    public func insert(_ data: Data, for url: URL) throws {
        videoImageDataCache.setObject(data as NSData, forKey: url as NSURL)
    }

    public func retrieve(dataForURL url: URL) throws -> Data? {
        videoImageDataCache.object(forKey: url as NSURL) as Data?
    }
}
