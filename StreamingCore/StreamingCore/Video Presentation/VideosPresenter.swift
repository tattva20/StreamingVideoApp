import Foundation

public final class VideosPresenter {
	public static var title: String {
		NSLocalizedString("VIDEO_VIEW_TITLE",
			tableName: "Video",
			bundle: Bundle(for: VideosPresenter.self),
			comment: "Title for the video view")
	}
}
