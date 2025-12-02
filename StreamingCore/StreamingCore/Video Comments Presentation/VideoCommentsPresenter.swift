//
//  VideoCommentsPresenter.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public struct VideoCommentsViewModel: Sendable {
	public let comments: [VideoCommentViewModel]
}

public struct VideoCommentViewModel: Hashable, Sendable {
	public let message: String
	public let date: String
	public let username: String

	public init(message: String, date: String, username: String) {
		self.message = message
		self.date = date
		self.username = username
	}
}

public final class VideoCommentsPresenter {
	public static var title: String {
		NSLocalizedString(
			"VIDEO_COMMENTS_VIEW_TITLE",
			tableName: "VideoComments",
			bundle: Bundle(for: VideoCommentsPresenter.self),
			comment: "Title for the video comments view"
		)
	}

	public static func map(
		_ comments: [VideoComment],
		currentDate: Date = Date(),
		calendar: Calendar = .current,
		locale: Locale = .current
	) -> VideoCommentsViewModel {
		let formatter = RelativeDateTimeFormatter()
		formatter.calendar = calendar
		formatter.locale = locale

		return VideoCommentsViewModel(
			comments: comments.map { comment in
				VideoCommentViewModel(
					message: comment.message,
					date: formatter.localizedString(for: comment.createdAt, relativeTo: currentDate),
					username: comment.username
				)
			}
		)
	}
}
