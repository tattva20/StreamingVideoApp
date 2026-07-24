import UIKit
import StreamingCore

@MainActor
public enum TVVideosUIComposer {
	public static func feedComposedWith(
		videos: [Video],
		selection: @escaping @MainActor (Video) -> Void
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

	public static func feedComposedWith(
		videoLoader: @escaping () async throws -> Paginated<Video>,
		imageLoader: @escaping @Sendable (URL) async throws -> Data,
		selection: @escaping @MainActor (Video) -> Void
	) -> TVVideoFeedViewController {
		let feedViewController = TVVideoFeedViewController()
		let adapter = TVFeedLoaderPresentationAdapter(
			videoLoader: videoLoader,
			imageLoader: imageLoader,
			selection: selection)
		adapter.feedViewController = feedViewController

		feedViewController.onRefresh = { adapter.loadFeed() }
		feedViewController.onLoadMore = { adapter.loadMoreIfAvailable() }

		return feedViewController
	}
}
