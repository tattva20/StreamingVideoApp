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
			let isCurrentlyFullscreen = controller.isFullscreen

			if #available(iOS 16.0, *) {
				guard let windowScene = controller.view.window?.windowScene else { return }
				let targetOrientation: UIInterfaceOrientationMask = isCurrentlyFullscreen ? .portrait : .landscapeRight
				controller.setNeedsUpdateOfSupportedInterfaceOrientations()
				windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: targetOrientation)) { _ in }
			} else {
				if isCurrentlyFullscreen {
					let value = UIInterfaceOrientation.portrait.rawValue
					UIDevice.current.setValue(value, forKey: "orientation")
				} else {
					let value = UIInterfaceOrientation.landscapeRight.rawValue
					UIDevice.current.setValue(value, forKey: "orientation")
				}
				UIViewController.attemptRotationToDeviceOrientation()
			}
		}

		controller.loadViewIfNeeded()
		if let avPlayer = videoPlayer as? AVPlayerVideoPlayer {
			avPlayer.attach(to: controller.playerView)
		}

		return controller
	}
}
