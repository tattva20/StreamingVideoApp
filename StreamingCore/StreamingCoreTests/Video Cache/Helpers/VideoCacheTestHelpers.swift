//
//  VideoCacheTestHelpers.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import StreamingCore

func uniqueVideo() -> Video {
    return Video(
        id: UUID(),
        title: "any title",
        description: "any description",
        url: URL(string: "https://any-url.com/video.mp4")!,
        thumbnailURL: URL(string: "https://any-url.com/thumb.jpg")!,
        duration: 120
    )
}

func uniqueVideoList() -> (models: [Video], local: [LocalVideo]) {
    let models = [uniqueVideo(), uniqueVideo()]
    let local = models.map { LocalVideo(
        id: $0.id,
        title: $0.title,
        description: $0.description,
        url: $0.url,
        thumbnailURL: $0.thumbnailURL,
        duration: $0.duration
    )}
    return (models, local)
}

extension Date {
	func minusVideoCacheMaxAge() -> Date {
		return adding(days: -7)
	}

	private func adding(days: Int) -> Date {
		return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
	}
}
