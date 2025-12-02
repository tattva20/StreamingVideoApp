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

	public static func formatTime(_ time: TimeInterval) -> String {
		guard time.isFinite && !time.isNaN else { return "0:00" }

		let totalSeconds = Int(time)
		let hours = totalSeconds / 3600
		let minutes = (totalSeconds % 3600) / 60
		let seconds = totalSeconds % 60

		if hours > 0 {
			return String(format: "%d:%02d:%02d", hours, minutes, seconds)
		} else {
			return String(format: "%d:%02d", minutes, seconds)
		}
	}
}
