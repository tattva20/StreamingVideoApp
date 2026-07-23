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

	public static func feedComposedWith(
		videoLoader: @escaping () async throws -> Paginated<Video>,
		imageLoader: @escaping @Sendable (URL) async throws -> Data,
		selection: @escaping (Video) -> Void
	) -> TVVideoFeedViewController {
		let feedViewController = TVVideoFeedViewController()

		feedViewController.onRefresh = { [weak feedViewController] in
			Task.immediate { @MainActor in
				guard let page = try? await videoLoader() else { return }

				let controllers = page.items.map { video in
					let cellController = TVVideoCellController(
						viewModel: VideoViewModel(title: video.title, description: video.description),
						imageLoader: imageLoader,
						thumbnailURL: video.thumbnailURL,
						selection: { selection(video) })
					return TVCellController(id: video, cellController)
				}
				feedViewController?.display(controllers)
			}
		}

		return feedViewController
	}
}
