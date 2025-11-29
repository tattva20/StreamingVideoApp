import Foundation

public final class VideoLoaderCacheDecorator: VideoLoader {
    private let decoratee: VideoLoader
    private let cache: VideoCache

    public init(decoratee: VideoLoader, cache: VideoCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    public func load() async throws -> [Video] {
        let videos = try await decoratee.load()
        try cache.save(videos)
        return videos
    }
}
