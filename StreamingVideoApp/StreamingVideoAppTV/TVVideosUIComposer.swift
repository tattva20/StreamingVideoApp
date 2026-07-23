import UIKit
import StreamingCore

@MainActor
public enum TVVideosUIComposer {
	public static func feedComposedWith(
		videos: [Video],
		selection: @escaping (Video) -> Void
	) -> TVVideoFeedViewController {
		let feedViewController = TVVideoFeedViewController()

		feedViewController.onRefresh = { [weak feedViewController] in
			let controllers = videos.map { video in
				let cellController = TVVideoCellController(
					viewModel: VideoViewModel(title: video.title, description: video.description),
					selection: { selection(video) })
				return TVCellController(id: video, cellController)
			}
			feedViewController?.display(controllers)
		}

		return feedViewController
	}
}
