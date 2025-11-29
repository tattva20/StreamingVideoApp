import Foundation

public final class LocalVideoLoader {
    private let store: VideoStore
    private let currentDate: () -> Date

    public init(store: VideoStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func load() throws -> [Video] {
        if let cache = try store.retrieve(), VideoCachePolicy.validate(cache.timestamp, against: currentDate()) {
            return cache.videos.map { localVideo in
                Video(
                    id: localVideo.id,
                    title: localVideo.title,
                    description: localVideo.description,
                    url: localVideo.url,
                    thumbnailURL: localVideo.thumbnailURL,
                    duration: localVideo.duration
                )
            }
        }
        return []
    }

    public func save(_ videos: [Video]) throws {
        try store.deleteCachedVideos()
    }
}

final class VideoCachePolicy {
    private static let maxCacheAgeInDays = 7

    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = Calendar(identifier: .gregorian).date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
