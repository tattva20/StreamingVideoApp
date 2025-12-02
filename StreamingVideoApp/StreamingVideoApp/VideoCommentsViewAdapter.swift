//
//  VideoCommentsViewAdapter.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreiOS

final class VideoCommentsViewAdapter: ResourceView {
	private weak var controller: ListViewController?

	init(controller: ListViewController) {
		self.controller = controller
	}

	func display(_ viewModel: VideoCommentsViewModel) {
		controller?.display(viewModel.comments.map { comment in
			CellController(id: comment, VideoCommentCellController(model: comment))
		})
	}
}
