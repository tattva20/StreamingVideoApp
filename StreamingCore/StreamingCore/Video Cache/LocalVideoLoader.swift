import Foundation

public final class LocalVideoLoader {
	private let store: VideoStore
	private let currentDate: () -> Date

	public init(store: VideoStore, currentDate: @escaping () -> Date) {
		self.store = store
		self.currentDate = currentDate
	}
}

extension LocalVideoLoader: VideoCache {
	public func save(_ videos: [Video]) throws {
		try store.deleteCachedVideos()
		let localVideos = videos.map { video in
			LocalVideo(
				id: video.id,
				title: video.title,
				description: video.description,
				url: video.url,
				thumbnailURL: video.thumbnailURL,
				duration: video.duration
			)
		}
		try store.insert(localVideos, timestamp: currentDate())
	}
}

extension LocalVideoLoader {
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
}

extension LocalVideoLoader {
	public func validateCache() throws {
		do {
			if let cache = try store.retrieve(), !VideoCachePolicy.validate(cache.timestamp, against: currentDate()) {
				try store.deleteCachedVideos()
			}
		} catch {
			try store.deleteCachedVideos()
		}
	}
}
