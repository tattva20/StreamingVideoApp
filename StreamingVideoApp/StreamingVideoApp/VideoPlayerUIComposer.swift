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
		player: VideoPlayer? = nil,
		commentsController: UIViewController? = nil
	) -> VideoPlayerViewController {
		let viewModel = VideoPlayerPresenter.map(video)
		let videoPlayer = player ?? AVPlayerVideoPlayer()
		let controller = VideoPlayerViewController(viewModel: viewModel, player: videoPlayer)

		if let commentsController = commentsController {
			controller.setCommentsController(commentsController)
		}

		controller.onFullscreenToggle = { [weak controller] in
			guard let controller = controller else { return }
			let currentOrientation = UIDevice.current.orientation
			let isCurrentlyLandscape = currentOrientation.isLandscape

			if isCurrentlyLandscape {
				let value = UIInterfaceOrientation.portrait.rawValue
				UIDevice.current.setValue(value, forKey: "orientation")
			} else {
				let value = UIInterfaceOrientation.landscapeRight.rawValue
				UIDevice.current.setValue(value, forKey: "orientation")
			}

			UIViewController.attemptRotationToDeviceOrientation()
		}

		controller.loadViewIfNeeded()
		if let avPlayer = videoPlayer as? AVPlayerVideoPlayer {
			avPlayer.attach(to: controller.playerView)
		}

		return controller
	}
}
