import Foundation

public final class LocalVideoLoader {
    private let store: VideoStore
    private let currentDate: () -> Date

    public init(store: VideoStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func load() throws -> [Video] {
        if let cache = try store.retrieve() {
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
}
