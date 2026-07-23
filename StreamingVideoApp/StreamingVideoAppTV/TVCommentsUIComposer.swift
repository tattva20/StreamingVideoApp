import Foundation
import StreamingCore

@MainActor
public enum TVCommentsUIComposer {
	public static func commentsComposedWith(
		commentsLoader: @escaping () async throws -> [VideoComment]
	) -> TVCommentsViewController {
		let commentsViewController = TVCommentsViewController()

		commentsViewController.onRefresh = { [weak commentsViewController] in
			Task.immediate { @MainActor in
				guard let comments = try? await commentsLoader() else { return }
				commentsViewController?.display(VideoCommentsPresenter.map(comments))
			}
		}

		return commentsViewController
	}
}
