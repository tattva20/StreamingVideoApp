//
//  AVPlayerVideoPlayer.swift
//  StreamingVideoApp
//
//  Created by Octavio Rojas on 02/12/25.
//

import AVFoundation
import StreamingCore
import StreamingCoreiOS

public final class AVPlayerVideoPlayer: VideoPlayer {
	public let player: AVPlayer

	public var isPlaying: Bool = false

	public init(player: AVPlayer = AVPlayer()) {
		self.player = player
	}

	public func load(url: URL) {
		let playerItem = AVPlayerItem(url: url)
		player.replaceCurrentItem(with: playerItem)
	}

	public func play() {
		player.play()
		isPlaying = true
	}

	public func pause() {
		player.pause()
		isPlaying = false
	}

	public func attach(to playerView: PlayerView) {
		playerView.playerLayer.player = player
	}
}
