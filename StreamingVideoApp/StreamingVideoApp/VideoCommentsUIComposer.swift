//
//  VideoCommentsUIComposer.swift
//  StreamingVideoApp
//

import UIKit
import Combine
import StreamingCore
import StreamingCoreiOS

@MainActor
public enum VideoCommentsUIComposer {
	private typealias CommentsPresentationAdapter = LoadResourcePresentationAdapter<[VideoComment], VideoCommentsViewAdapter>

	public static func commentsComposedWith(
		commentsLoader: @MainActor @escaping () -> AnyPublisher<[VideoComment], Error>
	) -> ListViewController {
		let presentationAdapter = CommentsPresentationAdapter(loader: commentsLoader)

		let commentsController = makeCommentsViewController()
		commentsController.onRefresh = presentationAdapter.loadResource

		presentationAdapter.presenter = LoadResourcePresenter(
			resourceView: VideoCommentsViewAdapter(controller: commentsController),
			loadingView: WeakRefVirtualProxy(commentsController),
			errorView: WeakRefVirtualProxy(commentsController),
			mapper: { VideoCommentsPresenter.map($0) })

		return commentsController
	}

	private static func makeCommentsViewController() -> ListViewController {
		let commentsController = ListViewController()
		commentsController.title = VideoCommentsPresenter.title
		commentsController.registerCellClass(VideoCommentCell.self)

		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(commentsController, action: #selector(ListViewController.valueChanged), for: .valueChanged)
		commentsController.refreshControl = refreshControl

		return commentsController
	}
}
