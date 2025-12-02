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
			guard let controller = controller else {
				print("[Fullscreen] Controller is nil")
				return
			}
			let isCurrentlyFullscreen = controller.isFullscreen
			let targetOrientation: UIInterfaceOrientationMask = isCurrentlyFullscreen ? .portrait : .landscapeRight

			print("[Fullscreen] Button tapped. isFullscreen=\(isCurrentlyFullscreen), target=\(targetOrientation == .portrait ? "portrait" : "landscape")")

			AppDelegate.orientationLock = targetOrientation

			if #available(iOS 16.0, *) {
				guard let windowScene = controller.view.window?.windowScene else {
					print("[Fullscreen] ERROR: windowScene is nil. window=\(String(describing: controller.view.window))")
					AppDelegate.orientationLock = .allButUpsideDown
					return
				}

				print("[Fullscreen] Requesting geometry update...")

				controller.setNeedsUpdateOfSupportedInterfaceOrientations()
				controller.navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()

				windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: targetOrientation)) { error in
					print("[Fullscreen] requestGeometryUpdate completed. error=\(error)")
					DispatchQueue.main.async {
						AppDelegate.orientationLock = .allButUpsideDown
					}
				}
			} else {
				if isCurrentlyFullscreen {
					let value = UIInterfaceOrientation.portrait.rawValue
					UIDevice.current.setValue(value, forKey: "orientation")
				} else {
					let value = UIInterfaceOrientation.landscapeRight.rawValue
					UIDevice.current.setValue(value, forKey: "orientation")
				}
				UIViewController.attemptRotationToDeviceOrientation()
				AppDelegate.orientationLock = .allButUpsideDown
			}
		}

		controller.loadViewIfNeeded()
		if let avPlayer = videoPlayer as? AVPlayerVideoPlayer {
			avPlayer.attach(to: controller.playerView)
		}

		return controller
	}
}
