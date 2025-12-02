//
//  VideoPlayerUIComposer.swift
//  StreamingVideoApp
//
//  Created by Octavio Rojas on 02/12/25.
//

import UIKit
import StreamingCore
import StreamingCoreiOS

public enum VideoPlayerUIComposer {
	public static func videoPlayerComposedWith(
		video: Video,
		commentsController: UIViewController? = nil
	) -> VideoPlayerViewController {
		let viewModel = VideoPlayerPresenter.map(video)
		let player = AVPlayerVideoPlayer()
		let controller = VideoPlayerViewController(viewModel: viewModel, player: player)

		if let commentsController = commentsController {
			controller.setCommentsController(commentsController)
		}

		controller.loadViewIfNeeded()
		player.attach(to: controller.playerView)

		return controller
	}
}
