//
//  VideoPlayerPresenter.swift
//  StreamingCore
//
//  Created by Octavio Rojas on 02/12/25.
//

import Foundation

public final class VideoPlayerPresenter {
	public static var title: String {
		NSLocalizedString(
			"VIDEO_PLAYER_VIEW_TITLE",
			tableName: "VideoPlayer",
			bundle: Bundle(for: VideoPlayerPresenter.self),
			comment: "Title for the video player view")
	}

	public static func map(_ video: Video) -> VideoPlayerViewModel {
		VideoPlayerViewModel(
			title: video.title,
			videoURL: video.url
		)
	}
}
