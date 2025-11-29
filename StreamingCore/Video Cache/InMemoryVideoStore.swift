import Foundation

public final class InMemoryVideoStore: VideoStore {
    private var cache: (videos: [LocalVideo], timestamp: Date)?

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
