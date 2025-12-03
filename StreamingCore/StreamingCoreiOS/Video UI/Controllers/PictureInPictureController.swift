//
//  PictureInPictureController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVKit

public final class PictureInPictureController: NSObject {
	private var pipController: AVPictureInPictureController?
	private weak var playerView: PlayerView?

	public var isPictureInPictureActive: Bool {
		pipController?.isPictureInPictureActive ?? false
	}

	public var isPictureInPicturePossible: Bool {
		pipController?.isPictureInPicturePossible ?? false
	}

	public func setup(with playerView: PlayerView) {
		guard AVPictureInPictureController.isPictureInPictureSupported() else { return }

		self.playerView = playerView
		pipController = AVPictureInPictureController(playerLayer: playerView.playerLayer)
		pipController?.delegate = self
	}

	public func togglePictureInPicture() {
		guard let pipController = pipController else { return }

		if pipController.isPictureInPictureActive {
			pipController.stopPictureInPicture()
		} else if pipController.isPictureInPicturePossible {
			pipController.startPictureInPicture()
		}
	}

	public func startPictureInPicture() {
		guard let pipController = pipController,
			  pipController.isPictureInPicturePossible else { return }
		pipController.startPictureInPicture()
	}

	public func stopPictureInPicture() {
		pipController?.stopPictureInPicture()
	}
}

extension PictureInPictureController: AVPictureInPictureControllerDelegate {
	public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		// PiP is about to start
	}

	public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		// PiP has started
	}

	public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		// PiP is about to stop
	}

	public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		// PiP has stopped
	}

	public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
		// Handle PiP start failure
	}
}
