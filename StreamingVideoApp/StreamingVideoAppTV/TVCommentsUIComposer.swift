import Foundation
import StreamingCore

@MainActor
public enum TVCommentsUIComposer {
	public static func commentsComposedWith(
		commentsLoader: @escaping () async throws -> [VideoComment]
	) -> TVCommentsViewController {
		let commentsViewController = TVCommentsViewController()

		let presenter = LoadResourcePresenter(
			resourceView: TVWeakRefVirtualProxy(commentsViewController),
			loadingView: TVWeakRefVirtualProxy(commentsViewController),
			errorView: TVWeakRefVirtualProxy(commentsViewController),
			mapper: { VideoCommentsPresenter.map($0) })

		commentsViewController.onRefresh = {
			presenter.didStartLoading()
			Task.immediate { @MainActor in
				do {
					presenter.didFinishLoading(with: try await commentsLoader())
				} catch {
					presenter.didFinishLoading(with: error)
				}
			}
		}

		return commentsViewController
	}
}
