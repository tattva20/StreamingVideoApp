//
//  VideoPlayerUIComposer.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit
import StreamingCore
import StreamingCoreiOS

public enum VideoPlayerUIComposer {
	public static func videoPlayerComposedWith(
		video: Video,
		player: VideoPlayer? = nil,
		commentsController: UIViewController? = nil,
		analyticsLogger: PlaybackAnalyticsLogger? = nil
	) -> VideoPlayerViewController {
		let viewModel = VideoPlayerPresenter.map(video)
		let basePlayer = player ?? AVPlayerVideoPlayer()
		let videoPlayer: VideoPlayer = analyticsLogger.map {
			AnalyticsVideoPlayerDecorator(decoratee: basePlayer, analyticsLogger: $0)
		} ?? basePlayer
		let controller = VideoPlayerViewController(viewModel: viewModel, player: videoPlayer)

		if let commentsController = commentsController {
			controller.setCommentsController(commentsController)
		}

		// IMPORTANT: Do NOT use AppDelegate.orientationLock here!
		// Using orientation locks causes iOS to cache the restricted orientation mask,
		// which blocks physical rotation even after the lock is reset.
		// The correct approach is to use requestGeometryUpdate WITHOUT any orientation locking.
		// The view controller's supportedInterfaceOrientations (.allButUpsideDown) handles
		// what orientations are allowed - we just request the specific one we want.
		// Reference: commits 5473c40 and 4705375 show the original working implementation.
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
		if let avPlayer = basePlayer as? AVPlayerVideoPlayer {
			avPlayer.attach(to: controller.playerView)
		}

		let pipController = PictureInPictureController()
		pipController.setup(with: controller.playerView)
		controller.pipController = pipController

		controller.onPipToggle = { [weak controller] in
			controller?.pipController?.togglePictureInPicture()
		}

		return controller
	}
}
