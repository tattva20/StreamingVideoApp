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
		let bundle = Bundle(for: ListViewController.self)
		let storyboard = UIStoryboard(name: "VideoComments", bundle: bundle)
		let commentsController = storyboard.instantiateInitialViewController() as! ListViewController
		commentsController.title = VideoCommentsPresenter.title
		return commentsController
	}
}
